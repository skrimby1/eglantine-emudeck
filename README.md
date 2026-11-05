<p align="center">
  <a href="https://controlmole.app/"><img src="assets/controlmole_icon.png" width="120" alt="ControlMole app icon"></a>
</p>
<h2 align="center">ControlMole</h2>
<p align="center">
  PROMOTION: Set a daily limit for TikTok, Instagram, YouTube and other apps, and when you go over, Mole closes them for the rest of the day. It's my own app against doomscrolling, and trying it is the best way to support these videos.
</p>
<p align="center">
  <a href="https://controlmole.app/play"><img src="assets/google-play-badge.png" height="40" alt="Get it on Google Play"></a>
  &nbsp;
  <a href="https://controlmole.app/appstore"><img src="assets/app-store.svg" height="40" alt="Download on the App Store"></a>
</p>

---

# Switch 2 games in EmuDeck on a Steam Deck or Steam Machine

EmuDeck has no Switch 2 option yet, so this adds one by hand: your games show up in your Steam library with artwork, and in EmulationStation as a Nintendo Switch 2 system. It's very early, so expect around 20 frames per second and bugs. You need your own Switch 2 and your own games, and nothing here helps you get games any other way.

## Install

In Desktop Mode, open Konsole (application menu → System) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/skrimby1/eglantine-emudeck/main/install.sh | bash
```

Read [install.sh](install.sh) first if you like, it's short. Run it again after you reset EmulationStation or Steam ROM Manager in EmuDeck, because a reset puts EmuDeck's own files back, and to update the emulator. It doesn't touch your games or saves.

## What it does

- Downloads the right Eglantine for your machine: on a Deck, the newest [Eglantine for Steam Deck](https://github.com/MFS-code/Eglantine-steamdeck/releases) by Miguel Serna with its launcher and settings, and on a Steam Machine or anything else with its own graphics memory, the newest numbered [Eglantine](https://github.com/Djihads80/Eglantine/releases). It also gets [PokeDinner 2.0.0](https://git.eden-emu.dev/Franseven/PokeDinner-a-Eglantine-Fork/releases/tag/2.0.0) by Franseven for Pokopia, into `~/Applications/eglantine`
- Writes `eglantine-emudeck.sh` there, which sends Pokopia to PokeDinner, helps Mario Kart along (`--frames-ahead` on a Deck, `EDEN_NX2_NO_MESH=1` on a Steam Machine, against a graphics driver crash) and starts everything else with the right Eglantine
- Gives the emulators settings of their own (a 12GB memory layout, no "outdated format" message, and Handheld for PokeDinner on a Deck), so they don't share them with EmuDeck's regular Eden
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
| On a Steam Machine, the screen goes black in Mario Kart World | AMD's graphics driver crashed. The launcher turns on the known workaround if the folder's name has "Mario Kart" or "mkw" in it, so keep that in the name. Some effects like trail ribbons go missing |
| On a Steam Machine, Pokopia crashes | One owner's PokeDinner crashed there. Delete the PokeDinner AppImage from `~/Applications/eglantine` to try the regular Eglantine, which went black on Pokopia when tested on a PC |
| EmulationStation opens and closes right away | In Desktop Mode, right-click ES-DE in Steam, open Properties and check that Target points at the real file |
| Stuck on loading | Check that `exefs/main` sits right inside the game's folder, and read `last-run.log`. The first start really is a black screen for a while |
| The whole Deck freezes | It ran out of graphics memory. Hold the power button, close everything else before you play, and make a 16 GB swap file with [CryoUtilities](https://github.com/CryoByte33/steam-deck-utilities) |
| Half the frames (Deck) | SMT is off, turn it back on in PowerTools or your Decky plugin |
| Donkey Kong Bananza freezes at a terrain break (Deck) | A folder name containing "Mario Kart" or "mkw" turns on `--frames-ahead`, which freezes this game |
| It's gone after resetting EmuDeck | Run the installer again |

To remove it: delete `~/Applications/eglantine`, the `switch2` block in `es_systems.xml`, and the parser in Steam ROM Manager. Eglantine and PokeDinner keep saves in `~/.local/share/eden`, the same place as EmuDeck's regular Eden.
