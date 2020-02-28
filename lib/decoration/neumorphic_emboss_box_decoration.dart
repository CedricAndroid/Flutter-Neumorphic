import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../NeumorphicBoxShape.dart';
import '../flutter_neumorphic.dart';
import '../theme.dart';

class NeumorphicEmbossBoxDecorationPainter extends BoxPainter {
  bool invalidate = false;

  Color accent;

  NeumorphicStyle style;
  NeumorphicBoxShape shape;

  Paint backgroundPaint;
  Paint whiteShadowPaint;
  Paint whiteShadowMaskPaint;
  Paint blackShadowPaint;
  Paint blackShadowMaskPaint;

  double width;
  double height;
  double radius;
  double depth;

  Offset originOffset;
  Offset circleOffset;
  Offset whiteShadowMaskPaintOffset;
  Offset blackShadowMaskPaintOffset;

  Rect layerRect;
  Rect backgroundRect;

  Radius cornerRadius;

  LightSource source;

  RRect buttonRRect;
  RRect whiteShadowMaskRect;
  RRect blackShadowMaskRect;

  NeumorphicEmbossBoxDecorationPainter(
      {this.accent,
      @required this.style,
      NeumorphicBoxShape shape,
      @required VoidCallback onChanged})
      : this.shape = shape ?? NeumorphicBoxShape.roundRect(),
        super(onChanged) {
    var color = accent ?? style.baseColor;
    var blackShadowColor = Colors.black45; // TODO : Add intensity ?
    var whiteShadowColor = Colors.white60; // TODO : Add intensity ?

    backgroundPaint = Paint()..color = color;

    whiteShadowPaint = Paint()..color = whiteShadowColor;
    whiteShadowMaskPaint = Paint()..blendMode = BlendMode.dstOut;

    blackShadowPaint = Paint()..color = blackShadowColor;
    blackShadowMaskPaint = Paint()..blendMode = BlendMode.dstOut;
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    this.invalidate = false;

    var width = configuration.size.width;
    var height = configuration.size.height;

    if (this.originOffset != offset ||
        this.width != width ||
        this.height != height) {
      this.width = width;
      this.height = height;
      this.originOffset = offset;
      this.invalidate = true;

      var middleWidth = this.width / 2;
      var middleHeight = this.height / 2;

      layerRect = offset & configuration.size;
      radius = min(middleWidth, middleHeight);

      if (shape.isCircle) {
        circleOffset = offset.translate(middleWidth, middleHeight);
      } else {
        backgroundRect = Rect.fromLTRB(offset.dx, offset.dy,
            offset.dx + this.width, offset.dy + this.height);
      }
    }

    var cornerRadius = (shape?.borderRadius?.topLeft ?? Radius.zero);
    if ((this.invalidate || this.cornerRadius != cornerRadius) &&
        !shape.isCircle) {
      this.cornerRadius = Radius.circular(cornerRadius.x.clamp(0.0, radius));
      this.buttonRRect =
          RRect.fromRectAndRadius(backgroundRect, this.cornerRadius);
    }

    LightSource source = style.lightSource;
    var depth = style.depth.abs().clamp(0.0, radius / 5);
    if (this.invalidate || this.source != source || this.depth != depth) {
      this.depth = depth;
      this.source = source;

      MaskFilter mask = MaskFilter.blur(BlurStyle.normal, depth);
      blackShadowMaskPaint..maskFilter = mask;
      whiteShadowMaskPaint..maskFilter = mask;

      if (shape.isCircle) {
        whiteShadowMaskPaintOffset = circleOffset.translate(
          this.depth * this.source.dx,
          this.depth * this.source.dy,
        );
        blackShadowMaskPaintOffset = circleOffset.translate(
          -this.depth * this.source.dx,
          -this.depth * this.source.dy,
        );
      } else {
        whiteShadowMaskRect = RRect.fromRectAndRadius(
            getWhiteShadowMaskRect(
              this.source,
              configuration.size,
              offset,
              this.depth,
            ),
            cornerRadius);
        blackShadowMaskRect = RRect.fromRectAndRadius(
            getBlackShadowMaskRect(
              this.source,
              configuration.size,
              offset,
              this.depth,
            ),
            cornerRadius);
      }
    }

    if (shape.isCircle) {
      canvas.drawCircle(circleOffset, radius, backgroundPaint);

      canvas.saveLayer(layerRect, whiteShadowPaint);
      canvas.drawCircle(circleOffset, radius, whiteShadowPaint);
      canvas.drawCircle(
        whiteShadowMaskPaintOffset,
        radius,
        whiteShadowMaskPaint,
      );
      canvas.restore();

      canvas.saveLayer(layerRect, blackShadowPaint);
      canvas.drawCircle(circleOffset, radius, blackShadowPaint);
      canvas.drawCircle(
        blackShadowMaskPaintOffset,
        radius,
        blackShadowMaskPaint,
      );
      canvas.restore();
    } else {
      canvas.drawRRect(buttonRRect, backgroundPaint);

      canvas.saveLayer(layerRect, whiteShadowPaint);
      canvas.drawRRect(buttonRRect, whiteShadowPaint);
      canvas.drawRRect(whiteShadowMaskRect, whiteShadowMaskPaint);
      canvas.restore();

      canvas.saveLayer(layerRect, blackShadowPaint);
      canvas.drawRRect(buttonRRect, blackShadowPaint);
      canvas.drawRRect(blackShadowMaskRect, blackShadowMaskPaint);
      canvas.restore();
    }
  }

  Rect getWhiteShadowMaskRect(
      LightSource source, Size size, Offset offset, double depth) {
    var xDepth = source.dx * depth;
    var yDepth = source.dy * depth;
    var xPadding = 2 * (1 - source.dx.abs()) * depth;
    var yPadding = 2 * (1 - source.dy.abs()) * depth;

    var left = xDepth - xPadding;
    var top = yDepth - yPadding;
    var right = xDepth + xPadding;
    var bottom = yDepth + yPadding;

    return Rect.fromLTRB(
      offset.dx + left,
      offset.dy + top,
      offset.dx + size.width + right,
      offset.dy + size.height + bottom,
    );
  }

  Rect getBlackShadowMaskRect(
      LightSource source, Size size, Offset offset, double depth) {
    var xDepth = source.dx * depth;
    var yDepth = source.dy * depth;
    var xPadding = 2 * (1 - source.dx.abs()) * depth;
    var yPadding = 2 * (1 - source.dy.abs()) * depth;

    var left = xDepth + xPadding;
    var top = yDepth + yPadding;
    var right = xDepth - xPadding;
    var bottom = yDepth - yPadding;

    return Rect.fromLTRB(
      offset.dx - left,
      offset.dy - top,
      offset.dx + size.width - right,
      offset.dy + size.height - bottom,
    );
  }
}