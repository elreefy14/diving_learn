import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomText extends StatelessWidget {
  final String txt;
  final String? fontFamily;
  final double fontSize;
  final double height;
  final double wordSpacing;
  final int maxLine;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final TextDecoration decoration;

  const CustomText({
    super.key,
    required this.txt,
    this.height = 1,
    this.maxLine = 1,
    this.fontSize = 16,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.ellipsis,
    this.wordSpacing = 1,
    this.decoration = TextDecoration.none,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      txt.tr,
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        decoration: decoration,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        wordSpacing: wordSpacing,
        fontFamily: fontFamily,
      ),
      textAlign: textAlign,
    );
  }
}
