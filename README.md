# NeoDex Toolkit

Warcraft III model toolkit for Autodesk 3ds Max — import, edit, animate and export
MDX/MDL models for both Classic (v800) and Reforged (v1200).

**Current version:** 4.7.0 · **3ds Max:** 2022–2027 (64-bit) · **License:** MIT

[Download the latest installer](https://github.com/DennisHerrm/NeoDex/releases/latest) ·
[Changelog](CHANGELOG.md) ·
[Hive Workshop thread](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/) ·
[Discord](https://discord.gg/6pt5v6sAEc)

---

## About

NeoDex was originally written by **BlinkBoy (Fernando A. Sahmkow)** as an MDLX toolkit for
gmax and 3ds Max. After years without updates it was carried forward by Jaccouille, Blinkoon
and Bensen (2.8 / 2.9), then largely rewritten from version 3.0 onwards by DennisH and
Benjamin Schiefer. Version 4.0 added full Warcraft III Reforged support.

## Features

### Import and export
- MDX and MDL, Classic **v800** and Reforged **v1200**; the importer detects the version
  automatically, the exporter lets you choose it
- Reforged data: PBR materials (diffuse, normal, ORM, emissive, environment), Fresnel and
  emissive gain, per-vertex skin weights (SKIN), bind poses (BPOS), tangents (TANG),
  LOD layers, Popcorn FX emitters (CORN) and FaceFX (FAFX)
- Shared (alias) sequences of Reforged models survive the round trip
- Cameras, lights, particle emitters 1 and 2, ribbons, collision shapes, attachment points
  and event objects
- Export of Biped rigs, IK- and Link-constrained bones, MassFX-baked animation and
  Editable Poly objects
- Lossless round trip of Hermite tangents and global sequences, multiple UV sets and
  geoset colour animation
- Scene status check in the exporter before writing the file

### Game files
- **MPQ** (Classic): read textures and models from `.mpq`, `.w3mod`, `.w3x`, `.w3m`, `.mix`;
  model browser with live search
- **CASC** (Reforged): browse and import all game models (HD and SD) directly from the
  Warcraft III installation
- Missing textures are looked up in the archives automatically
- Native BLP textures in 3ds Max (`blp.bmi`): viewport, material editor and preview,
  with an automatic fallback decoder

### Scripted plugins
- Warcraft III material with filter modes, team colour, team glow, texture animation
  (including IFL sequences) and a Reforged PBR section
- Blizzard Particle 1 and 2, ribbon emitter, Popcorn emitter, light, attachment point,
  event object (type and code dropdowns), collision shapes, FaceFX, vertex colour modifier

### Tools
- **Sequence Manager** — create, duplicate, filter and nudge sequences; rarity, move speed,
  looping, export ignore list, presets
- **Global Sequence Manager**
- **Animation tools** with *One Click Tools*: attachment points from bone names, portrait
  camera, collision spheres and collision box
- Visibility Keyer, Skin Changer, Team Colour Manager, Node Manager, Object Settings,
  Object Manipulation Tools, Grid and Dummy Creator
- Extra tools: **Keyframe Optimizer** and **Cell Shade Creator**

### Interface
- NeoDex menu and dockable sidebar; every tool panel can be undocked into its own window
- Six languages: English, German, Chinese, Russian, Japanese, Korean
- Built-in update check against the GitHub releases

## Installation

### Installer (recommended)

1. Download `NeoDex_Setup_vX.Y.Z.exe` from the
   [latest release](https://github.com/DennisHerrm/NeoDex/releases/latest).
2. Close 3ds Max and run the installer.
3. Start 3ds Max. The **NeoDex** menu and sidebar appear automatically.

The installer upgrades older NeoDex versions and keeps your `maps` folder and settings.
It installs to `%APPDATA%\Autodesk\ApplicationPlugins\NeoDex` and does not touch the
3ds Max program directory.

### Manual installation from source

Copy the [`NeoDex`](NeoDex) folder from this repository to

```
%APPDATA%\Autodesk\ApplicationPlugins\NeoDex
```

and restart 3ds Max. 3ds Max loads the package via
[`PackageContents.xml`](NeoDex/PackageContents.xml).

### Older 3ds Max versions

NeoDex 3.0 and newer require 3ds Max 2022 or later. For 3ds Max 2016–2021, NeoDex 2.8 is
still available on the
[Hive Workshop page](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/).

## Repository layout

The [`NeoDex`](NeoDex) folder is the Autodesk application plugin bundle, exactly as it is
installed:

| Path | Contents |
|---|---|
| `PackageContents.xml` | Autodesk package manifest: load order and Max version ranges |
| `pre-start-up scripts parts/` | Core: MDX/MDL reader and writer, scene parser and rebuilder, import/export, localisation |
| `scripted plugins parts/` | Scripted plugins: Warcraft III material, emitters, ribbons, lights, attachments, events |
| `post-start-up scripts parts/` | UI tools: managers, animation tools, sidebar, menu, auto-updater |
| `macroscripts parts/` | Macroscripts for menu and toolbar entries |
| `extra tools/` | Keyframe Optimizer, Cell Shade Creator |
| `native plugins/` | `blp.bmi` per Max version, `NeoDexNative.dll` (Max 2022–2025 and 2026+) |
| `neodex_icons/` | Sidebar, menu and about-dialog icons |
| `maps/` | Bundled textures (team glow) |
| `WhiteoutTexCLI.exe` | Texture extraction and conversion helper (see [THIRD_PARTY.md](NeoDex/THIRD_PARTY.md)) |
| `version.txt` | Installed version, read by the About dialog and the updater |

User settings are written at runtime to `NeoDex_Settings.ini` in the install folder and are
not part of the repository.

## Bugs and feedback

Report bugs or suggest features in the
[Hive Workshop thread](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/),
on the [NeoDex Development Discord](https://discord.gg/6pt5v6sAEc) or via
[GitHub issues](https://github.com/DennisHerrm/NeoDex/issues).

Animation questions are also welcome on the
[WC3 Animations Discord](https://discord.gg/v8hYf4nTmb).

## Credits

**Original author**
- BlinkBoy / Fernando A. Sahmkow

**Updaters (2.x)**
- Jaccouille, Blinkoon, Bensen

**Developers (3.0 and newer)**
- DennisH — lead developer
- Benjamin Schiefer — developer

**Plugin development**
- LxXDinjin — material, light, Blizzard Particle 1 and 2, ribbon emitter and collision
  shape plugins

**Contributors**
- Republicola — creator of the original Dexporter
- Igni — Biped support and various fixes
- Bensen — attachment point auto-generation, Sequence Manager safety features

**Testers**
- ghostheroine (also light export and colour fixes), gluma
- Adiktuz, BallisticTerrain, Manoo, skrab, Talavaj

**Libraries**
- [WhiteoutLib](https://github.com/FernandoS27/WhiteoutLib) by Fernando A. Sahmkow — BLP
  support in the native plugin and WhiteoutTex. Further third-party components are listed
  in [THIRD_PARTY.md](NeoDex/THIRD_PARTY.md).

## Support the project

If NeoDex helps you, you can support further development with a
[donation via PayPal](https://www.paypal.com/donate/?hosted_button_id=PQQQB3CHQ5FRG).

## License

MIT — see [LICENSE.md](LICENSE.md).

NeoDex Toolkit is a community-made fan tool. It is not affiliated with, endorsed by or
connected to Blizzard Entertainment, Inc.
