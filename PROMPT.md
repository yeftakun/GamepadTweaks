# Prompt 1 — Setup & Validasi Baseline (Fase 0)

Baca file PLAN-B.md di root proyek ini secara menyeluruh sebelum mulai apapun — termasuk §2.1 (formula), §2.2 (workflow & path AC), dan §3 (struktur folder).

Kerjakan HANYA Fase 0 dulu:
1. Buat struktur folder persis seperti §3 (extension/lua/joypad-assist/hall_config/ dengan manifest.ini + assist.lua skeleton).
2. assist.lua skeleton minimal: script.update(dt) yang cuma ac.log() tiap beberapa detik, buat konfirmasi script ke-load.
3. Investigasi dulu poin di §2.2: apakah CSP hot-reload script Lua atau perlu restart total acs.exe tiap edit. Laporkan hasilnya ke saya.
4. Validasi mapping axis SPESIFIK untuk controller saya (Gamesir Nova Lite) — log semua gamepad.axes[1..8] sambil saya gerakkan RT/LT/Left Stick, JANGAN asumsi axes[3]/axes[4] otomatis benar seperti di contoh dokumentasi.
5. Setelah axis terkonfirmasi, buat passthrough MURNI tanpa processing sama sekali (ac.setGas/ac.setBrake langsung dari raw axis) — baseline dulu sebelum ada logic apapun.
6. JANGAN auto-deploy ke folder Assetto Corsa. Saya sudah punya deploy.bat sendiri di root repo untuk hapus+deploy manual — cukup pastikan struktur folder source di repo (extension/lua/joypad-assist/hall_config/) sudah benar sesuai §3, saya yang akan jalankan deploy.bat sendiri kapan siap test.
JANGAN kerjakan Fase 1 ke atas dulu. JANGAN tambah fitur/logic di luar yang diminta di sini. Kalau ada yang ambigu, tanya dulu, jangan asumsi.

Setelah selesai, beri saya instruksi cara aktifkan script ini di Content Manager (Settings > Custom Shaders Patch > Gamepad FX) dan cara verifikasi baseline passthrough jalan.

# Prompt 2 — Signal Processing (Fase 1)

Fase 0 sudah saya verifikasi (axis mapping benar, baseline passthrough jalan). Lanjut ke Fase 1 di PLAN-B.md — HANYA Fase 1, jangan lompat ke vibration atau UI dulu.

Port smoothing (EMA dt-normalized) dan hysteresis deadzone remap PERSIS sesuai formula di §2.1 — jangan ubah/tambah pendekatan lain. Mulai dari Right Trigger saja dulu, toggle enable/disable hardcode di config.lua (belum perlu UI).

Setelah RT saya konfirmasi stutter 0-20% hilang, baru tambahkan Left Trigger dengan cara yang sama. JANGAN proses Left Stick X/Y kecuali saya minta — itu opsional di plan dan belum tentu perlu untuk controller saya.

Jangan tambah fitur lain di luar smoothing+hysteresis ini.

Setelah selesai, beri saya instruksi test: cara toggle smoothing/hysteresis on/off buat A/B testing, dan apa yang perlu saya rasakan bedanya saat trailbraking di trek.

# Prompt 3 — Vibration (Fase 2)

Fase 1 sudah saya test dan berhasil (RT & LT sudah smooth). Lanjut ke Fase 2 di PLAN-B.md — HANYA vibration, ikuti PERSIS formula & spesifikasi di §2.1 bagian Vibration dan §4 Fase 2 (mode Proportional/Static, pilihan motor per axis, resolusi konflik MAX(), pakai ac.setControllerRumble bukan setTriggerRumble).

PERHATIAN KHUSUS: ac.setControllerRumble butuh parameter duration, beda dari XInputSetState yang "set dan tahan". Uji dulu apakah perlu dipanggil tiap frame dengan duration sedikit lebih panjang dari dt supaya efeknya kontinu tanpa gap — laporkan hasil uji cobanya ke saya, jangan asumsi satu pendekatan langsung benar.

Config masih hardcode di config.lua, belum perlu UI.

Jangan tambah fitur di luar spesifikasi vibration yang sudah ada di plan.

Setelah selesai, beri saya instruksi test: cara verifikasi getaran proporsional vs static, dan cara test skenario dua axis share motor yang sama.

# Prompt 4 — UI Tuning Panel (Fase 3)

Fase 1 & 2 sudah saya test dan berhasil, semua parameter masih hardcode di config.lua. Lanjut ke Fase 3 di PLAN-B.md — bangun in-game UI app sesuai §3 (apps/lua/hall_config_ui/).

Riset dulu CSP Lua UI API yang tersedia (ui.slider, ui.checkbox, dst — link SDK ada di §4 referensi) sebelum coding, laporkan API apa saja yang mau dipakai.

UI cukup expose parameter yang SUDAH ADA (toggle smoothing/hysteresis/vibration per axis, slider alpha/threshold/max vibration, pilihan motor) — JANGAN tambah parameter atau fitur baru yang belum ada di plan. Simpan config ke file supaya tidak hilang tiap restart game.

Setelah selesai, beri saya instruksi cara buka panel UI ini in-game dan cara test semua kontrolnya kepakai live tanpa restart.