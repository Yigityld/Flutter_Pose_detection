import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:body_detection/models/pose.dart';
import 'package:body_detection/models/pose_landmark.dart';
import 'package:body_detection/models/pose_landmark_type.dart';

int counter = 0;
bool isCounterIncreased = false;
bool isCounterIncreaseds = false;
bool isCounterIncreasedss = false;
class PoseMaskPainter extends CustomPainter {
  PoseMaskPainter({
    required this.pose,
    required this.mask,
    required this.imageSize,
  });

  final Pose? pose;
  final ui.Image? mask;
  final Size imageSize;
  final pointPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.8);
  final leftPointPaint = Paint()..color = const Color.fromRGBO(223, 157, 80, 1);
  final rightPointPaint = Paint()
    ..color = const Color.fromRGBO(100, 208, 218, 1);
  final linePaint = Paint()
    ..color = const Color.fromRGBO(255, 0, 0, 0.9)
    ..strokeWidth = 3;
  final yellowLinePaint = Paint()
    ..color = Colors.yellow
    ..strokeWidth = 3;
  final maskPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
        Color.fromRGBO(0, 0, 255, 0.5), BlendMode.srcOut);

  // Tüm açıları tutmak için tek bir liste oluştur
  final List<double> angleDegreesList = [0, 0, 0, 0];

  @override
  void paint(Canvas canvas, Size size) {
    _paintMask(canvas, size);
    _paintPose(canvas, size);
  }

  void _paintPose(Canvas canvas, Size size) {
    if (pose == null) return;

    final double hRatio =
    imageSize.width == 0 ? 1 : size.width / imageSize.width;
    final double vRatio =
    imageSize.height == 0 ? 1 : size.height / imageSize.height;

    offsetForPart(PoseLandmark part) =>
        Offset(part.position.x * hRatio, part.position.y * vRatio);

    // Landmark connections
    final landmarksByType = {for (final it in pose!.landmarks) it.type: it};

    for (int i = 0; i < connections.length; i++) {
      final connection = connections[i];
      final point1 = offsetForPart(landmarksByType[connection[0]]!);
      final point2 = offsetForPart(landmarksByType[connection[1]]!);
      double angleRadians =
      math.atan2(point2.dy - point1.dy, point2.dx - point1.dx);
      double angleDegrees = (angleRadians * 180 / math.pi);
      if (connection[0] == PoseLandmarkType.leftElbow &&
          connection[1] == PoseLandmarkType.leftShoulder) {
        angleDegrees += 90;
        angleDegrees *= -1;
        angleDegreesList[0] = (angleDegrees);
      } else if (connection[0] == PoseLandmarkType.leftWrist &&
          connection[1] == PoseLandmarkType.leftElbow) {
        angleDegrees += 90;
        angleDegrees *= -1;
        angleDegreesList[3] = (angleDegrees);
      } else if (connection[0] == PoseLandmarkType.rightWrist &&
          connection[1] == PoseLandmarkType.rightElbow) {
        angleDegrees += 90;
        angleDegreesList[2] = (angleDegrees);
      } else {
        angleDegrees -= 90;
        angleDegreesList[1] = (angleDegrees);
      }

      if (angleDegrees < 0) {
        angleDegrees += 360;
      } else if (angleDegrees > 360) {
        angleDegrees -= 360;
      }


      if ( i==1){
        if (isAngleInRange(angleDegrees)) {
          isCounterIncreaseds = true;
          canvas.drawLine(point1, point2, yellowLinePaint);
        }else{
          isCounterIncreaseds = false;
          canvas.drawLine(point1, point2, linePaint);
        }
      }
      else if ( i==0){
        if (isAngleInRange(angleDegrees)) {
          isCounterIncreasedss = true;
          canvas.drawLine(point1, point2, yellowLinePaint);
        }else{
          isCounterIncreasedss = false;
          canvas.drawLine(point1, point2, linePaint);
        }
      }
      else{
        canvas.drawLine(point1, point2, linePaint);
      }

      // linePaint rengini kontrol et ve gerektiğinde sarıya dönüştür
      if ((i == 0 || i == 1) && (!isCounterIncreaseds && !isCounterIncreasedss)) {
        isCounterIncreased = false;
      } else if (isCounterIncreaseds && isCounterIncreasedss && (i == 0 || i == 1)) {
        if (isAngleInRange(angleDegrees)) {
          if (!isCounterIncreased) {
            counter++;
            isCounterIncreased = true;
          }
        } else {
          isCounterIncreased = false;
        }
      } else {

      }


      // Açıyı ekrana yazdır
      TextSpan angleSpan = TextSpan(
        text: "${angleDegrees.toStringAsFixed(2)}°",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      );
      TextPainter angleTp = TextPainter(
          text: angleSpan, textAlign: TextAlign.left);
      angleTp.textDirection = TextDirection.ltr;
      angleTp.layout();
      angleTp.paint(
          canvas, Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2));
    }


    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
    );
    final textSpan = TextSpan(
      text: 'squat=$counter',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }

  void _paintMask(Canvas canvas, Size size) {
    if (mask == null) return;

    canvas.drawImageRect(
        mask!,
        Rect.fromLTWH(0, 0, mask!.width.toDouble(), mask!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        maskPaint);
  }

  @override
  bool shouldRepaint(PoseMaskPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.mask != mask ||
        oldDelegate.imageSize != imageSize;
  }

  bool isAngleInRange(double angleDegrees) {
    return (angleDegrees >= 90 && angleDegrees <= 180);
  }

  List<List<PoseLandmarkType>> get connections => [
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder],
    [PoseLandmarkType.rightWrist, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.leftWrist, PoseLandmarkType.leftElbow],
  ];
}