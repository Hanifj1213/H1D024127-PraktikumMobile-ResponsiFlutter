# Penjelasan kode LangitKota

## Urutan demo

1. **Home:** lihat nama kota, suhu saat ini, kelembapan, angin, suhu terasa, curah hujan, dan peluang hujan. Gulir untuk melihat tujuh hari; warna dan ikon bukan satu-satunya indikator kondisi.
2. **Pencarian:** buka ikon kaca pembesar dan ketik `Bandung`. Pilih nama dan wilayah yang sesuai. Ketuk ikon bintang sebelum memilih kota.
3. **Persistensi:** perbarui atau buka ulang aplikasi. Kota aktif tetap terpilih; pada halaman pencarian, favorit masih ada. Cuaca tetap dimuat dari API.
4. **Jika jaringan gagal:** lihat pesan galat dan tombol **Coba lagi**. Jika kueri valid tetapi tidak memiliki hasil, layar menampilkan **Kota tidak ditemukan**.

## Titik kode yang perlu dipahami

- `main.dart` menginisialisasi format tanggal Indonesia dan membaca preferensi sebelum menampilkan UI.
- `data/open_meteo.dart`: `Uri.https` mengenkode parameter pada kedua GET. Klien `package:http` menerima byte respons; `utf8.decode` dan `jsonDecode` mengubahnya menjadi data Dart. Batas waktu 12 detik dan status non-200 diterjemahkan menjadi pesan untuk pengguna.
- `models/weather.dart`: API mengirim prakiraan dalam bentuk beberapa array paralel. `DailyWeather.at()` memakai indeks tanggal untuk mengambil minimum, maksimum, kode WMO, dan peluang hujan dari hari yang sama.
- `viewmodels/search_model.dart`: timer 400 ms menghindari satu request untuk setiap karakter. Pencarian via Enter langsung berjalan. Nomor revisi berubah saat kueri berubah sehingga hasil lama tidak mengganti hasil baru.
- `viewmodels/weather_model.dart`: membuka atau mengganti kota memicu `refresh()`. Setelah hasil/error, `notifyListeners()` memicu render ulang. Saat kota berubah, cuaca kota sebelumnya dibersihkan agar tidak terlihat sebagai cuaca kota baru.
- `data/local_places.dart`: satu nilai JSON menyimpan pilihan aktif, favorit, dan maksimum delapan entri riwayat. ID geocoding membedakan dua kota yang namanya sama. Penulisan dijalankan berurutan untuk menghindari benturan.
- `views/`: Theme Material 3 menetapkan warna dan tipografi. `LayoutBuilder` memilih susunan bertumpuk pada layar sempit dan dua kolom pada layar lebar.

## Tanya jawab latihan

| Pertanyaan | Inti jawaban |
| --- | --- |
| Kenapa setelah memilih hasil pencarian masih ada GET kedua? | Geocoding mengembalikan lokasi dan koordinat, bukan cuaca. Forecast membutuhkan koordinat dari hasil itu. |
| Kenapa `timezone=auto`? | Waktu terkini serta tanggal prakiraan mengikuti lokasi kota, bukan zona perangkat. |
| Apa beda 0% dan `—`? | `0%` adalah nilai yang dikirim API. `—` berarti field tidak tersedia. |
| Bagaimana jika dua respons tiba terbalik? | ViewModel cuma menerapkan respons milik nomor permintaan/revisi terbaru. |
| Apa yang tersimpan ketika aplikasi ditutup? | Metadata lokasi aktif, favorit, dan riwayat. Data cuaca diminta ulang saat aplikasi dibuka. |
| Kenapa tidak menaruh HTTP di `build()`? | `build()` dapat dipanggil berulang. ViewModel melakukan I/O dan View hanya merender state. |
