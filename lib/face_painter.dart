import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Paint _eyeContourPaint;

  FacePainter({required this.faces})
      : _eyeContourPaint = Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

  void _drawEyeContour(Canvas canvas, FaceContour? contour) {
    if (contour != null && contour.points.isNotEmpty) {
      final path = Path()
        ..addPolygon(contour.points.map((p) => Offset(p.x as double, p.y as double)).toList(), true);
      canvas.drawPath(path, _eyeContourPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      print("yes");
      _drawEyeContour(canvas, face.contours[FaceContourType.leftEye]);
      _drawEyeContour(canvas, face.contours[FaceContourType.rightEye]);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) => oldDelegate.faces != faces;
}