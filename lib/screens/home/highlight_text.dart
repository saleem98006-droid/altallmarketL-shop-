import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final int maxLines;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color highlightColor;

  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.maxLines = 1,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color = Colors.black,
    this.highlightColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final safeText = text.toString();

    if (query.isEmpty) {
      return Text(
        safeText,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      );
    }

    final lowerText = safeText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        safeText,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      );
    }

    final endIndex = startIndex + query.length;

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        children: [
          TextSpan(text: safeText.substring(0, startIndex)),
          TextSpan(
            text: safeText.substring(startIndex, endIndex),
            style: TextStyle(
              color: highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: safeText.substring(endIndex)),
        ],
      ),
    );
  }
}