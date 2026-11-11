# Informasi Fitur UI

Dokumen ini berisi rancangan informasi dalam bahasa Indonesia untuk setiap bagian UI. Isinya belum dipasang sebagai tooltip atau teks bantuan di dalam aplikasi.

## 1. Vibration Manager

Vibration Manager digunakan untuk mengatur getaran yang berasal dari efek game, seperti tire slip, kerb, ABS, collision, G-force, off-road, engine RPM, dan gearshift.

## 2. Select Trigger to Configure (tidak perlu, sudah ditampilkan di deskripsi singkat)

## 3. Trigger Input

Hysteresis membantu mencegah input kecil atau noise di sekitar posisi awal trigger terbaca sebagai tekanan yang tidak diinginkan.

- `Threshold Up` menentukan kapan input mulai dianggap aktif.
- `Threshold Down` menentukan kapan input kembali dianggap tidak aktif.

## 4. Input Indicator (Vibrate)

- Mode `Proportional` mengikuti besar tekanan trigger. Semakin besar input, semakin kuat getarannya.
- Mode `Static` menggunakan kekuatan getaran yang tetap selama trigger sedang aktif.

## 5. Trigger Smooth

Memperhalus perubahan sinyal dari trigger yang mendadak. Gunakan **Time Constant** untuk mengatur tingkat kehalusan.

Catatan: Nilai yang lebih besar membuat perubahan lebih halus, tetapi respons terasa lambat.

## 6. Trigger Sensitivity

Trigger Sensitivity mengatur hubungan antara tekanan trigger dan output yang dihasilkan.

- `Knee X` menentukan posisi perubahan kurva.
- `Knee Y` menentukan seberapa besar respons kurva dibentuk.
- Preset tersedia sebagai titik awal pengaturan.

Kurva di bawah garis lurus (input sinyal yg masih linear) membuat tekanan awal lebih lambat (cocok untuk pedal rem saat trail braking). Kurva di atas garis lurus membuat respons akhir lebih lambat (cocok pedal Gas saat throttle control).

## 7. Preview

Gunakan bagian ini untuk melihat apakah input berubah sesuai harapan.

## 8. Signal Limit (masih blm ditulis)

### Status

Fitur ini masih direncanakan dan belum diimplementasikan.

### Penjelasan

Signal Limit akan digunakan untuk membatasi output maksimum rem. Fitur ini hanya ditampilkan ketika `Left Trigger (Brake)` dipilih.

Signal Limit berbeda dari Brake Power. Fitur ini hanya memotong input pada rentang `0–100%` secara linear atau 1:1. Nilai `100%` berarti tidak ada pembatasan tambahan.

Fitur ini berguna untuk mobil yang tidak menyediakan pengaturan pembatasan rem dari setup bawaan mobil.

### Teks informasi singkat

> Batasi output maksimum rem secara linear. Fitur ini hanya tersedia untuk Left Trigger (Brake).

## Hierarki pemrosesan

```text
Raw Input
  ↓
Trigger Input
  ↓
Trigger Smooth
  ↓
Trigger Sensitivity
  ↓
Processed Signal
```

Signal Limit akan ditambahkan setelah Trigger Sensitivity pada tahap berikutnya, khusus untuk LT/brake.
