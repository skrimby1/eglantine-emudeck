<p align="center">
  <a href="https://controlmole.app/"><img src="assets/controlmole_icon.png" width="120" alt="ControlMole app icon"></a>
</p>
<h2 align="center">ControlMole</h2>
<p align="center">
  <b>Your phone's new bodyguard.</b> Set a daily limit for TikTok, Instagram, YouTube and other apps, and when you go over, Mole closes them for the rest of the day. It's my own app against doomscrolling, and trying it is the best way to support these videos.
</p>
<p align="center">
  <a href="https://controlmole.app/play"><img src="assets/google-play.png" height="48" alt="Get it on Google Play"></a>
  &nbsp;
  <a href="https://controlmole.app/appstore"><img src="assets/app-store.svg" height="48" alt="Download on the App Store"></a>
</p>

---

# Switch 2 games in EmuDeck on a Steam Deck

EmuDeck has no Switch 2 option yet, so this adds one by hand: your games show up in your Steam library with artwork, and in EmulationStation as a Nintendo Switch 2 system. It's very early, so expect around 20 frames per second and bugs. You need your own Switch 2 and your own games, and nothing here helps you get games any other way.

## Install

In Desktop Mode, open Konsole (application menu → System) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/skrimby1/eglantine-emudeck/main/install.sh | bash
```

Read [install.sh](install.sh) first if you like, it's short. Run it again after you reset EmulationStation or Steam ROM Manager in EmuDeck, because a reset puts EmuDeck's own files back, and to update the emulator. It doesn't touch your games or saves.

## What it does

- Downloads the newest [Eglantine for Steam Deck](https://github.com/MFS-code/Eglantine-steamdeck/releases) by Miguel Serna, with its launcher and settings, and [PokeDinner 2.0.0](https://git.eden-emu.dev/Franseven/PokeDinner-a-Eglantine-Fork/releases/tag/2.0.0) by Franseven for Pokopia, into `~/Applications/eglantine`
- Writes `eglantine-emudeck.sh` there, which sends Pokopia to PokeDinner, adds `--frames-ahead` for Mario Kart and starts everything else with the fork's own launcher
- Gives PokeDinner settings of its own (Handheld, 12GB memory layout, no "outdated format" message), so it doesn't share them with EmuDeck's regular Eden
- Makes `Emulation/roms/switch2`
- Adds a `switch2` system to `~/ES-DE/custom_systems/es_systems.xml` and a parser to Steam ROM Manager's `userConfigurations.json`, keeping a `.before-eglantine` copy of each

## Add your games

1. Copy each game into `Emulation/roms/switch2` as a folder named after the game with `.ns2` on the end, with `exefs` and `romfs` right inside it: `Mario Kart World.ns2/exefs/main`. If your dump came as `base` and `updates`, it's the folder inside `updates` that holds both.
2. Open EmuDeck → Steam ROM Manager → Add Games → Parse → Save to Steam.
3. Back in Gaming Mode, play from your library or from EmulationStation.

## When something goes wrong

Each start writes what it printed to `~/Applications/eglantine/last-run.log`.

| What happens | What it is |
|---|---|
| You open the AppImage and nothing happens | The Deck version has no menus and quits with "No ROM specified". Start it through a game |
| Stuck on loading | Check that `exefs/main` sits right inside the game's folder, and read `last-run.log`. The first start really is a black screen for a while |
| The whole Deck freezes | It ran out of graphics memory. Hold the power button, close everything else before you play, and make a 16 GB swap file with [CryoUtilities](https://github.com/CryoByte33/steam-deck-utilities) |
| Half the frames | SMT is off, turn it back on in PowerTools or your Decky plugin |
| Donkey Kong Bananza freezes at a terrain break | A folder name containing "Mario Kart" or "mkw" turns on `--frames-ahead`, which freezes this game |
| It's gone after resetting EmuDeck | Run the installer again |

To remove it: delete `~/Applications/eglantine`, the `switch2` block in `es_systems.xml`, and the parser in Steam ROM Manager. Eglantine and PokeDinner keep saves in `~/.local/share/eden`, the same place as EmuDeck's regular Eden.
