import 'package:flutter/material.dart';
import 'package:gestion_fournitures/models/shop_stand_model.dart';
import 'package:gestion_fournitures/widgets/build_card_widget.dart';
import 'package:gestion_fournitures/pages/turnover_table_page.dart';

/// 🔹 Widget réutilisable pour afficher une grille
/// de boutiques ou de stands sous forme de cartes.
class BuildGridWidget extends StatelessWidget {
  final List<ShopStandModel> items;
  final bool isShop;
  final Color backgroundColor;

  const BuildGridWidget({
    super.key,
    required this.items,
    required this.isShop,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return BuildCardWidget(
          icon: isShop
              ? Icons.store_mall_directory_rounded
              : Icons.storefront_outlined,
          label: item.name,
          padding: const EdgeInsets.all(5),
          page: TurnoverTablePage(
            stand: item,
            isShop: isShop,
          ),
          backgroundColor: backgroundColor,
          iconSize: 50,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
      },
    );
  }
}
