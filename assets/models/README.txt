TARUH MODEL AI DI SINI
======================

1. Latih model di https://teachablemachine.withgoogle.com
   - Image Project -> Standard
   - Buat kelas (mis. Mangga_Mentah, Mangga_Setengah, Mangga_Matang, Mangga_Lunak)
   - 50-100 foto per kelas (buah nyata, berbagai sudut & cahaya)
   - Train Model -> Export Model -> tab "TensorFlow Lite" -> "Floating point" -> Download

2. Dari hasil download, salin 2 file ke folder ini:
   - model.tflite
   - labels.txt

3. Jalankan: flutter pub get  (lalu flutter run)

Catatan: selama model.tflite belum ada di sini, aplikasi TETAP berjalan
(mode sensor-only) tanpa crash. Kamera+AI otomatis aktif begitu file model tersedia.
