import 'package:bona_mangxo_app/main.dart';
import 'package:bona_mangxo_app/screens/restaurant_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BonaManĝo opens its restaurant browser', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Widget tests intercept HTTP; rendering must not require a live server.
    await tester.pumpWidget(const BonaMangxoApp());
    await tester.pumpAndSettle();

    expect(find.byType(RestaurantListPage), findsOneWidget);
    expect(find.text('The restaurant collection'), findsOneWidget);
    expect(find.byTooltip('Add restaurant'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
