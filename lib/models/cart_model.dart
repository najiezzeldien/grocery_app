// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class CartModel with ChangeNotifier {
  final String id, productId;
  final int quantity;
  CartModel({
    required this.id,
    required this.productId,
    required this.quantity,
  });
}
