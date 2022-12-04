import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/screens/wishlist/wishlist_widget.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../../widgets/back_widget.dart';

class WishlistScreen extends StatelessWidget {
  static const routeName = '/WishlistScreen';

  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    Size size = utils.getScreenSize;
    final Color color = utils.color;

    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlistItems =
        wishlistProvider.getWishlistItems.values.toList().reversed.toList();

    return wishlistItems.isEmpty
        ? const EmptyScreen(
            title: "Your Wishlist Is Empty",
            subtitle: "Explore more and shortlist some items",
            bouttontext: "Add a wish",
            imagePath: "assets/images/wishlist.png",
          )
        : Scaffold(
            appBar: AppBar(
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: const BackWidget(),
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: TextWidget(
                text: "Wishlist (${wishlistItems.length})",
                color: color,
                textSize: 22,
                isTitle: true,
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await GlobalMethods.warningDialog(
                      title: "Empty your wishlist?",
                      subtitle: "Are you sure?",
                      fct: () async {
                        await wishlistProvider.clearOnlineWislist();
                        wishlistProvider.clearLocalWishlist();
                      },
                      context: context,
                    );
                  },
                  icon: Icon(
                    IconlyBroken.delete,
                    color: color,
                  ),
                ),
              ],
            ),
            body: MasonryGridView.count(
              crossAxisCount: 2,
              itemCount: wishlistItems.length,
              // mainAxisSpacing: 16,
              // crossAxisSpacing: 4,
              itemBuilder: (context, index) {
                return ChangeNotifierProvider.value(
                  value: wishlistItems[index],
                  child: const WishlistWidget(),
                );
              },
            ),
          );
  }
}
