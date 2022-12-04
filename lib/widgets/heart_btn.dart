import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:provider/provider.dart';

class HeartBTN extends StatefulWidget {
  const HeartBTN({
    super.key,
    required this.productId,
    this.isInWishlist = false,
  });
  final String productId;
  final bool? isInWishlist;

  @override
  State<HeartBTN> createState() => _HeartBTNState();
}

class _HeartBTNState extends State<HeartBTN> {
  bool isloading = false;
  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    final Color color = utils.color;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final productProvider = Provider.of<ProductsProvider>(context);

    final getCurrProduct = productProvider.findProdById(widget.productId);

    return GestureDetector(
      onTap: () async {
        setState(() {
          isloading = true;
        });
        try {
          final User? user = authInstance.currentUser;
          if (user == null) {
            GlobalMethods.errorDialog(
              subtitle: "No user found, Please login first",
              context: context,
            );
            return;
          }
          if (widget.isInWishlist == false && widget.isInWishlist != null) {
            GlobalMethods.addToWishlist(
              productId: widget.productId,
              context: context,
            );
          } else {
            await wishlistProvider.removeOneItem(
              wishlidtId:
                  wishlistProvider.getWishlistItems[getCurrProduct.id]!.id,
              productId: widget.productId,
            );
          }
          await wishlistProvider.fetchWishlist();
          setState(() {
            isloading = false;
          });
        } catch (error) {
          GlobalMethods.errorDialog(
            subtitle: error.toString(),
            context: context,
          );
        } finally {
          setState(() {
            isloading = false;
          });
        }
        // wishlistProvider.addRemoveProductToWishlist(productId: productId);
      },
      child: isloading
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
            )
          : Icon(
              widget.isInWishlist != null && widget.isInWishlist == true
                  ? IconlyBold.heart
                  : IconlyLight.heart,
              size: 22,
              color: widget.isInWishlist != null && widget.isInWishlist == true
                  ? Colors.red
                  : color,
            ),
    );
  }
}
