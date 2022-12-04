import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/order_model.dart';

class OrdersProvider with ChangeNotifier {
  static final List<OrderModel> _ordersList = [];
  List<OrderModel> get getOrders {
    return _ordersList;
  }

  void clearLocalOrders() {
    _ordersList.clear();
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    User? user = authInstance.currentUser;
    await FirebaseFirestore.instance
        .collection("orders")
        .where(
          "userId",
          isEqualTo: user!.uid,
        )
        .get()
        .then(
      (QuerySnapshot orderSnapshot) {
        _ordersList.clear();
        orderSnapshot.docs.forEach(
          (element) {
            _ordersList.insert(
              0,
              OrderModel(
                orderId: element.get("orderId"),
                userId: element.get("userId"),
                productId: element.get("productId"),
                userName: element.get("userName"),
                price: element.get("price").toString(),
                imageUrl: element.get("imageUrl"),
                quantity: element.get("quantity").toString(),
                orderDate: element.get("orderDate"),
              ),
            );
          },
        );
      },
    );
    notifyListeners();
  }
}
