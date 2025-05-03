import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FoodController {
  static late Interpreter _interpreter;
  static late List<String> _labels;

  /// Load the TFLite model and label file
  static Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/food_classifier.tflite');

    final labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsData.split('\n');
  }

  /// Predict the most probable food label from an image
  static Future<Map<String, dynamic>?> predictFood(File imageFile) async {
    final inputImage = img.decodeImage(await imageFile.readAsBytes());
    if (inputImage == null) return null;

    // Resize image to 224x224
    final resized = img.copyResize(inputImage, width: 224, height: 224);

    // Convert to Float32List and normalize pixel values (0–1)
    final input = Float32List(1 * 224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    final inputTensor = input.reshape([1, 224, 224, 3]);
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter.run(inputTensor, output);

    final result = List<double>.from(output[0]);
    final double maxConfidence = result.reduce((a, b) => a > b ? a : b);
    final int maxIndex = result.indexOf(maxConfidence);

    return {
      "label": _labels[maxIndex],
      "confidence": maxConfidence,
    };
  }
}
