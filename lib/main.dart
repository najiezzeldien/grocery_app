import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:grocery_app/consts/theme_data.dart';
import 'package:grocery_app/fetch_screen.dart';
import 'package:grocery_app/inner_screens/category_screen.dart';
import 'package:grocery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/dark_theme_provider.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/auth/forget_pass.dart';
import 'package:grocery_app/screens/auth/login.dart';
import 'package:grocery_app/screens/auth/register.dart';
import 'package:grocery_app/screens/bottm_bar_screen.dart';
import 'package:grocery_app/screens/orders/orders_screen.dart';
import 'package:grocery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:grocery_app/screens/wishlist/wishlist_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_test_51MAzc9HiFaOZhNBRfGEVileV7KJueTd2hBlS7de6VIhOqWTEyX2pdb1yN7FzcqvtgElPNmJ6737n1QAYDCEMsfB400qp2r0Z2Q";
  Stripe.instance.applySettings();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme =
        await themeChangeProvider.darkThemePrefs.getTheme();
  }

  @override
  void initState() {
    getCurrentAppTheme();
    super.initState();
  }

  final Future<FirebaseApp> _firebaseInitialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _firebaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Text(
                    "An error occured",
                  ),
                ),
              ),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) {
                  return themeChangeProvider;
                },
              ),
              ChangeNotifierProvider(
                create: (_) {
                  return ProductsProvider();
                },
              ),
              ChangeNotifierProvider(
                create: (_) {
                  return CartProvider();
                },
              ),
              ChangeNotifierProvider(
                create: (_) {
                  return WishlistProvider();
                },
              ),
              ChangeNotifierProvider(
                create: (_) {
                  return ViewedProdProvider();
                },
              ),
              ChangeNotifierProvider(
                create: (_) {
                  return OrdersProvider();
                },
              ),
            ],
            child: Consumer<DarkThemeProvider>(
              builder: (context, themeProvider, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Flutter Demo',
                  theme: Styles.themeData(themeProvider.getDarkTheme, context),
                  home: const FetchScreen(),
                  routes: {
                    OnSaleScreen.routeName: ((ctx) => const OnSaleScreen()),
                    FeedsScreen.routeName: ((ctx) => FeedsScreen()),
                    ProductDetails.routeName: ((ctx) => const ProductDetails()),
                    WishlistScreen.routeName: ((ctx) => const WishlistScreen()),
                    OrdersScreen.routeName: ((ctx) => const OrdersScreen()),
                    ViewedRecentlyScreen.routeName: ((ctx) =>
                        const ViewedRecentlyScreen()),
                    RegisterScreen.routeName: ((ctx) => const RegisterScreen()),
                    LoginScreen.routeName: ((ctx) => const LoginScreen()),
                    ForgetPasswordScreen.routeName: ((ctx) =>
                        const ForgetPasswordScreen()),
                    CategoryScreen.routeName: ((ctx) => CategoryScreen()),
                  },
                );
              },
            ),
          );
        });
  }
}

class PaymentDemo extends StatelessWidget {
  const PaymentDemo({super.key});
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Pay 20\$"),
          onPressed: () async {
            await initPayment(
              email: "email@test.com",
              amount: 100.0,
              context: context,
            );
          },
        ),
      ),
    );
  }
}
