# Analisis Repo Gamepad Tweaks

## Ringkasan

Repo ini berisi plugin Lua untuk Assetto Corsa CSP Gamepad FX, versi `0.2`.
Implementasinya terdiri dari dua komponen utama:

- Script physics: `extension/lua/joypad-assist/gamepad_tweaks/`
- UI tuning: `apps/lua/gamepad_tweaks/`

Working tree saat dianalisis bersih. Belum tersedia unit test, mock API CSP, syntax check Lua, atau CI build.

## Komponen yang sudah tersedia

- Hysteresis deadzone untuk RT dan LT.
- EMA smoothing berbasis `dt`.
- Response curve quadratic Bezier.
- Konfigurasi live melalui file INI.
- UI tuning untuk trigger, curve, smoothing, dan vibration.
- Telemetry raw vs processed melalui `ac.connect()`.
- Routing native vibration berdasarkan efek dan motor.
- Script deploy, uninstall, dan packaging ZIP.

## Temuan penting

### 1. Jalur output input belum jelas tervalidasi

`assist.lua` mengambil data melalui `ac.getJoypadState()` lalu mengubah `data.gas` dan `data.brake` secara langsung. Kode tidak memanggil:

```lua
ac.setGas(...)
ac.setBrake(...)
```

Rencana proyek dan contoh implementasi Gamepad FX lain menggunakan setter CSP untuk menulis output ke physics engine. Karena belum ada validasi in-game atau dokumentasi lokal yang membuktikan object hasil `ac.getJoypadState()` mutable, jalur output ini harus dianggap sebagai risiko runtime utama.

### 2. Vibration belum memakai API yang direncanakan

`vibration.lua` menghitung nilai vibration dan menulis `data.vibrationLeft` serta `data.vibrationRight`, tetapi tidak memanggil:

```lua
ac.setControllerRumble(leftMotor, rightMotor, duration)
```

Akibatnya, kode mungkin hanya menghitung nilai tanpa benar-benar menghasilkan getaran. Parameter `duration` juga belum ditangani.

### 3. State gear vibration tidak di-reset

`vibration.reset()` saat ini kosong. State `lastGear` dan `gearJolt` dapat terbawa antar-session atau menghasilkan gear jolt palsu ketika session baru dimulai.

Selain itu, `gearJolt` dikurangi `0.05` per frame, bukan berdasarkan `dt`. Durasi getaran bisa berubah sesuai physics rate.

### 4. Dokumentasi tidak sinkron dengan implementasi

`docs/PLAN-B.md` dan `docs/PROMPT.md` masih menggambarkan proyek `hall_config` dan fase pengembangan awal, sedangkan source aktual sudah memakai nama `gamepad_tweaks` dan telah memiliki:

- response curve;
- telemetry;
- native haptics;
- UI tuning;
- live configuration.

Dokumentasi saat ini dapat membingungkan developer baru karena nama folder, fase, dan status implementasi tidak lagi cocok.

### 5. Belum ada automated test

Repo tidak memiliki test untuk:

- hysteresis;
- response curve;
- EMA smoothing;
- reset state;
- konfigurasi invalid;
- routing vibration.

Environment analisis juga tidak memiliki executable `lua` atau `luac`, sehingga syntax Lua belum dapat diverifikasi secara lokal.

### 6. Konfigurasi belum divalidasi secara menyeluruh

Nilai dari file INI dibaca langsung tanpa validasi lengkap. Nilai invalid dapat muncul pada:

- threshold hysteresis;
- motor routing;
- mode vibration;
- maximum vibration;
- smoothing time constant.

UI memang membatasi sebagian nilai, tetapi file konfigurasi tetap dapat diedit manual.

### 7. Artifact ZIP kemungkinan stale

`dist/gamepad-tweaks-v0.2.zip` masih berisi `temp.md`, sementara file tersebut sudah tidak ada di source tree. ZIP perlu dibangun ulang sebelum distribusi.

Selain itu, `deploy.bat` memakai path hardcoded ke repository dan instalasi Assetto Corsa developer saat ini.

## Prioritas perbaikan

1. Validasi output in-game dan pastikan input ditulis melalui API setter CSP yang benar.
2. Implementasikan vibration menggunakan `ac.setControllerRumble()` beserta strategi `duration` yang tervalidasi.
3. Reset seluruh state vibration dan ubah decay gear jolt agar berbasis `dt`.
4. Tambahkan test atau harness sederhana untuk signal processing.
5. Tambahkan validasi dan fallback aman untuk konfigurasi INI.
6. Sinkronkan README, PLAN-B, PROMPT, dan nama proyek aktual.
7. Rebuild ZIP dari source terbaru dan tambahkan validasi packaging.
8. Kurangi alokasi dan pekerjaan berat di physics thread.

## Kesimpulan

Struktur proyek dan fitur tuning sudah cukup matang untuk tahap prototipe, tetapi jalur penulisan input ke physics engine dan implementasi vibration masih menjadi blocker utama sebelum rilis dianggap aman. Analisis ini belum mengubah kode; perubahan yang diperlukan sebaiknya dimulai setelah perilaku API CSP dikonfirmasi melalui uji in-game.
