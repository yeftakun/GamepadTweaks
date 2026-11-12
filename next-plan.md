# Next Plan — Penyederhanaan UI dan Pipeline Trigger

## Tujuan

Menyederhanakan UI menjadi beberapa bagian yang lebih mudah dipahami, sekaligus memastikan alur sinyal trigger dan indikator input dapat diverifikasi dengan jelas.

## Struktur UI utama

### 1. Vibration Manager

Rebranding bagian pengaturan vibration menjadi **Vibration Manager**.

Fokus bagian ini adalah mengatur variabel getaran output dari native game effects dan routing motor.

Rencana perubahan:

- Kelompokkan seluruh pengaturan output vibration di satu tempat.
- Gunakan pilihan intensitas berjenjang, bukan slider detail 1–100%:
  - 0 = `0%`
  - 1 = `20%`
  - 2 = `40%`
  - 3 = `60%`
  - 4 = `80%`
  - 5 = `100%`
- Pertahankan pengaturan routing motor jika masih diperlukan.
- Pertahankan mode vibration yang sudah ada jika masih relevan, seperti proportional dan static.
- Audit seluruh variabel output vibration.
- Pastikan setiap variabel yang ditampilkan benar-benar memengaruhi output vibration.
- Pastikan perubahan nilai dapat diverifikasi melalui pengujian in-game.

Acceptance criteria:

- Semua output vibration yang tersedia memiliki pengaturan yang jelas.
- Setiap level intensitas menghasilkan perubahan yang dapat dirasakan atau diukur.
- Tidak ada kontrol UI yang terlihat tetapi tidak berfungsi.
- Konflik ketika dua trigger memakai motor yang sama tetap menggunakan resolusi yang konsisten.

## Aturan UI/UX opsi trigger

Selector opsi trigger yang sudah ada tetap dipertahankan posisinya setelah **Vibration Manager** dan sebelum bagian pengaturan trigger lainnya.

Urutan tampilan UI yang harus dipertahankan:

```text
Vibration Manager
      ↓
Trigger Option
  RT (Gas) / LT (Brake)
      ↓
Trigger Input
  input cleaning
  Input Indicator (Vibrate)
      ↓
Trigger Smooth
      ↓
Trigger Sensitivity
      ↓
Preview
```

Aturan selector:

- Pengguna tetap memilih trigger yang ingin dikonfigurasi melalui opsi `RT (Gas)` atau `LT (Brake)`.
- Trigger Input, Input Indicator (Vibrate), Trigger Smooth, Trigger Sensitivity, dan Preview mengikuti trigger yang sedang dipilih.
- Selector berlaku untuk satu trigger aktif pada satu waktu, bukan untuk menampilkan konfigurasi RT dan LT sekaligus.
- Tampilkan label `Right Trigger (Gas)` atau `Left Trigger (Brake)` pada setiap bagian yang mengikuti selector.
- Tampilkan keterangan singkat bahwa semua pengaturan di bawah selector berlaku untuk trigger yang dipilih.
- Jangan memindahkan selector trigger ke bawah bagian pemrosesan.
- Jangan membuat halaman konfigurasi terpisah untuk RT dan LT jika tidak diperlukan.
- Fitur yang hanya relevan untuk rem harus ditampilkan secara kontekstual pada opsi `LT (Brake)`.

### 2. Trigger Sensitivity

Rebranding bagian response curve menjadi **Trigger Sensitivity**.

Nama ini dipilih karena lebih umum dipahami dan memiliki istilah yang serupa pada game lain, termasuk brake sensitivity di LMU.

Fokus bagian ini adalah mengatur seberapa sensitif output trigger terhadap tekanan fisik.

Rencana perubahan:

- Gunakan istilah `Trigger Sensitivity` di UI, dokumentasi, dan konfigurasi yang terlihat user.
- Pertahankan pengaturan response curve yang sudah ada apabila perilakunya masih sesuai.
- Pastikan perubahan sensitivity memengaruhi sinyal trigger yang sudah melewati tahap input cleaning dan smoothing.
- Jelaskan secara singkat perbedaan sensitivity dengan smoothing:
  - Sensitivity mengubah hubungan input terhadap output.
  - Smoothing memperhalus perubahan sinyal dari waktu ke waktu.

Acceptance criteria:

- Pengguna dapat memahami apakah perubahan yang dibuat adalah sensitivity atau smoothing.
- Input ringan, sedang, dan penuh menunjukkan respons yang sesuai dengan konfigurasi.
- Kurva sensitivity tidak menciptakan deadzone tambahan yang tidak disengaja.

### 3. Trigger Input

Rebranding bagian input dasar menjadi **Trigger Input**.

Bagian ini berfokus pada input trigger fisik sebelum diproses lebih lanjut.

Rencana perubahan:

- Gunakan istilah `Trigger Input` di UI.
- Tempatkan pengaturan yang berkaitan dengan pembersihan input dasar di bagian ini.
- Tampilkan indikator input untuk RT dan LT.
- Pertahankan indikator pedal/trigger yang saat ini sudah berfungsi.
- Tempatkan bagian `Input Indicator (Vibrate)` di bagian paling akhir dari Trigger Input.
- Gunakan selector trigger aktif untuk mengatur indikator vibration dari satu trigger yang dipilih.
- Pastikan indikator menggunakan sumber data yang benar dan memperlihatkan nilai raw input yang diterima sistem.
- Bedakan dengan jelas raw input dan processed input.
- Tambahkan verifikasi untuk kondisi berikut:
  - trigger tidak ditekan;
  - trigger ditekan sebagian;
  - trigger ditekan penuh;
  - RT dan LT ditekan bersamaan;
  - nilai input berubah secara cepat.

Acceptance criteria:

- Indikator RT dan LT berubah secara live ketika trigger ditekan.
- Nilai indikator sesuai dengan input yang diterima script.
- Indikator tetap bekerja ketika smoothing, sensitivity, atau vibration dinonaktifkan.

### 3b. Trigger Smooth

Fitur yang memperhalus input dipisahkan dari **Trigger Input** dan diberi nama **Trigger Smooth**.

Fokus bagian ini adalah mengurangi noise, stutter, dan perubahan input yang terlalu mendadak.

Rencana perubahan:

- Pindahkan pengaturan smoothing ke bagian tersendiri.
- Pertahankan smoothing berbasis `dt` agar hasil tidak bergantung pada frame rate.
- Sediakan toggle enable/disable untuk RT dan LT.
- Sediakan parameter smoothing yang memang diperlukan, tanpa mencampurnya dengan sensitivity.
- Gunakan preview untuk membandingkan raw input dengan input setelah smoothing.

Acceptance criteria:

- Input yang tidak stabil menjadi lebih halus ketika Trigger Smooth aktif.
- Input tidak mengalami delay berlebihan.
- Saat Trigger Smooth dinonaktifkan, sinyal kembali merepresentasikan input tanpa smoothing.
- Reset session tidak membawa state smoothing dari session sebelumnya.

### 4. Preview

Preview dipisahkan menjadi bagian UI tersendiri.

Preview harus membantu pengguna memahami perubahan sinyal sepanjang pipeline, bukan hanya menampilkan satu nilai akhir.

Rencana perubahan:

- Pindahkan preview keluar dari bagian Trigger Input.
- Tampilkan minimal:
  - raw input;
  - input setelah Trigger Input;
  - input setelah Trigger Smooth;
  - input setelah Trigger Sensitivity;
  - processed trigger signal.
- Tampilkan RT dan LT secara terpisah.
- Pastikan preview memperbarui data secara live.
- Gunakan label yang konsisten dengan hierarki pemrosesan.

Acceptance criteria:

- Setiap tahap pipeline dapat dibedakan secara visual.
- Preview dapat digunakan untuk menemukan tahap yang menyebabkan input tidak sesuai.
- Nilai preview konsisten dengan nilai yang benar-benar digunakan untuk output.

## Hierarki pemrosesan sinyal

Urutan utama yang harus dipertahankan:

```text
Raw Input
  trigger fisik
      ↓
Trigger Input
  pembersihan/input cleaning
      ↓
Trigger Smooth
  smoothing berbasis dt
      ↓
Trigger Sensitivity
  response curve/sensitivity
      ↓
Processed Trigger Signal
```

Secara ringkas:

```text
raw input (trigger fisik)
> dibersihkan lewat Trigger Input
> diperhalus lewat Trigger Smooth
> diatur lewat Trigger Sensitivity
> processed trigger signal
```

Setiap tahap harus mempunyai data output yang dapat digunakan oleh Preview untuk debugging.

## Fitur lanjutan: Signal Limit (diimplementasikan pada v0.3)

Fitur ini sudah diimplementasikan setelah tiga bagian utama dan Preview.

### Tujuan

**Signal Limit** digunakan untuk membatasi maksimum sinyal trigger pada rentang input `0–100%`.

Fitur ini ditujukan untuk mobil yang tidak menyediakan pengaturan built-in seperti Brake Power.

Nama `Signal Limit` dipilih karena fitur ini hanya membatasi input maksimum sampai persentase tertentu. Istilah `Brake Power` dapat membingungkan karena beberapa mobil bisa menyediakan nilai di atas `100%`, misalnya `Brake Power 120%`.

### Implementasi fitur

- Jangan tampilkan Signal Limit sebagai bagian global atau sebagai opsi terpisah untuk RT.
- Tampilkan pengaturan **Signal Limit** hanya ketika pengguna memilih opsi trigger `LT (Brake)`.
- Jangan tampilkan kontrol Signal Limit ketika opsi `RT (Gas)` sedang dipilih.
- Sediakan nilai batas maksimum dalam rentang `0–100%`.
- Potong langsung processed trigger signal secara linear atau 1:1.
- Jangan mengubah bentuk kurva secara non-linear.
- Jangan menerapkan limit sebelum Trigger Sensitivity.
- Pastikan Signal Limit hanya memengaruhi processed signal LT/brake.

### Hierarki setelah Signal Limit ditambahkan

```text
Raw Input
  trigger fisik
      ↓
Trigger Input
  pembersihan/input cleaning
      ↓
Trigger Smooth
  smoothing berbasis dt
      ↓
Trigger Sensitivity
  response curve/sensitivity
      ↓
Signal Limit
  pemotongan linear/1:1 pada processed signal
      ↓
Processed Trigger Signal
```

Secara ringkas:

```text
raw input (trigger fisik)
> Trigger Input
> Trigger Smooth
> Trigger Sensitivity
> Signal Limit
> processed trigger signal
```

Acceptance criteria:

- Signal Limit hanya terlihat pada opsi `LT (Brake)`.
- Saat opsi `RT (Gas)` dipilih, tidak ada kontrol Signal Limit yang ditampilkan.
- LT/brake tidak pernah menghasilkan output di atas batas yang ditentukan.
- RT/gas tetap bekerja normal dan tidak dipengaruhi Signal Limit.
- Nilai `100%` menghasilkan perilaku tanpa pembatasan tambahan.
- Nilai batas diterapkan linear/1:1 pada processed signal.
- Preview menunjukkan perbedaan antara processed signal sebelum dan sesudah Signal Limit.

## Urutan pengerjaan

1. Rebranding dan penyederhanaan UI menjadi tiga bagian utama.
2. Memisahkan Trigger Smooth dari Trigger Input.
3. Memindahkan Preview menjadi bagian mandiri.
4. Menguji seluruh variabel output pada Vibration Manager.
5. Memastikan hierarki pipeline dan data preview benar.
6. Menambahkan Signal Limit hanya di dalam opsi `LT (Brake)`. (Selesai pada v0.3.)
