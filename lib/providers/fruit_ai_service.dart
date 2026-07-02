import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ============================================================
//  FRUIT AI SERVICE — Klasifikasi varietas + kematangan dari warna
//  Model: Teachable Machine (Image) -> ekspor TensorFlow Lite (Floating point)
//  Taruh: assets/models/model.tflite  &  assets/models/labels.txt
//  Aman: jika model belum ada, service tetap jalan (siap=false) → app tidak crash.
// ============================================================

/// Hasil klasifikasi kamera
class HasilAI {
  const HasilAI(this.label, this.confidence);
  final String label;       // mis. "Mangga_Matang"
  final double confidence;  // 0..1

  String get labelRapi => label.replaceAll('_', ' ').trim();
}

class FruitAiService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  static const int _size = 224; // input MobileNet Teachable Machine

  /// true jika model + label sudah ter-load
  bool get siap => _interpreter != null && _labels.isNotEmpty;

  /// Muat model & label dari assets. Panggil sekali (mis. di initState).
  /// Lempar exception bila file belum ada — tangani dengan try/catch di pemanggil.
  Future<void> load() async {
    // Jika gagal, coba ganti path ke 'models/model.tflite' (tergantung versi paket)
    _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    final raw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        // Teachable Machine menulis "0 Mangga_Mentah" → buang indeks di depan
        .map((e) => e.contains(' ') ? e.substring(e.indexOf(' ') + 1) : e)
        .toList();
    debugPrint('[AI] Model siap. Label: $_labels');
  }

  /// Klasifikasi 1 foto. Return null jika model belum siap / gambar gagal dibaca.
  Future<HasilAI?> klasifikasi(File foto) async {
    if (!siap) return null;

    final decoded = img.decodeImage(await foto.readAsBytes());
    if (decoded == null) return null;
    final r = img.copyResize(decoded, width: _size, height: _size);

    // input [1,224,224,3], normalisasi [-1,1] (standar Teachable Machine)
    final input = List.generate(1, (_) => List.generate(_size, (y) =>
        List.generate(_size, (x) {
          final p = r.getPixel(x, y);
          return [p.r / 127.5 - 1.0, p.g / 127.5 - 1.0, p.b / 127.5 - 1.0];
        }),),);

    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter!.run(input, output);

    final skor = (output[0] as List).cast<double>();
    var best = 0;
    for (var i = 1; i < skor.length; i++) {
      if (skor[i] > skor[best]) best = i;
    }
    return HasilAI(_labels[best], skor[best]);
  }

  void dispose() {
    _interpreter?.close();
  }
}
