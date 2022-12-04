import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/firebase_consts.dart';

import 'package:grocery_app/models/wishlist_model.dart';

class WishlistProvider with ChangeNotifier {
  Map<String, WishlistModel> _wishlistItems = {};
  Map<String, WishlistModel> get getWishlistItems {
    return _wishlistItems;
  }

  final userCollection = FirebaseFirestore.instance.collection("users");

  // void addRemoveProductToWishlist({required String productId}) {
  //   if (_wishlistItems.containsKey(productId)) {
  //     removeOneItem(productId);
  //   } else {
  //     _wishlistItems.putIfAbsent(
  //       productId,
  //       () => WishlistModel(
  //         id: DateTime.now().toString(),
  //         productId: productId,
  //       ),
  //     );
  //   }
  //   notifyListeners();
  // }

  Future<void> fetchWishlist() async {
    final User? user = authInstance.currentUser;

    final DocumentSnapshot userDoc = await userCollection.doc(user!.uid).get();
    if (userDoc == null) {
      return;
    }
    final length = userDoc.get("userWish").length;
    for (int i = 0; i < length; i++) {
      _wishlistItems.putIfAbsent(
        userDoc.get("userWish")[i]["productId"],
        () => WishlistModel(
          id: userDoc.get("userWish")[i]["wishlistId"],
          productId: userDoc.get("userWish")[i]["productId"],
        ),
      );
    }
    notifyListeners();
  }

  Future<void> removeOneItem({
    required String wishlidtId,
    required String productId,
  }) async {
    final User? user = authInstance.currentUser;

    await userCollection.doc(user!.uid).update(
      {
        "userWish": FieldValue.arrayRemove(
          [
            {
              "wishlistId": wishlidtId,
              "productId": productId,
            },
          ],
        ),
      },
    );
    _wishlistItems.remove(productId);
    await fetchWishlist();
    notifyListeners();
  }

  Future<void> clearOnlineWislist() async {
    final User? user = authInstance.currentUser;

    await userCollection.doc(user!.uid).update(
      {
        "userWish": [],
      },
    );
    _wishlistItems.clear();
    notifyListeners();
  }

  void clearLocalWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
