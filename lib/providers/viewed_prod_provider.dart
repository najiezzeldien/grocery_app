import 'package:flutter/material.dart';
import 'package:grocery_app/models/viewed_model.dart';

import 'package:grocery_app/models/wishlist_model.dart';

class ViewedProdProvider with ChangeNotifier {
  Map<String, ViewedProdModel> _viewedProdListItems = {};
  Map<String, ViewedProdModel> get getViewProdListItems {
    return _viewedProdListItems;
  }

  void addProductToHistory({required String productId}) {
    _viewedProdListItems.putIfAbsent(
      productId,
      () => ViewedProdModel(
        id: DateTime.now().toString(),
        productId: productId,
      ),
    );

    notifyListeners();
  }

  void clearHistory() {
    _viewedProdListItems.clear();
    notifyListeners();
  }
}
