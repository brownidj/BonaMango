import 'package:bona_mangxo_app/models/restaurant.dart';
import 'package:bona_mangxo_app/widgets/restaurant_share_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  const restaurant = Restaurant(
    id: 1,
    name: 'Manĝo',
    city: 'Paris',
    country: 'France',
    cuisine: 'French',
    notes: 'not listed',
    telephone: '+33 1 23 45 67 89',
    internetLink: 'https://example.com',
    revision: 'private-revision',
    reviewNote: 'private review',
  );
  test('shared details omit placeholders and internal review metadata', () {
    final text = restaurantShareText(restaurant);
    expect(text, contains('Manĝo\nCity: Paris\nCountry: France'));
    expect(text, contains('Tel: +33 1 23 45 67 89'));
    expect(text, contains('Website: https://example.com'));
    expect(text, isNot(contains('not listed')));
    expect(text, isNot(contains('private')));
  });
  testWidgets('share button supplies restaurant details and popover anchor', (
    tester,
  ) async {
    ShareParams? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestaurantShareButton(
            restaurant: restaurant,
            share: (params) async {
              captured = params;
              return const ShareResult('', ShareResultStatus.dismissed);
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Share restaurant'));
    await tester.pumpAndSettle();
    expect(captured!.subject, 'Manĝo');
    expect(captured!.text, restaurantShareText(restaurant));
    expect(captured!.sharePositionOrigin!.width, greaterThan(0));
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('native sharing failure is reported without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestaurantShareButton(
            restaurant: restaurant,
            share: (_) async => throw StateError('unavailable'),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Share restaurant'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not open sharing. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
