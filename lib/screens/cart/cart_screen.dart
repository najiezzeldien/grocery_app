import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/cart/cart_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    Size size = utils.getScreenSize;
    final Color color = utils.color;
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemsList =
        cartProvider.getCartItems.values.toList().reversed.toList();
    return cartItemsList.isEmpty
        ? const EmptyScreen(
            title: "Your cart is empty",
            subtitle: "Add something and make me happy :)",
            bouttontext: "Show now",
            imagePath: "assets/images/cart.png",
          )
        : Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: TextWidget(
                text: "Cart (${cartItemsList.length})",
                color: color,
                textSize: 22,
                isTitle: true,
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await GlobalMethods.warningDialog(
                      title: "Empty your cart?",
                      subtitle: "Are you sure?",
                      fct: () async {
                        await cartProvider.clearOnlineCart();
                        cartProvider.clearLocalCart();
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
            body: Column(
              children: [
                _checkOut(context),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItemsList.length,
                    itemBuilder: (cxt, index) {
                      return ChangeNotifierProvider.value(
                        value: cartItemsList[index],
                        child: CartWidget(
                          q: cartItemsList[index].quantity,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _checkOut(BuildContext ctx) {
    final Utils utils = Utils(ctx);
    Size size = utils.getScreenSize;
    final Color color = utils.color;
    final cartProvider = Provider.of<CartProvider>(ctx);
    final productProvider = Provider.of<ProductsProvider>(ctx);
    final ordersProvider = Provider.of<OrdersProvider>(ctx);
    double total = 0.0;
    cartProvider.getCartItems.forEach(
      (key, value) {
        final getCurrProduct = productProvider.findProdById(value.productId);
        total += (getCurrProduct.isOnSale
                ? getCurrProduct.salePrice
                : getCurrProduct.price) *
            value.quantity;
      },
    );

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Material(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  User? user = authInstance.currentUser;
                  final orderId = const Uuid().v4();
                  final productProvider =
                      Provider.of<ProductsProvider>(ctx, listen: false);
                  try {
                    await initPayment(
                      email: user!.email ?? "",
                      amount: total * 100,
                      context: ctx,
                    );
                  } catch (erorr) {
                    GlobalMethods.errorDialog(
                      subtitle: erorr.toString(),
                      context: ctx,
                    );
                    return;
                  }
                  cartProvider.getCartItems.forEach(
                    (key, value) async {
                      final getCurrProduct =
                          productProvider.findProdById(value.productId);

                      try {
                        await FirebaseFirestore.instance
                            .collection("orders")
                            .doc(orderId)
                            .set(
                          {
                            "orderId": orderId,
                            "userId": user.uid,
                            "productId": value.productId,
                            "price": (getCurrProduct.isOnSale
                                    ? getCurrProduct.salePrice
                                    : getCurrProduct.price) *
                                value.quantity,
                            "totalPrice": total,
                            "quantity": value.quantity,
                            "imageUrl": getCurrProduct.imageUrl,
                            "userName": user.displayName,
                            "orderDate": Timestamp.now(),
                          },
                        );
                        await cartProvider.clearOnlineCart();
                        cartProvider.clearLocalCart();
                        ordersProvider.fetchOrders();
                        await Fluttertoast.showToast(
                          msg: "Your order has been placed",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                        );
                      } catch (error) {
                        GlobalMethods.errorDialog(
                          subtitle: error.toString(),
                          context: ctx,
                        );
                      } finally {}
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextWidget(
                    text: "Order Now",
                    color: Colors.white,
                    textSize: 20,
                  ),
                ),
              ),
            ),
            const Spacer(),
            FittedBox(
              child: TextWidget(
                text: "Total: \$${total.toStringAsFixed(2)}",
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initPayment({
    required String email,
    required double amount,
    required BuildContext context,
  }) async {
    try {
      // 1. Create a payment intent on the server
      final response = await http.post(
        Uri.parse(
            "https://us-central1-grocery---flutter-course.cloudfunctions.net/stripePaymentIntentRequest"),
        body: {
          "email": email,
          "amount": amount.toString(),
        },
      );
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse.toString());
      if (jsonResponse["success"] == false) {
        GlobalMethods.errorDialog(
          subtitle: jsonResponse["error"],
          context: context,
        );
        throw "${jsonResponse["error"]}";
      }
      // 2.  initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse["paymentIntent"],
          merchantDisplayName: "Grocery App",
          customerId: jsonResponse["customer"],
          customerEphemeralKeySecret: jsonResponse["ephemeralkey"],
          //testEnv: true,
          //merchantCountryCode:"US",
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment is succesfull"),
        ),
      );
    } catch (error) {
      if (error is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occured ${error.error.localizedMessage}"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occured $error "),
          ),
        );
      }
      throw "$error";
    }
  }
}
