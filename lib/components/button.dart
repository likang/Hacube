import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CPButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  CPButton(
      {@required this.child,
      @required this.onPressed,
      this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4)});

  @override
  _CPButtonState createState() => _CPButtonState();
}

class _CPButtonState extends State<CPButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: widget.padding,
        decoration: CPButtonDecoration(),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.cyanAccent),
          child: widget.child,
        ),
      ),
    );
  }
}

class CPButtonDecoration extends Decoration {
  //4
  @override
  BoxPainter createBoxPainter([onChanged]) {
    return _CPButtonDecorationPainter();
  }
}

class _CPButtonDecorationPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect bounds = offset & configuration.size;
    _drawDecoration(canvas, bounds);
  }
}

void _drawDecoration(Canvas canvas, Rect bounds) {
  Paint innerFillPaint = Paint()
    ..color = Color.fromARGB(0x52, 0x18, 0xff, 0xff);
  Paint innerBorderPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint cornerPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  double cornerRadius = min(bounds.width, bounds.height) / 4;

  Path cornerPath = new Path()
    ..moveTo(bounds.left, bounds.top + cornerRadius)
    ..lineTo(bounds.left, bounds.top)
    ..lineTo(bounds.left + cornerRadius, bounds.top)
    ..moveTo(bounds.right - cornerRadius, bounds.top)
    ..lineTo(bounds.right, bounds.top)
    ..lineTo(bounds.right, bounds.top + cornerRadius)
    ..moveTo(bounds.right, bounds.bottom - cornerRadius)
    ..lineTo(bounds.right, bounds.bottom)
    ..lineTo(bounds.right - cornerRadius, bounds.bottom)
    ..moveTo(bounds.left + cornerRadius, bounds.bottom)
    ..lineTo(bounds.left, bounds.bottom)
    ..lineTo(bounds.left, bounds.bottom - cornerRadius);

  canvas.drawPath(cornerPath, cornerPaint);

  Rect innerRect = bounds.deflate(1);
  canvas.drawRect(innerRect, innerFillPaint);
  canvas.drawRect(innerRect, innerBorderPaint);
}
