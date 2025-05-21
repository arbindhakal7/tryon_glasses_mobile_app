import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tryon/utils/face_painter.dart'; // Assuming face_painter.dart is in the same directory or adjust path

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
  List<CameraDescription> _cameras =
      []; // Still needed to find the front camera

  // Selected colors for frame and lens, and lens opacity
  Color _selectedFrameColor =
      Colors.black; // Default frame color changed to black for clarity
  Color _selectedLensColor =
      Colors.red; // Default lens color changed to red for clarity
  double _lensOpacity =
      0.5; // Default lens opacity increased for better visibility

  // List of available colors for both frame and lens
  final List<Color> _availableColors = [
    Colors.grey[800]!, // Dark Grey
    Colors.black, // Black
    Colors.brown[700]!, // Dark Brown
    Colors.blue[700]!, // Dark Blue
    Colors.red[700]!, // Dark Red
    Colors.green[700]!, // Dark Green
    Colors.transparent, // For clear lenses if desired
  ];

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
        enableLandmarks: true,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopImageStream(); // Ensure stream is stopped before disposing
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

      // Find the front camera explicitly
      CameraDescription? frontCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      if (frontCamera == null) {
        _showMessage('Front camera not found.');
        return;
      }

      _controller = CameraController(
        frontCamera, // Use the found front camera
        ResolutionPreset
            .medium, // Changed to medium for better performance on some devices
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid
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
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStreaming)
      return;

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
    if (_isProcessing ||
        !mounted ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

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
    // Get the description of the active camera (which is now always the front camera)
    final camera = _controller!.description;
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

    if (Platform.isAndroid && format == InputImageFormat.yuv_420_888) {
      Uint8List nv21Data = _convertYUV420ToNV21(image); // Use internal helper

      return InputImage.fromBytes(
        bytes: nv21Data,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != ImageFormatGroup.bgra8888)) {
      return null;
    }

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

  // Moved convertYUV420ToNV21 inside the class and made it private
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = width * height + (width * height ~/ 2);
    final nv21 = Uint8List(numPixels);

    int idY = 0;
    int idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 2;

    for (int y = 0; y < height; ++y) {
      final yOffset = y * yRowStride;
      for (int x = 0; x < width; ++x) {
        nv21[idY++] = yBuffer[yOffset + x * yPixelStride];
      }
    }

    for (int y = 0; y < uvHeight; ++y) {
      final uvOffset = y * uvRowStride;
      for (int x = 0; x < uvWidth; ++x) {
        final bufferIndex = uvOffset + (x * uvPixelStride);
        nv21[idUV++] = vBuffer[bufferIndex];
        nv21[idUV++] = uBuffer[bufferIndex];
      }
    }
    return nv21;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      // No AppBar
      body:
          _isInitialized &&
                  _controller != null &&
                  _controller!.value.isInitialized
              ? Stack(
                children: [
                  // Camera preview takes full screen
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(
                        3.14159,
                      ), // Mirror front camera
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  // FacePainter overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FacePainter(
                        faces: _faces,
                        imageSize: Size(
                          _controller!
                              .value
                              .previewSize!
                              .height, // Camera preview is rotated
                          _controller!.value.previewSize!.width,
                        ),
                        isFrontCamera:
                            true, // Always true as we only use front camera
                        glassesFrameColor:
                            _selectedFrameColor, // Pass the selected frame color
                        glassesLensColor:
                            _selectedLensColor, // Pass the selected lens color
                        lensOpacity:
                            _lensOpacity, // Pass the selected lens opacity
                      ),
                    ),
                  ),
                  // Color selection UI overlaid on top of the camera
                  Positioned(
                    bottom: 16.0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Frame Color Selection
                          Text(
                            'Frame Color:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableColors.length,
                              itemBuilder: (context, index) {
                                final color = _availableColors[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFrameColor = color;
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _selectedFrameColor == color
                                                ? Colors.blueAccent
                                                : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child:
                                        _selectedFrameColor == color
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                            : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Lens Color Selection
                          Text(
                            'Lens Color:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableColors.length,
                              itemBuilder: (context, index) {
                                final color = _availableColors[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedLensColor = color;
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _selectedLensColor == color
                                                ? Colors.blueAccent
                                                : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child:
                                        _selectedLensColor == color
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                            : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Lens Opacity Slider
                          Text(
                            'Lens Opacity: ${(_lensOpacity * 100).toInt()}%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          Slider(
                            value: _lensOpacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10, // 0%, 10%, ..., 100%
                            label: (_lensOpacity * 100).toInt().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _lensOpacity = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
