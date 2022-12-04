// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:grocery_app/inner_screens/category_screen.dart';
import 'package:provider/provider.dart';

import 'package:grocery_app/providers/dark_theme_provider.dart';
import 'package:grocery_app/widgets/text_widget.dart';

class CategoriesWidget extends StatelessWidget {
  final String catText;
  final String imgPath;
  final Color passedcolor;
  const CategoriesWidget({
    Key? key,
    required this.catText,
    required this.imgPath,
    required this.passedcolor,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Size size=MediaQuery.of(context).size;
    double _screenWidth = MediaQuery.of(context).size.width;

    final themeState = Provider.of<DarkThemeProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          CategoryScreen.routeName,
          arguments: catText,
        );
      },
      child: Container(
        //height: _screenWidth * 0.6,
        decoration: BoxDecoration(
          color: passedcolor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: passedcolor.withOpacity(0.7),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: _screenWidth * 0.3,
              width: _screenWidth * 0.3,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    imgPath,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            TextWidget(
              text: catText,
              color: color,
              textSize: 20,
              isTitle: true,
            ),
          ],
        ),
      ),
    );
  }
}
