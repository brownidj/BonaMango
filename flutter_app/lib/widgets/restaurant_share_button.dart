import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/restaurant.dart';

String restaurantShareText(Restaurant restaurant) {
  final lines = <String>[restaurant.name];
  void add(String label, String? value) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'not listed') {
      lines.add('$label: $text');
    }
  }

  add('City', restaurant.city);
  add('Country', restaurant.country);
  add('Address', restaurant.address);
  add('Cuisine', restaurant.cuisine);
  add('Special dishes', restaurant.specialDish);
  add('Notes', restaurant.notes);
  add('Tel', restaurant.telephone);
  add('Website', restaurant.internetLink);
  return lines.join('\n');
}

class RestaurantShareButton extends StatelessWidget {
  const RestaurantShareButton({
    super.key,
    required this.restaurant,
    this.share,
  });
  final Restaurant restaurant;
  final Future<ShareResult> Function(ShareParams)? share;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Share restaurant',
    icon: const Icon(Icons.share_outlined, semanticLabel: 'Share restaurant'),
    onPressed: () async {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      try {
        await (share ?? SharePlus.instance.share)(
          ShareParams(
            text: restaurantShareText(restaurant),
            subject: restaurant.name,
            sharePositionOrigin: origin,
          ),
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open sharing. Please try again.'),
            ),
          );
        }
      }
    },
  );
}
