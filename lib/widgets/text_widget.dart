import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  late String text;
  late double fontSize;
  late Color? color;
  late String? fontFamily;
  late TextDecoration? decoration;
  final bool? isItalize;
  final bool? isBold;
  final int? maxLines;
  final TextAlign align;
  final FontWeight? fontWeight;
  final TextOverflow? overflow;

  TextWidget(
      {super.key,
      this.decoration,
      this.align = TextAlign.start,
      this.maxLines,
      this.overflow,
      this.isItalize = false,
      this.isBold = false,
      required this.text,
      required this.fontSize,
      this.color = Colors.black,
      this.fontWeight,
      this.fontFamily = 'Regular'});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      style: TextStyle(
          letterSpacing: 0,
          overflow: overflow ?? TextOverflow.ellipsis,
          fontStyle: isItalize! ? FontStyle.italic : null,
          decoration: decoration,
          fontWeight: fontWeight,
          fontSize: fontSize,
          color: color,
          fontFamily: fontFamily),
    );
  }
}
