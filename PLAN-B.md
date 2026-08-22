# hall_config — HallConfig for Assetto Corsa (CSP Gamepad FX Edition)

Proyek BARU (repo terpisah), menggantikan HallConfig versi Windows app khusus untuk Assetto Corsa. Berjalan langsung di dalam `acs.exe` lewat CSP Gamepad FX (Lua), bukan lagi lewat vJoy/ViGEm/HidHide di level OS.

## 1. Kenapa Arsitektur Ini Lebih Simpel

Versi lama (Windows app) harus bikin device virtual (vJoy/ViGEm) buat "nipu" game, makanya butuh 3 driver terpisah (vJoy, ViGEmBus, HidHide) dan rawan salah bind device. hall_config baca sinyal fisik LANGSUNG dari dalam game, olah, terus tulis LANGSUNG ke physics engine (`ac.setGas()`/`ac.setBrake()`) — jadi:

- **Tidak butuh vJoy, ViGEm, atau HidHide sama sekali.**
- **Tidak ada lagi masalah "Gamepad ID salah device"** — cuma ada SATU device (fisik) dari awal sampai akhir, tidak ada device virtual yang bisa ketuker.
- **Passthrough tombol/D-pad/Right Stick otomatis** — karena kita cuma intercept `setGas`/`setBrake`/`setSteer`/`setClutch`/`setGearRequest`, semua input lain (tombol, dsb) tetap dibaca normal oleh sistem binding AC yang sudah ada. Tidak perlu kode passthrough eksplisit seperti di versi lama.
- **Distribusi jauh lebih simpel** — tinggal copy folder ke `assettocorsa/extension/lua/joypad-assist/`, tidak perlu installer/driver apapun.

## 2. Referensi API CSP Gamepad FX (dari dokumentasi resmi)

```lua
-- Entry point, dipanggil tiap physics frame
function script.update(dt)  -- dt = delta time (detik)
function script.reset()     -- dipanggil saat reset session/ganti mobil — WAJIB clear semua state di sini

-- Baca input mentah
local gamepad = ac.getGamepad(0)
gamepad.axes[1]   -- left stick X (steering)   [-1, 1]
gamepad.axes[2]   -- left stick Y              [-1, 1]
gamepad.axes[3]   -- right trigger (throttle)  [0, 1]
gamepad.axes[4]   -- left trigger (brake)      [0, 1]
-- CATATAN PENTING: index axis bisa beda tiap controller — WAJIB validasi pakai ac.log() dulu,
-- jangan asumsi mapping di atas otomatis benar untuk Gamesir Nova Lite.

-- Tulis hasil olahan ke physics
ac.setGas(value)          -- [0, 1]
ac.setBrake(value)        -- [0, 1]
ac.setSteer(value)        -- [-1, 1]  (tidak dipakai di hall_config, steering tidak diproses)
ac.setClutch(value)       -- [0, 1]   (tidak dipakai)
ac.setGearRequest(delta)  -- (tidak dipakai)

-- Vibration — Gamesir Nova Lite pakai motor STANDAR (2 motor), pakai fungsi ini:
ac.setControllerRumble(leftMotor, rightMotor, duration)  -- motors [0,1], duration dalam detik
-- ac.setTriggerRumble() TIDAK relevan — itu untuk "impulse trigger" motor terpisah
-- yang cuma ada di controller Xbox Series, Gamesir Nova Lite tidak punya ini.

-- Telemetry fisik (untuk kemungkinan pengembangan lanjut, di luar scope v1 hall_config)
local car = ac.getCar(0)  -- bisa nil di frame pertama, WAJIB nil-guard

-- Utilities
ac.log("pesan")
```

**Pitfall penting dari dokumentasi resmi (berlaku juga buat kita):**
- Smoothing/lerp HARUS di-normalize ke `dt`, supaya behavior sama di frame rate berapa pun (60fps vs 165fps) — beda dari versi lama yang loop-nya fixed 250Hz.
- `ac.getCar(0)` bisa `nil` di frame-frame awal — selalu nil-guard.
- `script.reset()` WAJIB clear semua state (misal nilai smoothing yang ke-carry), kalau tidak bakal ada "jerk" di awal session baru.

## 2.1 Formula Konkret (WAJIB dibaca sebelum coding — repo ini berdiri sendiri, tidak ada akses ke repo HallConfig lama)

### Smoothing (EMA) — port dari versi C#, PERLU di-retune untuk dt variable
Versi lama pakai `alpha = 0.4` yang di-tuning untuk loop TETAP 250Hz (dt = 0.004s tiap tick). CSP Gamepad FX jalan di physics tick rate game yang variable, jadi alpha lama TIDAK otomatis valid — pakai formula dt-normalized:

```lua
-- time constant setara alpha=0.4 @ 250Hz sebagai titik awal, BUKAN patokan mati:
local function smoothDt(raw, prevSmoothed, timeConstant, dt)
    local factor = 1 - math.exp(-dt / timeConstant)
    return prevSmoothed + (raw - prevSmoothed) * factor
end
-- timeConstant awal untuk dicoba: sekitar 0.01-0.02 detik, lalu RE-TUNE manual
-- sambil lihat feel in-game — jangan asumsikan angka ini langsung pas.
```

### Hysteresis Deadzone Remap — port LANGSUNG, tidak perlu retuning (tidak dt-dependent)
```lua
-- default: thresholdUp = 0.27, thresholdDown = 0.23 (sama seperti versi lama)
local active = false
local function hysteresis(raw, thresholdUp, thresholdDown)
    if not active and raw > thresholdUp then active = true
    elseif active and raw < thresholdDown then active = false end
    if not active then return 0.0 end
    return (raw - thresholdDown) / (1.0 - thresholdDown)
end
```

### Vibration — port dari PLAN2.md (repo lama), inline di sini karena tidak tersedia di repo baru
```lua
-- Proportional (default):
motorValue = processedOutput * (maxVibrationPercent / 100)
-- Static:
motorValue = (processedOutput > 0) and (maxVibrationPercent / 100) or 0
-- Kalau RT & LT dipilih ke motor yang SAMA: motorValue = math.max(nilai_axis_1, nilai_axis_2)
-- Default mapping: LT -> Left Motor (low freq), RT -> Right Motor (high freq) — user-selectable
```

## 2.2 Workflow Development — Investigasi Dulu di Fase 0

**Path instalasi Assetto Corsa (target testing):** `D:\SteamLibrary\steamapps\common\assettocorsa`
Folder tujuan untuk deploy script saat development: `D:\SteamLibrary\steamapps\common\assettocorsa\extension\lua\joypad-assist\hall_config\`

**PENTING, cek di awal sebelum development jalan lama-lama:** apakah CSP hot-reload script Lua setelah file di-edit (misal cukup Alt-Tab keluar-masuk game, atau ada tombol "reload script" di CSP debug menu), ATAU harus restart total `acs.exe` tiap kali ada perubahan kode? Ini nentuin kecepatan iterasi development — kalau harus restart total tiap edit kecil, pertimbangkan bikin cara test logic (misal fungsi smoothing/hysteresis) di luar game dulu (standalone Lua interpreter/unit test sederhana) sebelum uji coba in-game, supaya tidak buang waktu restart berulang-ulang untuk hal yang bisa divalidasi tanpa game.

## 2.3 Sebelum Mulai Coding — WAJIB baca §2.1 dan §2.2 dulu

Kalau ada bagian yang ambigu atau butuh keputusan (misal: apakah investigasi hot-reload di §2.2 hasilnya bikin perlu ubah pendekatan testing), tanyakan dulu sebelum lanjut coding — jangan asumsi.

## 3. Struktur Proyek

CSP butuh DUA komponen terpisah:
1. **Gamepad FX script** (proses per-frame, tidak ada UI) — wajib.
2. **In-game UI app** (panel tuning interaktif di sidebar, opsional tapi disarankan untuk paritas fitur sama versi lama) — dikerjakan belakangan (Fase 3).

```
hall_config/
├── extension/
│   └── lua/
│       └── joypad-assist/
│           └── hall_config/
│               ├── manifest.ini
│               ├── assist.lua        <- entry point, script.update(dt)
│               ├── signal.lua        <- port SignalProcessor (smoothing+hysteresis)
│               └── config.lua        <- default config + load/save
├── apps/
│   └── lua/
│       └── hall_config_ui/                <- Fase 3, panel tuning in-game
│               ├── manifest.ini
│               └── app.lua
└── README.md
```

## 4. Fase Pengembangan

### Fase 0 — Setup & Validasi Dasar
- [ ] Buat struktur folder + `manifest.ini` (name, version).
- [ ] `assist.lua` skeleton minimal: `script.update(dt)` yang cuma `ac.log()` tiap beberapa detik buat konfirmasi script ke-load & jalan.
- [ ] Validasi mapping axis SPESIFIK untuk Gamesir Nova Lite — log semua `gamepad.axes[1..8]` sambil gerakin RT/LT/Left Stick satu-satu, konfirmasi index mana yang mana (JANGAN asumsi `axes[3]`/`axes[4]` otomatis benar).
- [ ] Set Content Manager Controls: Input Method = Gamepad, arahkan ke device fisik (sekarang tidak ada ambiguitas lagi karena cuma ada satu device).
- [ ] Passthrough MURNI dulu tanpa processing sama sekali: `ac.setGas(gamepad.axes[3])`, `ac.setBrake(gamepad.axes[4])` — pastikan baseline end-to-end jalan sebelum nambah logic apapun.

**Acceptance:** trigger fisik menggerakkan throttle/brake in-game (masih stuttery di 0-20%, itu wajar, belum diproses).

### Fase 1 — Port Signal Processing (Smoothing + Hysteresis)
- [ ] Port logic `SignalProcessor` dari versi C# (`signal.lua`): EMA smoothing + hysteresis deadzone remap, TAPI di-normalize ke `dt` (bukan alpha tetap seperti versi 250Hz dulu — pakai rumus dt-normalized exponential decay, lihat contoh di dokumentasi: `1 - (1 - base)^dt`).
- [ ] Toggle enable/disable smoothing & hysteresis per axis (hardcode dulu di `config.lua`, belum perlu UI).
- [ ] Mulai dari RT saja, verifikasi stutter 0-20% hilang persis seperti pengujian awal proyek lama.
- [ ] Setelah RT beres, tambahkan LT, lalu Left Stick X/Y (opsional — cek apakah stutter juga muncul di stick Gamesir Nova Lite kamu; kalau tidak pernah jadi masalah, boleh skip stick di v1).

**Acceptance:** trailbraking mulus di RT, tanpa blip di 0-20%, dites langsung di trek — sama seperti kriteria sukses proyek lama.

### Fase 2 — Vibration Feedback
- [ ] Port fitur vibration dari PLAN2.md: toggle enable per axis, pilihan motor (Left/Right), mode Proportional/Static, Max Vibration cap, resolusi konflik MAX() kalau dua axis pakai motor sama.
- [ ] Pakai `ac.setControllerRumble(leftMotor, rightMotor, duration)`.
- [ ] **PERHATIAN — perlu diuji khusus:** fungsi ini punya parameter `duration`, beda dari `XInputSetState` versi lama yang sifatnya "set dan tahan sampai diubah". Kemungkinan perlu dipanggil TIAP FRAME dengan `duration` sedikit lebih panjang dari `dt` supaya efeknya kontinu tanpa jeda/retrigger yang keliatan. Uji dan verifikasi behavior sebenarnya sebelum finalisasi — ini beda karakteristik API yang belum pernah kita alami di versi lama.

**Acceptance:** vibration RT/LT proporsional (atau static, sesuai mode), berhenti pas output kembali 0, tidak ada glitch/gap dari cara pemanggilan `duration`.

### Fase 3 — In-Game UI (Tuning Panel)
- [ ] Bangun `apps/lua/hall_config_ui/` — panel sidebar in-game (CSP Lua UI API — `ui.slider`, `ui.checkbox`, dst, riset dulu di CSP Lua SDK: https://github.com/ac-custom-shaders-patch/acc-lua-sdk).
- [ ] Toggle smoothing/hysteresis/vibration per axis, slider parameter (alpha, threshold up/down, max vibration), live preview raw vs processed (kalau CSP UI API support grafik; kalau tidak, angka real-time cukup).
- [ ] Komunikasi antara UI app dan Gamepad FX script lewat shared state/config file — riset API persistence CSP yang tepat (kemungkinan ada `ac.storage()` atau sejenis, cek CSP Lua SDK docs).
- [ ] Save/load config ke file, supaya setting tidak hilang tiap restart game.

**Acceptance:** semua parameter bisa diubah live dari dalam game tanpa edit file manual, tersimpan otomatis.

### Fase 4 — Sunset Versi Lama (Windows App)
- [ ] Update README repo HallConfig lama: tandai sebagai "no longer recommended for Assetto Corsa — see hall_config", tapi tetap functional untuk game lain (jangan dihapus, cuma di-deprioritaskan).
- [ ] Update Steam Guide, forum post OverTake.gg, dan link mana pun yang nunjuk ke HallConfig lama supaya arahin ke hall_config untuk use-case Assetto Corsa.
- [ ] Publish hall_config sebagai release pertamanya (repo GitHub baru, README lengkap, instruksi instalasi simpel — cukup "extract ke folder assettocorsa", tanpa driver).

## 5. Di Luar Scope (v1)

- Steering assist / self-steer correction (itu domain mod lain seperti Advanced Gamepad Assist, bukan tujuan HallConfig).
- Telemetry-driven vibration (ABS/wheel slip) — worth dipertimbangkan v2 setelah v1 hall_config stabil, karena `ac.getCar(0)` sudah expose semua data itu, tinggal nyambungin.
- Cross-game support — hall_config eksklusif Assetto Corsa + CSP. Windows app lama tetap jadi opsi untuk game lain.