# ChillyScript Modular

Struktur ini memecah `ChillyScript.txt` menjadi beberapa file kecil berdasarkan kategori fitur.

## Folder

- `src/00_bootstrap.lua` - setup services, Rayfield window, dan tab.
- `src/01_state.lua` - state bersama dan konfigurasi runtime.
- `src/02_common.lua` - helper umum.
- `src/03_movement.lua` - movement, fly, noclip, teleport, dan koordinat.
- `src/04_combat_targeting.lua` - targeting, visibility, prediction, dan hitbox.
- `src/05_visual_esp.lua` - ESP dan visual renderer.
- `src/06_runtime_loop.lua` - loop runtime dan input handling.
- `src/07_autoclick.lua` - auto click dan tap detector.
- `src/08_weapon_tools.lua` - weapon assist dan ballistics.
- `src/09_extra_tools.lua` - low graphics, desync, reset, dan analyzer.
- `src/10_ui_movement.lua` sampai `src/14_ui_extra.lua` - UI per tab.
- `src/99_startup.lua` - startup apply dan notifikasi.

## Build

Jalankan:

```powershell
.\tools\build.ps1
```

Hasilnya ada di:

```text
dist\ChillyScript.lua
```

Catatan: file di `src` sengaja tetap digabung menjadi satu output final supaya `local` dan urutan eksekusi dari script asli tetap aman.
