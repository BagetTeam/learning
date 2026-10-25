# Dino Run

A small C++17 Windows dinosaur runner inspired by Chrome's offline game.
Pixel graphics are drawn with the Windows API; no assets or third-party libraries are needed.

## Build and run

Install Visual Studio 2022 with **Desktop development with C++** and CMake.
From this folder, run:

```powershell
cmake -S . -B build
cmake --build build --config Release
.\build\Release\dino.exe
```

You can also open the folder in Visual Studio and run the `dino` target.

## Controls

- **Space / Up / click:** start, jump, or restart after a collision.
- **Release Space / Up early:** make a shorter jump.
- **Down:** duck on the ground or fall faster in the air.
- **P:** pause or resume. Losing window focus also pauses the game.
- **R:** start a fresh run.
- **Escape:** quit.

Avoid cacti and flying obstacles. The pace increases as you travel.
Your best score is stored in `%LOCALAPPDATA%\DinoRunner\highscore.txt`.

This implementation targets Windows and uses GDI double buffering and a fixed-step physics loop.
