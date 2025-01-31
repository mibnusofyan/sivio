import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class SignDetectionController extends GetxController {
  late Interpreter interpreter;
  RxBool isProcessing = false.obs;
  RxString detectedText = "".obs;
  final int modelInputSize = 224;

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initializeModel();
  }

  Future<void> initializeModel() async {
    try {
      // Load model
      interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> processFrame(CameraImage frame) async {
    if (isProcessing.value) return;

    isProcessing.value = true;
    try {
      // 1. Konversi frame kamera ke format yang bisa diproses
      final processedImage = await preprocessFrame(frame);
      if (processedImage == null) return;

      // 2. Jalankan deteksi
      final result = await runInference(processedImage);

      // 3. Update UI dengan hasil
      updateDetectionResult(result);
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<List<double>?> preprocessFrame(CameraImage frame) async {
    try {
      // Konversi YUV420 ke RGB
      final rgbImage = await convertYUV420toRGB(frame);
      if (rgbImage == null) return null;

      // Resize dan normalize image
      final processedData = normalizeImage(rgbImage);
      return processedData;
    } catch (e) {
      print('Error in preprocessing: $e');
      return null;
    }
  }

  Future<img.Image?> convertYUV420toRGB(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      final yBuffer = image.planes[0].bytes;
      final uBuffer = image.planes[1].bytes;
      final vBuffer = image.planes[2].bytes;

      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      final rgbImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yValue = yBuffer[y * yRowStride + x];
          final uValue = uBuffer[uvIndex];
          final vValue = vBuffer[uvIndex];

          int r = (yValue + 1.402 * (vValue - 128)).toInt().clamp(0, 255);
          int g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .toInt()
                  .clamp(0, 255);
          int b =
              (yValue + 1.772 * (uBuffer[uvIndex] - 128)).toInt().clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      return rgbImage;
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  List<double> normalizeImage(img.Image image) {
    // Resize ke ukuran input model
    final resized = img.copyResize(
      image,
      width: modelInputSize,
      height: modelInputSize,
    );

    // Normalize pixel values ke range [0,1] atau [-1,1]
    List<double> normalized = [];
    for (int y = 0; y < modelInputSize; y++) {
      for (int x = 0; x < modelInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        normalized.add(pixel.r / 255.0);
        normalized.add(pixel.g / 255.0);
        normalized.add(pixel.b / 255.0);
      }
    }

    return normalized;
  }

  Future<String> runInference(List<double> inputData) async {
    try {
      // Prepare input tensor
      var input = inputData.reshape([1, modelInputSize, modelInputSize, 3]);
      // Prepare output tensor (sesuaikan dengan output shape model Anda)
      var output = List.filled(1 * 31, 0).reshape([1, 31]);

      // Run inference
      interpreter.run(input, output);

      // Process hasil
      return interpretOutput(output);
    } catch (e) {
      print('Error in inference: $e');
      return '';
    }
  }

  String interpretOutput(List<dynamic> output) {
    // Implementasi sesuai dengan format output model Anda
    // Contoh sederhana: ambil index dengan nilai tertinggi
    var results = output[0] as List;
    int maxIndex = 0;
    double maxValue = results[0];

    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxValue) {
        maxIndex = i;
        maxValue = results[i];
      }
    }

    // Convert index ke text
    return getSignText(maxIndex);
  }

  void updateDetectionResult(String result) {
    detectedText.value = result;
  }

  String getSignText(int index) {
    // Mapping dari index ke text (sesuaikan dengan label model Anda)
    Map<int, String> signMap = {
      0: "0",
      1: "1",
      2: "2",
      3: "5",
      4: "selamat",
      5: "pagi",
      6: "tidur",
      7: "terima",
      8: "kasih",
      9: "maaf",
      10: "tolong",
      11: "ya",
      12: "makan",
      13: "minum",
      14: "jalan",
      15: "rumah",
      16: "dingin",
      17: "jam",
      18: "teman",
      19: "ayah",
      20: "ibu",
      21: "baca",
      22: "sepatu",
      23: "handphone",
      24: "hujan",
      25: "foto",
      26: "sayur",
      27: "meja",
      28: "saya",
      29: "kamu",
      30: "pergi",
      // Tambahkan mapping lainnya
    };

    return signMap[index] ?? "Tidak terdeteksi";
  }

  @override
  void onClose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    interpreter.close();
    super.onClose();
  }
}

class SignDetectorView extends StatelessWidget {
  final controller = Get.put(SignDetectionController());
  late CameraController cameraController;

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras[1], // Using front camera
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await cameraController.initialize();
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);

    cameraController.startImageStream((image) {
      controller.processFrame(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Language Detector'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder(
        future: setupCamera(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Transform.rotate(
                      angle: -90 * 3.14159 / 180,
                      child: CameraPreview(cameraController),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Obx(() => Text(
                          controller.detectedText.value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ),
                ),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}