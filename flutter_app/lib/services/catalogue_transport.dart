import 'dart:convert';

import 'package:http/http.dart' as http;

/// An application response, independent of HTTP and of any future mesh SDK.
/// A successful write means the host accepted it, not merely that it was sent.
class CatalogueReply {
  const CatalogueReply(this.data, this.statusCode);
  final Map<String, dynamic> data;
  final int statusCode;
}

/// Application operations used by the offline controller. Paths and methods
/// retain the existing host protocol; a future adapter must preserve revision,
/// conflict and host-acknowledgement semantics. No provider is enabled here.
/// The caller owns the transport and any associated resources.
abstract interface class CatalogueTransport {
  Future<CatalogueReply> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]);
}

/// Borrows the existing authenticated client, including its pairing checks.
class HttpCatalogueTransport implements CatalogueTransport {
  HttpCatalogueTransport(this.client, {required this.baseUrl});
  final http.Client client;
  final String baseUrl;

  @override
  Future<CatalogueReply> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(
      method,
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path'),
    );
    if (body != null) {
      request.headers.addAll({
        'Content-Type': 'application/json',
        'X-BonaMangxo-Edit': '1',
      });
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(await client.send(request));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected catalogue response.');
    }
    return CatalogueReply(data, response.statusCode);
  }
}
