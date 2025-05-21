import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;
  final Color glassesFrameColor; // Color for the glasses frame
  final Color glassesLensColor; // Color for the lenses
  final double lensOpacity; // Opacity for the lenses (0.0 to 1.0)

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.isFrontCamera,
    this.glassesFrameColor = Colors.grey,
    this.glassesLensColor = Colors.blue, // Default lens color
    this.lensOpacity = 0.2, // Default lens opacity
  });

  // Helper to scale and mirror points from image coordinates to canvas coordinates
  Offset _scaleOffset(
    Offset point,
    double scaleX,
    double scaleY,
    Size canvasSize,
  ) {
    double x = point.dx * scaleX;
    double y = point.dy * scaleY;

    if (isFrontCamera) {
      x = canvasSize.width - x; // Mirror horizontally for front camera
    }

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    // Define paint for the glass frames using the provided frame color
    final framePaint =
        Paint()
          ..color = glassesFrameColor
          ..style = PaintingStyle.fill;

    // Define paint for the frame borders (slightly lighter/darker for definition)
    final frameBorderPaint =
        Paint()
          ..color = Color.alphaBlend(
            Colors.white.withAlpha((0.2 * 255).round()),
            glassesFrameColor,
          ) // Using withAlpha
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Define paint for the lenses with a solid color, incorporating lensOpacity
    final lensPaint =
        Paint()
          ..color = glassesLensColor.withAlpha(
            (lensOpacity * 255).round(),
          ) // Using withAlpha
          ..style = PaintingStyle.fill;

    // Define paint for the bridge and temples using the provided frame color
    final bridgeTemplePaint =
        Paint()
          ..color = glassesFrameColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.0;

    for (final face in faces) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];

      if (leftEye == null || rightEye == null || noseBase == null) continue;

      final scaledLeftEye = _scaleOffset(
        Offset(leftEye.position.x.toDouble(), leftEye.position.y.toDouble()),
        scaleX,
        scaleY,
        size,
      );
      final scaledRightEye = _scaleOffset(
        Offset(rightEye.position.x.toDouble(), rightEye.position.y.toDouble()),
        scaleX,
        scaleY,
        size,
      );
      final scaledNoseBase = _scaleOffset(
        Offset(noseBase.position.x.toDouble(), noseBase.position.y.toDouble()),
        scaleX,
        scaleY,
        size,
      );

      // Calculate center for lenses directly on eye positions
      final leftLensCenter = scaledLeftEye;
      final rightLensCenter = scaledRightEye;

      // Define lens dimensions (adjust as needed for desired size)
      const double lensWidth = 70;
      const double lensHeight = 40;
      const double frameThickness = 6;

      // Left Lens Frame
      final leftFrameRect = Rect.fromCenter(
        center: leftLensCenter,
        width: lensWidth + frameThickness,
        height: lensHeight + frameThickness,
      );
      canvas.drawOval(leftFrameRect, framePaint);
      canvas.drawOval(leftFrameRect, frameBorderPaint);

      // Right Lens Frame
      final rightFrameRect = Rect.fromCenter(
        center: rightLensCenter,
        width: lensWidth + frameThickness,
        height: lensHeight + frameThickness,
      );
      canvas.drawOval(rightFrameRect, framePaint);
      canvas.drawOval(rightFrameRect, frameBorderPaint);

      // Left Lens (inner part with solid color)
      final leftLensRect = Rect.fromCenter(
        center: leftLensCenter,
        width: lensWidth,
        height: lensHeight,
      );
      canvas.drawOval(leftLensRect, lensPaint);

      // Right Lens (inner part with solid color)
      final rightLensRect = Rect.fromCenter(
        center: rightLensCenter,
        width: lensWidth,
        height: lensHeight,
      );
      canvas.drawOval(rightLensRect, lensPaint);

      // Bridge connection: Connect the inner edges of the frames
      final double bridgeY = (scaledLeftEye.dy + scaledRightEye.dy) / 2;
      final Offset bridgeStart = Offset(
        leftLensCenter.dx + (lensWidth / 2),
        bridgeY,
      );
      final Offset bridgeEnd = Offset(
        rightLensCenter.dx - (lensWidth / 2),
        bridgeY,
      );
      canvas.drawLine(bridgeStart, bridgeEnd, bridgeTemplePaint);

      // Temples (legs): Start from the outermost side of the frames
      final Offset leftTempleStart = Offset(
        leftFrameRect.left,
        leftLensCenter.dy,
      );
      final Offset rightTempleStart = Offset(
        rightFrameRect.right,
        rightLensCenter.dy,
      );

      // Estimate ear positions using the face bounding box
      final scaledFaceRect = Rect.fromLTRB(
        _scaleOffset(
          Offset(face.boundingBox.left, face.boundingBox.top),
          scaleX,
          scaleY,
          size,
        ).dx,
        _scaleOffset(
          Offset(face.boundingBox.left, face.boundingBox.top),
          scaleX,
          scaleY,
          size,
        ).dy,
        _scaleOffset(
          Offset(face.boundingBox.right, face.boundingBox.bottom),
          scaleX,
          scaleY,
          size,
        ).dx,
        _scaleOffset(
          Offset(face.boundingBox.right, face.boundingBox.bottom),
          scaleX,
          scaleY,
          size,
        ).dy,
      );

      // Calculate ear positions relative to the scaled face bounding box and eye level
      final Offset scaledLeftEar = Offset(
        scaledFaceRect.left - 20,
        scaledLeftEye.dy,
      );
      final Offset scaledRightEar = Offset(
        scaledFaceRect.right + 20,
        scaledRightEye.dy,
      );

      // Draw temples
      canvas.drawLine(leftTempleStart, scaledLeftEar, bridgeTemplePaint);
      canvas.drawLine(rightTempleStart, scaledRightEar, bridgeTemplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.glassesFrameColor != glassesFrameColor ||
        oldDelegate.glassesLensColor != glassesLensColor ||
        oldDelegate.lensOpacity != lensOpacity;
  }
}
