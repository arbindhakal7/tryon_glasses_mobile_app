import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'face_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final FaceDetector _faceDetector;
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isProcessing = false;
  List<Face> _faces = [];
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      _showMessage('Camera permission is required.');
      return;
    }

    try {
      _cameras = await availableCameras();
      final frontCameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );

      if (frontCameraIndex == -1) throw 'Front camera not found';

      _cameraIndex = frontCameraIndex;

      _controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() => _isInitialized = true);
      await _startImageStream();
    } catch (e) {
      _showMessage('Error initializing camera: $e');
      if (kDebugMode) print('Camera init error: $e');
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized || _isStreaming) return;

    await _controller!.startImageStream(_processCameraImage);
    setState(() => _isStreaming = true);
  }

  Future<void> _stopImageStream() async {
    if (_controller != null && _isStreaming) {
      await _controller!.stopImageStream();
      setState(() => _isStreaming = false);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !mounted || _controller == null || !_controller!.value.isInitialized) return;

    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) throw 'Failed to convert image';

      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces = faces;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var deviceOrientation = _controller!.value.deviceOrientation;
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;

      rotation = InputImageRotationValue.fromRawValue(
        camera.lensDirection == CameraLensDirection.front
            ? (sensorOrientation + rotationCompensation) % 360
            : (sensorOrientation - rotationCompensation + 360) % 360,
      );
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized && _controller != null && _controller!.value.isInitialized
          ? Stack(
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159), // Mirror front camera
                  child: CameraPreview(_controller!),
                ),
                CustomPaint(
                  painter: FacePainter(faces: _faces),
                  size: Size.infinite,
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
