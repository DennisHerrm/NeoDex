# NeoDex Toolkit

Warcraft III model toolkit for Autodesk 3ds Max — import, edit, animate and export
MDX/MDL models for both Classic (v800) and Reforged (v1200).

**Current version:** 4.7.0 · **3ds Max:** 2022–2027 (64-bit) · **License:** MIT

[Download the latest installer](https://github.com/DennisHerrm/NeoDex/releases/latest) ·
[Changelog](CHANGELOG.md)

---

## Features

**Import / Export**
- MDX and MDL import and export, Classic (v800) and Reforged (v1200, PBR materials, skin data, LODs)
- Textures read directly from MPQ (Classic) and CASC (Reforged) archives
- Native BLP texture support in 3ds Max via `blp.bmi`, with an automatic fallback decoder
- Biped, MassFX-baked and Editable Poly objects are exported correctly
- Multiple UV sets, geoset colour animation and global sequences are preserved

**Warcraft III scene objects**
- Warcraft III material with team colour, team glow, filter modes and Reforged PBR maps
- Particle emitters (Blizzard Particle 1/2, Popcorn), ribbons, lights, attachment points,
  event objects, collision shapes and FaceFX

**Animation and scene tools** (sidebar and NeoDex menu)
- Sequence Manager and Global Sequence Manager
- Animation tools, visibility keyer, skin changer, team colour manager
- Node manager, object settings, object manipulation tools, grid and dummy creator
- Extra tools: Keyframe Optimizer, Cell Shade Creator

**Interface**
- Dockable sidebar and NeoDex menu in 3ds Max
- Six languages: English, German, Chinese, Russian, Japanese, Korean
- Built-in update check against the GitHub releases

## Installation

### Installer (recommended)

1. Download `NeoDex_Setup_vX.Y.Z.exe` from the
   [latest release](https://github.com/DennisHerrm/NeoDex/releases/latest).
2. Close 3ds Max and run the installer.
3. Start 3ds Max. The **NeoDex** menu and sidebar appear automatically.

The installer updates earlier versions in place and keeps your `maps` folder and settings.
It installs to `%APPDATA%\Autodesk\ApplicationPlugins\NeoDex` and does not touch the
3ds Max program directory.

### Manual installation from source

Copy the [`NeoDex`](NeoDex) folder from this repository to

```
%APPDATA%\Autodesk\ApplicationPlugins\NeoDex
```

and restart 3ds Max. 3ds Max loads the package via
[`PackageContents.xml`](NeoDex/PackageContents.xml).

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

## Credits

Developed by **DennisH** and **Benjamin Schiefer**.
Third-party components are listed in [THIRD_PARTY.md](NeoDex/THIRD_PARTY.md).

## License

MIT — see [LICENSE.md](LICENSE.md).

NeoDex Toolkit is a community-made fan tool. It is not affiliated with, endorsed by or
connected to Blizzard Entertainment, Inc.
