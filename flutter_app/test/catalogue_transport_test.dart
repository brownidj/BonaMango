import 'dart:async';
import 'dart:convert';

import 'package:bona_mangxo_app/data/catalogue_store.dart';
import 'package:bona_mangxo_app/data/mobile_catalogue.dart';
import 'package:bona_mangxo_app/services/catalogue_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryStore implements CatalogueStore {
  Map<String, dynamic>? state;
  @override
  Future<Map<String, dynamic>?> read() async => state;
  @override
  Future<void> write(Map<String, dynamic> value) async => state = value;
}

/// This fake uses no HTTP. It models host acceptance and revision conflicts.
class HostTransport implements CatalogueTransport {
  bool reachable = true;
  int writes = 0;
  int requests = 0;
  Completer<void>? downloadGate;
  Map<String, dynamic> row = {
    'id': 1,
    'revision': 'r1',
    'restaurant_name': 'Bistro',
    'city': 'Paris',
    'country': 'France',
    'needs_review': 1,
    'review_status': 'pending',
  };
  @override
  Future<CatalogueReply> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    requests++;
    if (!reachable) throw StateError('unreachable');
    if (method != 'GET') {
      writes++;
      if (body!['revision'] != row['revision']) {
        return const CatalogueReply({'error': 'Host revision changed'}, 409);
      }
      row = {
        ...row,
        if (method == 'PATCH') ...body['changes'] as Map,
        if (path.endsWith('/review')) 'review_status': body['decision'],
        'revision': 'r${writes + 1}',
      };
      return CatalogueReply({'restaurant': row}, 200);
    }
    await downloadGate?.future;
    return CatalogueReply({
      'restaurants': [row],
      'reviews': <String, dynamic>{},
      'version': row['revision'],
    }, 200);
  }
}

void main() {
  MobileCatalogue create(HostTransport host, CatalogueStore store) =>
      MobileCatalogue(
        baseUrl: 'http://fixture:8776',
        store: store,
        transport: host,
        remote: MockClient(
          (_) async => throw StateError('HTTP must not be used'),
        ),
      );

  test(
    'HTTP adapter preserves Unicode, conflict status and edit payload',
    () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://fixture:8776/api/restaurants/1');
        expect(request.method, 'PATCH');
        expect(request.headers['X-BonaMangxo-Edit'], '1');
        expect(jsonDecode(request.body)['revision'], 'r1');
        expect(jsonDecode(request.body)['changes']['notes'], 'Manĝo');
        return http.Response.bytes(
          utf8.encode('{"error":"Konflikto ĉe Manĝo"}'),
          409,
        );
      });
      addTearDown(client.close);
      final adapter = HttpCatalogueTransport(
        client,
        baseUrl: 'http://fixture:8776/',
      );
      final result = await adapter.request('PATCH', '/api/restaurants/1', {
        'revision': 'r1',
        'changes': {'notes': 'Manĝo'},
      });
      expect(result.statusCode, 409);
      expect(result.data['error'], 'Konflikto ĉe Manĝo');
    },
  );

  test('HTTP adapter rejects a malformed snapshot envelope', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    final adapter = HttpCatalogueTransport(
      client,
      baseUrl: 'http://fixture:8776',
    );
    await expectLater(
      adapter.request('GET', '/api/offline-catalogue'),
      throwsFormatException,
    );
  });

  test('provider-independent offline queue survives restart and explicit conflict resolution', () async {
    final host = HostTransport();
    final store = MemoryStore();
    final first = create(host, store);
    await first.catalogue();
    await first.mutate('PATCH', 1, {
      'revision': 'r1',
      'changes': {'notes': 'Phone note'},
    });
    first.dispose();
    host.reachable = false;
    final reopened = create(host, store);
    addTearDown(reopened.dispose);
    await reopened.catalogue();
    await reopened.syncAll();
    expect(reopened.pendingCount, 1);
    expect(reopened.localRecord(1)!['notes'], 'Phone note');
    host.reachable = true;
    host.row = {...host.row, 'revision': 'mac-r2', 'notes': 'Mac note'};
    await reopened.syncAll();
    expect(reopened.conflicts, hasLength(1));
    expect(reopened.serverRecord(1)!['notes'], 'Mac note');
    final before = host.requests;
    await reopened.synchronizeIfChanged();
    expect(host.requests, before);
    await reopened.resolve(reopened.conflicts.single['key'], useLocal: true);
    await reopened.syncAll();
    expect(host.row['notes'], 'Phone note');
    expect(reopened.pendingCount, 0);
    expect(reopened.hasChanges, false);
    expect(reopened.exportLocalHistory(), contains('Mac note'));
    expect(reopened.exportLocalHistory(), contains('Phone note'));
  });

  test(
    'opening an editor waits for an in-flight download then blocks refresh',
    () async {
      final host = HostTransport();
      final app = create(host, MemoryStore());
      addTearDown(app.dispose);
      await app.catalogue();
      host.downloadGate = Completer<void>();
      final sync = app.syncAll();
      var entered = false;
      final opening = app.beginEditing().then((_) => entered = true);
      await Future<void>.delayed(Duration.zero);
      expect(entered, false);
      host.downloadGate!.complete();
      await sync;
      await opening;
      host.row = {...host.row, 'revision': 'changed', 'notes': 'Mac changed'};
      final before = host.requests;
      await app.syncAll();
      await app.synchronizeIfChanged();
      expect(host.requests, before);
      expect(app.localRecord(1)!['notes'], isNull);
      app.endEditing(saved: false);
      await Future<void>.delayed(Duration.zero);
      expect(host.requests, before);
      await app.syncAll();
      expect(app.localRecord(1)!['notes'], 'Mac changed');
    },
  );

  testWidgets(
    'idle and reconnect cannot upload review until the saved flow closes',
    (tester) async {
      final host = HostTransport();
      final app = create(host, MemoryStore());
      await app.catalogue();
      await app.beginEditing();
      app.resume();
      app.networkChanged(true);
      await app.mutate('REVIEW', 1, {
        'revision': 'r1',
        'decision': 'passed',
        'note': 'Checked',
      });
      await tester.pump(const Duration(seconds: 16));
      expect(host.writes, 0);
      expect(app.pendingCount, 1);
      app.endEditing(saved: true);
      await app.syncAll();
      expect(host.writes, 1);
      expect(host.row['review_status'], 'passed');
      expect(app.pendingCount, 0);
      app.dispose();
    },
  );
}
