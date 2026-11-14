import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class DetectorScreen extends StatefulWidget {
  final String nomeFuncionario;

  const DetectorScreen({super.key, required this.nomeFuncionario});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlertaSonolenciaAtivo = false;

  int _framesOlhosFechados = 0;

  CameraController? _cameraController;
  bool _isBusy = false;
  List<Face> _faces = [];
  CameraDescription? _camera;
  bool _mostrarPontos = true;
  String _debugText = "A aguardar câmera...";

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: false,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _solicitarPermissao();
  }

  Future<void> _solicitarPermissao() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _iniciarCamera();
    } else {
      if (mounted) setState(() => _debugText = "Sem permissão de câmera!");
    }
  }

  Future<void> _iniciarCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _debugText = "Nenhuma câmera encontrada.");
      return;
    }

    _camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _camera!,
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        await _cameraController!.startImageStream(_processarImagem);
        setState(() => _debugText = "Câmera Iniciada!");
      }
    } catch (e) {
      if (mounted) setState(() => _debugText = "ERRO: ${e.toString()}");
    }
  }

  Future<void> _processarImagem(CameraImage image) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _imageToInputImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      bool olhosFechadosNesteFrame = false;

      for (final face in faces) {
        final double? leftEyeOpen = face.leftEyeOpenProbability;
        final double? rightEyeOpen = face.rightEyeOpenProbability;

        if (leftEyeOpen != null && rightEyeOpen != null) {
          if (leftEyeOpen < 0.2 && rightEyeOpen < 0.2) {
            olhosFechadosNesteFrame = true;
          }
        }
      }

      if (olhosFechadosNesteFrame) {
        _framesOlhosFechados++;
      } else {
        _framesOlhosFechados = 0;
      }

      bool motoristasonolento = _framesOlhosFechados > 22;

      if (mounted) {
        setState(() {
          _faces = faces;
          _isAlertaSonolenciaAtivo = motoristasonolento;
          if (motoristasonolento) {
            _debugText = "⚠️ ALERTA: SONOLÊNCIA PROLONGADA!";
          } else if (olhosFechadosNesteFrame) {
            _debugText = "Piscar detetado (A monitorizar...)";
          } else {
            _debugText = "Estado: Atento";
          }
        });

        if (motoristasonolento) {
          _tocarAlarme();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _debugText = "Erro IA: ${e.toString().split('\n').first}");
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _tocarAlarme() async {
    try {
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      // Ignora erro de áudio
    }
  }
  InputImage? _imageToInputImage(CameraImage image) {
    if (_camera == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageRotation? imageRotation = InputImageRotationValue.fromRawValue(_camera!.sensorOrientation);
    if (imageRotation == null) return null;

    final InputImageFormat? inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _alternarPontos() {
    setState(() => _mostrarPontos = !_mostrarPontos);
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          if (_isAlertaSonolenciaAtivo)
            Positioned.fill(
              child: Container(
                color: Colors.red.withOpacity(0.7),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 120, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "SONOLÊNCIA DETECTADA",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 50, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.person, color: Colors.greenAccent),
                  Text(
                    "Condutor: ${widget.nomeFuncionario.split(' ').first}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.circle, color: Colors.green, size: 12),
                ],
              ),
            ),
          ),

          if (_faces.isEmpty)
            Positioned(
              top: 120, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                child: const Text("Nenhum rosto detectado!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

          if (_mostrarPontos)
            CustomPaint(
              painter: FacePainter(
                faces: _faces,
                imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
              ),
            ),

          Positioned(
            bottom: 40, right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.greenAccent,
              onPressed: _alternarPontos,
              child: Icon(_mostrarPontos ? Icons.visibility : Icons.visibility_off),
            ),
          ),

          Positioned(
            bottom: 120, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Text(_debugText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;

  FacePainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellowAccent;

    for (final face in faces) {
      for (final contour in face.contours.values) {
        if (contour != null) {
          for (final point in contour.points) {
            final double x = size.width - (point.x.toDouble() * size.width / imageSize.width);
            final double y = point.y.toDouble() * size.height / imageSize.height;

            canvas.drawCircle(Offset(x, y), 2.5, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => true;
}