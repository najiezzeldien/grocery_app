import 'package:flutter/material.dart';
import 'package:grocery_app/providers/orders_provider.dart';
import 'package:grocery_app/widgets/back_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:provider/provider.dart';

import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'orders_widget.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/OrderScreen';

  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    // Size size = Utils(context).getScreenSize;
    final orderProvider = Provider.of<OrdersProvider>(context);
    final ordersList = orderProvider.getOrders;
    return FutureBuilder(
      future: orderProvider.fetchOrders(),
      builder: (context, snapshot) {
        return ordersList.isEmpty
            ? const EmptyScreen(
                title: "Your didn't place any order yet",
                subtitle: "order something and make me happy :)",
                bouttontext: "Show now",
                imagePath: "assets/images/cart.png",
              )
            : Scaffold(
                appBar: AppBar(
                  leading: const BackWidget(),
                  elevation: 0,
                  centerTitle: false,
                  title: TextWidget(
                    text: 'Your orders (${ordersList.length})',
                    color: color,
                    textSize: 24.0,
                    isTitle: true,
                  ),
                  backgroundColor: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.9),
                ),
                body: ListView.separated(
                  itemCount: ordersList.length,
                  itemBuilder: (ctx, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 6),
                      child: ChangeNotifierProvider.value(
                        value: ordersList[index],
                        child: const OrderWidget(),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(
                      color: color,
                      thickness: 1,
                    );
                  },
                ),
              );
      },
    );
  }
}
