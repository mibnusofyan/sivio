import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignDetectionController extends GetxController {
  late Interpreter interpreter;
  RxBool isProcessing = false.obs;
  RxString detectedText = "".obs;
  final int modelInputSize = 128;
  late GpuDelegateV2 gpuDelegate;
  final Queue<List<double>> frameQueue = Queue();
  final int maxQueueSize = 4;

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initializeModel();
  }

  Future<void> initializeModel() async {
    try {
      final options = InterpreterOptions();

      // Tambahkan GPU Delegate
      try {
        options.addDelegate(GpuDelegateV2());
        print('GPU Delegate enabled');
      } catch (e) {
        print('Failed to add GPU Delegate: $e');
      }

      // Set thread count untuk CPU
      options.threads = 4;

      // Load model
      interpreter =
          await Interpreter.fromAsset('assets/model.tflite', options: options);
      //interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
      interpreter = await Interpreter.fromAsset('assets/model.tflite');
    }
  }

  DateTime? _lastProcessingTime;
  static const int _processingInterval = 100;
  // Future<void> processFrame(CameraImage frame) async {
  //   final now = DateTime.now();
  //   if (_lastProcessingTime != null &&
  //       now.difference(_lastProcessingTime!) <
  //           Duration(milliseconds: _processingInterval)) {
  //     return;
  //   }

  //   if (isProcessing.value) return;

  //   isProcessing.value = true;
  //   _lastProcessingTime = now;

  //   try {
  //     final processedImage = await preprocessFrame(frame);
  //     if (processedImage == null) return;

  //     final result = await runInference(processedImage);
  //     updateDetectionResult(result);
  //   } catch (e) {
  //     print('Error processing frame: $e');
  //   } finally {
  //     isProcessing.value = false;
  //   }
  // }

  Future<void> processFrame(CameraImage frame) async {
    final now = DateTime.now();
    if (_lastProcessingTime != null &&
        now.difference(_lastProcessingTime!) <
            Duration(milliseconds: _processingInterval)) {
      return;
    }

    if (isProcessing.value) return;

    isProcessing.value = true;
    _lastProcessingTime = now;

    try {
      final processedImage = await preprocessFrame(frame);
      if (processedImage == null) return;

      // Process single frame
      final result = await runInference(processedImage);

      // Debug log
      print('Processing result: $result');

      if (result.isNotEmpty) {
        updateDetectionResult(result);
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  // Tambahkan method untuk membersihkan queue
  void clearFrameQueue() {
    frameQueue.clear();
    isProcessing.value = false;
    print('Frame queue cleared');
  }

  Future<List<double>?> preprocessFrame(CameraImage frame) async {
    try {
      final rgbImage = await convertYUV420toRGB(frame);
      if (rgbImage == null) return null;

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
    final resized = img.copyResize(
      image,
      width: modelInputSize,
      height: modelInputSize,
    );

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
    // try {
    //   var input = inputData.reshape([1, modelInputSize, modelInputSize, 3]);

    //   var output = List.filled(1 * 31, 0).reshape([1, 31]);

    //   // Run inference dengan timing
    //   final stopwatch = Stopwatch()..start();

    //   interpreter.run(input, output);

    //   stopwatch.stop();
    //   print('Inference time: ${stopwatch.elapsedMilliseconds}ms');

    //   return interpretOutput(output);
    // } catch (e) {
    //   print('Error in inference: $e');
    //   return '';
    // }

    try {
      // Reshape input untuk single inference
      var input = inputData.reshape([1, modelInputSize, modelInputSize, 3]);

      // Prepare output tensor
      var output = List<List<double>>.filled(
        1,
        List<double>.filled(31, 0.0),
      );

      // Run inference
      final stopwatch = Stopwatch()..start();
      interpreter.run(input, output);
      stopwatch.stop();

      print('Inference time: ${stopwatch.elapsedMilliseconds}ms');
      print('Output shape: ${output.length}x${output[0].length}');

      return interpretOutput(output[0]);
    } catch (e) {
      print('Error in inference: $e');
      return '';
    }
  }

  String interpretOutput(List<dynamic> output) {
    try {
      // Print raw output untuk debugging
      print('Raw output: $output');

      double maxValue = double.negativeInfinity;
      int maxIndex = 0;

      // Pastikan kita mengakses list dengan benar
      final results = output is List ? output : [output];

      for (int i = 0; i < results.length; i++) {
        double value =
            results[i] is double ? results[i] : results[i].toDouble();
        if (value > maxValue) {
          maxValue = value;
          maxIndex = i;
        }
      }

      print('Selected index: $maxIndex, value: $maxValue');
      String result = getSignText(maxIndex);
      print('Detected text: $result');
      return result;
    } catch (e) {
      print('Error in interpretOutput: $e');
      return "Tidak terdeteksi";
    }
  }

  void updateDetectionResult(String result) {
    detectedText.value = result;
  }

  final ImagePicker _picker = ImagePicker();
  RxString imagePath = "".obs;
  RxBool isCameraMode = true.obs;
  RxBool isImageProcessing = false.obs;

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imagePath.value = pickedFile.path;
        await processImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> processImage(File imageFile) async {
    if (isImageProcessing.value) return;

    isImageProcessing.value = true;
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      final processedData = normalizeImage(image);

      final result = await runInference(processedData);

      updateDetectionResult(result);
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      isImageProcessing.value = false;
    }
  }

  void enableCameraMode() {
    isCameraMode.value = true;
    detectedText.value = "";
    imagePath.value = "";
  }

  // Fungsi untuk mengaktifkan mode gambar dari galeri
  void enableGalleryMode() {
    isCameraMode.value = false;
    detectedText.value = "";
  }

  String getSignText(int index) {
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
    clearFrameQueue();
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
      cameras[1],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await cameraController.initialize();
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await cameraController.setFlashMode(FlashMode.off);
    DateTime? lastProcessingTime;

    cameraController.startImageStream((image) {
      if (controller.isCameraMode.value) {
        final now = DateTime.now();
        if (lastProcessingTime == null ||
            now.difference(lastProcessingTime!).inMilliseconds > 500) {
          controller.processFrame(image);
          lastProcessingTime = now;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: setupCamera(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        controller.enableCameraMode();
                      },
                      child: Text("Gunakan Kamera"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isCameraMode.value
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.enableGalleryMode();
                        controller.pickImageFromGallery();
                      },
                      child: Text("Pilih Gambar dari Galeri"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !controller.isCameraMode.value
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isCameraMode.value) {
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
                              // child: Transform.rotate(
                              //   angle: -90 * 3.14159 / 180,
                              //   child: CameraPreview(cameraController),
                              // ),
                              // clipBehavior: Clip.hardEdge,
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child:Transform.rotate(
                                  angle: -90 * 3.14159 / 180,
                                  child: CameraPreview(cameraController),
                                )
                                // child: Transform.scale(
                                //   scale: cameraController.value.aspectRatio,
                                //   child: Center(
                                //     child: CameraPreview(cameraController),
                                //   ),
                                // ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              // child: Text(
                              //   controller.detectedText.value,
                              //   style: TextStyle(
                              //     fontSize: 24,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              child: Obx(() {
                                final text = controller.detectedText.value;
                                print('Displaying text: $text'); // Debug log
                                return Text(
                                  text.isEmpty ? "Mendeteksi..." : text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          if (controller.imagePath.value.isNotEmpty)
                            Expanded(
                              child: Image.file(
                                File(controller.imagePath.value),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                controller.detectedText.value,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }),
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
