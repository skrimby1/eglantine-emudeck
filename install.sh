#!/usr/bin/env bash
# Puts Switch 2 games into EmuDeck on a Steam Deck: the Steam Deck version of Eglantine, PokeDinner
# for Pokopia, a roms/switch2 folder, a "Nintendo Switch 2" system in EmulationStation (ES-DE) and
# a parser in Steam ROM Manager.
#
# EmuDeck has no Switch 2 option of its own yet, and resetting ES-DE or Steam ROM Manager in EmuDeck
# puts its own files back. Run this again after a reset, and to update the emulator: it's safe to
# run as often as you like, and it never touches your games or saves.
set -euo pipefail

fork_repo="MFS-code/Eglantine-steamdeck"
pokedinner_url="https://git.eden-emu.dev/Franseven/PokeDinner-a-Eglantine-Fork/releases/download/2.0.0/Eglantine-PokeDinner-2.0.0-linux-x86_64.AppImage"
parser_id="176250000000000002"

app="$HOME/Applications/eglantine"
emudeck_settings="$HOME/.config/EmuDeck/settings.sh"
es_systems="$HOME/ES-DE/custom_systems/es_systems.xml"
srm_parsers="$HOME/.config/steam-rom-manager/userData/userConfigurations.json"

say() { printf '\n== %s\n' "$*"; }
die() { printf '\nStopped: %s\n' "$*" >&2; exit 1; }

[ -f "$emudeck_settings" ] || die "EmuDeck isn't set up on this Deck yet, so run it once first."
command -v python3 >/dev/null || die "python3 is missing, and SteamOS comes with it, so this doesn't look like a Steam Deck."
[ -f "$srm_parsers" ] || die "Steam ROM Manager has no settings yet. Run EmuDeck once first."
if pgrep -i "steam-rom-manag" >/dev/null; then
    die "Steam ROM Manager is open. Close it, then run this again."
fi

set +u
# shellcheck disable=SC1090
. "$emudeck_settings"
set -u
roms="${romsPath:-$HOME/Emulation/roms}"

# ---- the emulators
say "Downloading the Steam Deck version of Eglantine"
mkdir -p "$app"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://api.github.com/repos/$fork_repo/releases/latest" -o "$tmp/release.json"
asset_url() { python3 -c 'import json,sys; print(next((u for u in (a["browser_download_url"] for a in json.load(open(sys.argv[1]))["assets"]) if u.endswith(sys.argv[2])), ""))' "$tmp/release.json" "$1"; }
appimage_url="$(asset_url .AppImage)"
kit_url="$(asset_url -kit.tar.gz)"
[ -n "$appimage_url" ] && [ -n "$kit_url" ] || die "the newest release has no AppImage or no kit, check https://github.com/$fork_repo/releases"
curl -fL --progress-bar "$appimage_url" -o "$tmp/$(basename "$appimage_url")"
curl -fsSL "$kit_url" -o "$tmp/kit.tar.gz"
rm -f "$app"/eglantine-steamdeck-*.AppImage
mv "$tmp"/eglantine-steamdeck-*.AppImage "$app/"
tar -xzf "$tmp/kit.tar.gz" -C "$app"

if ! ls "$app"/Eglantine-PokeDinner-*.AppImage >/dev/null 2>&1; then
    say "Downloading PokeDinner 2.0.0 for Pokopia"
    curl -fL --progress-bar "$pokedinner_url" -o "$tmp/$(basename "$pokedinner_url")"
    mv "$tmp"/Eglantine-PokeDinner-*.AppImage "$app/"
fi

# Pokopia hangs on "Launching" for many on the defaults, Docked and a 4GB memory layout, and the
# first start stops on an "Outdated Game Format" message that's easy to miss in Gaming Mode.
mkdir -p "$app/pokedinner-config/eden"
if [ ! -f "$app/pokedinner-config/eden/qt-config.ini" ]; then
    cat > "$app/pokedinner-config/eden/qt-config.ini" <<'POKEDINNER'
[UI]
calloutFlags\default=false
calloutFlags=2

[Core]
memory_layout_mode\default=false
memory_layout_mode=4

[System]
use_docked_mode\default=false
use_docked_mode=0
POKEDINNER
fi

# ---- the launcher Steam and EmulationStation both start. It lives here and not in EmuDeck's
# tools/launchers, because EmuDeck's "Emulators" parser would add it to Steam as an emulator, and
# neither of these starts without a game.
cat > "$app/eglantine-emudeck.sh" <<'LAUNCHER'
#!/usr/bin/env bash
# Starts a Switch 2 game. Takes the game's folder or its exefs/main, and picks the emulator and the
# switches by the folder's name. Whatever it prints also lands in last-run.log, next to this file.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee -p >(head -c 2000000 > "$here/last-run.log")) 2>&1 # -p, so the game outlives a full log
ulimit -c 0 # a crash here would otherwise leave a core dump of many gigabytes on the Deck's disk

game="${1:-}"
[ -n "$game" ] || { echo "Which game? This starts a game, it has no menu of its own."; exit 1; }
shift
case "$game" in
*/exefs/main) main="$game" ;;
*) main="$game/exefs/main" ;;
esac
[ -f "$main" ] || { echo "There's no exefs/main in $game, so it isn't a loose dump."; exit 1; }
title="$(basename "$(dirname "$(dirname "$main")")")"

case "${title,,}" in
*pokopia*)
    # A loose dump opens thousands of files at once, and the default limit of 1024 ends the game.
    ulimit -n "$(ulimit -Hn)" 2>/dev/null
    pokedinner="$(ls -t "$here"/Eglantine-PokeDinner-*.AppImage 2>/dev/null | head -1)"
    [ -n "$pokedinner" ] || { echo "PokeDinner is missing, run the installer again."; exit 1; }
    chmod +x "$pokedinner"
    # Its own settings (Handheld, 12GB memory layout), so they don't change EmuDeck's regular Eden,
    # which keeps its settings in the same place, and Eden's don't stop this from booting.
    export XDG_CONFIG_HOME="$here/pokedinner-config"
    "$pokedinner" -f -g "$main" "$@"
    exit $?
    ;;
*mario*kart*|*mkw*)
    set -- --frames-ahead "$@" # 18 to 25 fps in a race; it freezes Donkey Kong Bananza, so only here
    ;;
esac
"$here/eglantine-deck.sh" "$main" "$@"
LAUNCHER
chmod +x "$app"/*.AppImage "$app/eglantine-deck.sh" "$app/eglantine-emudeck.sh"

# ---- the games folder
say "Making the games folder"
mkdir -p "$roms/switch2"
cat > "$roms/switch2/systeminfo.txt" <<'INFO'
Nintendo Switch 2, through Eglantine for Steam Deck (and PokeDinner for Pokopia).

One folder per game, named after the game with .ns2 on the end, holding exefs and romfs. If your
dump came as base and updates, it's the folder inside updates that holds both:

  Mario Kart World.ns2/exefs/main
  Mario Kart World.ns2/romfs/...
INFO

# ---- EmulationStation
say "Adding Nintendo Switch 2 to EmulationStation"
mkdir -p "$(dirname "$es_systems")"
[ -f "$es_systems" ] || printf '<?xml version="1.0"?>\n<systemList>\n</systemList>\n' > "$es_systems"
if ! grep -q '<name>switch2</name>' "$es_systems"; then
    cp "$es_systems" "$es_systems.before-eglantine"
    cat > "$tmp/system.xml" <<SYSTEM
  <system>
	<name>switch2</name>
	<fullname>Nintendo Switch 2</fullname>
	<path>%ROMPATH%/switch2</path>
	<extension>.ns2 .NS2</extension>
	<command label="Eglantine (Steam Deck)">/bin/bash $app/eglantine-emudeck.sh %ROM%</command>
	<platform>switch</platform>
	<theme>switch2</theme>
  </system>
SYSTEM
    awk -v block="$tmp/system.xml" '/<\/systemList>/ { while ((getline line < block) > 0) print line } { print }' "$es_systems" > "$tmp/es_systems.xml"
    cat "$tmp/es_systems.xml" > "$es_systems"
fi

# ---- Steam ROM Manager
say "Adding the parser to Steam ROM Manager"
cp "$srm_parsers" "$srm_parsers.before-eglantine"
python3 - "$srm_parsers" "$tmp/parsers.json" "$parser_id" "$app/eglantine-emudeck.sh" <<'PARSER'
import json, sys
source, out, parser_id, launcher = sys.argv[1:]
parsers = [p for p in json.load(open(source)) if p.get("parserId") != parser_id]
parsers.append({
    "parserType": "Glob",
    "configTitle": "Nintendo Switch 2 - Eglantine",
    "steamDirectory": "${steamdirglobal}",
    "romDirectory": "${romsdirglobal}/switch2",
    "executableArgs": '%command% "${filePath}"',
    "executableModifier": '"${exePath}"',
    "startInDirectory": "",
    "titleModifier": "${fuzzyTitle}",
    "imageProviders": ["sgdb", "steamCDN"],
    "imagePool": "${fuzzyTitle}",
    "userAccounts": {"specifiedAccounts": ["Global"]},
    "disabled": False,
    "executable": {"path": launcher, "shortcutPassthrough": False, "appendArgsToExecutable": False},
    "parserInputs": {"glob": "${title}.ns2/exefs/main"},
    "titleFromVariable": {"caseInsensitiveVariables": False, "skipFileIfVariableWasNotFound": False, "limitToGroups": []},
    "fuzzyMatch": {"replaceDiacritics": True, "removeCharacters": True, "removeBrackets": True},
    "controllers": {k: None for k in ("ps4", "ps5", "xbox360", "xboxone", "switch_joycon_left", "switch_joycon_right", "switch_pro", "neptune")},
    "imageProviderAPIs": {"sgdb": {"nsfw": False, "humor": False, "styles": [], "stylesHero": [], "stylesLogo": [], "stylesIcon": [], "imageMotionTypes": ["static"]}},
    "defaultImage": {"tall": "", "long": "", "hero": "", "logo": "", "icon": ""},
    "localImages": {"tall": "", "long": "", "hero": "", "logo": "", "icon": ""},
    "parserId": parser_id,
    "version": 25,
    "steamInputEnabled": "1",
    "drmProtect": False,
    "steamCategories": ["Nintendo Switch 2"],
    "onlineImageQueries": ["${fuzzyTitle}"],
})
parsers.sort(key=lambda p: p.get("configTitle", ""))
json.dump(parsers, open(out, "w"), indent=2)
PARSER
[ -s "$tmp/parsers.json" ] || die "couldn't write the parser, Steam ROM Manager's settings are unchanged."
cat "$tmp/parsers.json" > "$srm_parsers"

# ---- what the emulator's author says decides the most, so check it here
say "Checking this Deck"
if [ "$(cat /sys/devices/system/cpu/smt/control 2>/dev/null)" = "off" ]; then
    echo "WARNING: SMT is off, which halves your frame rate. Turn it back on in the tool that turned it off (PowerTools, a Decky plugin)."
else
    echo "SMT is on, good."
fi
swap_mb="$(free -m | awk '/^Swap:/ { print $2 }')"
if [ "${swap_mb:-0}" -lt 8000 ]; then
    echo "WARNING: you have ${swap_mb:-0} MB of swap, and these games can freeze the whole Deck without more. CryoUtilities' Recommended settings make a 16 GB swap file: https://github.com/CryoByte33/steam-deck-utilities"
else
    echo "Swap is ${swap_mb} MB, good."
fi

cat <<DONE

All done! Now:
  1. Copy each game into $roms/switch2/ as a folder named like "Mario Kart World.ns2", with exefs and romfs right inside it
  2. Open Steam ROM Manager from EmuDeck, parse, and save to Steam
  3. Go back to Gaming Mode and play from your library or from EmulationStation
DONE
