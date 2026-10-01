# NeoDex Toolkit for 3ds Max

[![Download](https://img.shields.io/github/v/release/DennisHerrm/NeoDex?label=download&color=2ea043)](https://github.com/DennisHerrm/NeoDex/releases/latest)
[![3ds Max](https://img.shields.io/badge/3ds%20Max-2022%20–%202027-0696D7)](#installing)
[![Formats](https://img.shields.io/badge/MDX%20%2F%20MDL-v800%20%7C%20v1200-8a2be2)](#what-it-does)
[![Languages](https://img.shields.io/badge/languages-6-orange)](#interface)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE.md)
[![Hive Workshop](https://img.shields.io/badge/Hive%20Workshop-approved%20%26%20recommended-c8a02c)](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/)
[![Discord](https://img.shields.io/badge/Discord-NeoDex%20Development-5865F2?logo=discord&logoColor=white)](https://discord.gg/6pt5v6sAEc)

The Warcraft III model toolkit for Autodesk 3ds Max. It imports, edits,
animates and exports **MDX** and **MDL** models, for both
**Classic (v800)** and **Reforged (v1200)**.

Models, skeletons, skinning, materials, particles and animations, in
both directions.

NeoDex goes back to the original MDLX toolkit by **BlinkBoy
(Fernando A. Sahmkow)**. Jaccouille, Blinkoon and Bensen kept it alive
through 2.8 and 2.9. From 3.0 on, DennisH and Benjamin Schiefer rewrote
most of it, and 4.0 added full Reforged support.

<p align="center">
  <a href="https://github.com/DennisHerrm/NeoDex/releases/latest"><b>⬇&nbsp; Download the latest version</b></a>
  &nbsp;·&nbsp; <a href="#installing">Installation guide</a>
  &nbsp;·&nbsp; <a href="CHANGELOG.md">Changelog</a>
  &nbsp;·&nbsp; <a href="https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/">Hive Workshop</a>
</p>

---

## What it does

| Area | What you get |
| :--- | :--- |
| **Formats** | MDX and MDL, Classic v800 and Reforged v1200. The importer detects the version, and the exporter lets you choose it |
| **Geometry** | Meshes with UVs (several UV sets), smoothing groups, vertex colours and LOD layers |
| **Skinning** | Classic matrix groups and Reforged per-vertex weights (SKIN), bind poses (BPOS) and tangents (TANG) |
| **Materials** | Warcraft III material with filter modes, team colour and team glow, texture animation and IFL sequences |
| **Reforged PBR** | Diffuse, normal, ORM, emissive and environment maps, Fresnel and emissive gain |
| **Animation** | Rotation, translation, scale and visibility, with Hermite tangents and global sequences preserved through the round trip |
| **Shared sequences** | Reforged alias sequences stay linked to their master and are collapsed again on export |
| **Objects** | Bones, helpers, cameras, lights, attachment points, event objects and collision shapes |
| **Emitters** | Particle emitters 1 and 2, ribbons, Popcorn FX (CORN), FaceFX (FAFX) |
| **Rigs** | Biped, IK- and Link-constrained bones, MassFX-baked animation, Editable Poly |
| **Game files** | Browse and import models straight from **MPQ** (Classic) and **CASC** (Reforged) |
| **BLP** | Native BLP textures in 3ds Max (viewport, material editor, preview), plus BLP conversion on export |

On top of that, NeoDex brings a set of tools for building Warcraft III
models: sequence managers, animation and skin tools, a visibility keyer,
a keyframe optimizer and more. See [The tools](#the-tools).

---

## Installing

> [!IMPORTANT]
> Close 3ds Max first. The plugin is loaded on startup, and a running
> 3ds Max keeps its files locked.

All downloads are on the **[Releases page](https://github.com/DennisHerrm/NeoDex/releases/latest)**.
Do not use *Code → Download ZIP*. That gives you the source code, not
the installer.

### Option 1: Setup (recommended)

1. Download **`NeoDex_Setup_v<version>.exe`** from the
   [latest release](https://github.com/DennisHerrm/NeoDex/releases/latest).
2. Run it. It installs into your user profile under
   `%APPDATA%\Autodesk\ApplicationPlugins\NeoDex` and does not touch
   the 3ds Max program folder.
3. Start 3ds Max. The **NeoDex** menu and the sidebar appear on their
   own.

**Updating:** run the Setup of the newer version. It upgrades older
NeoDex versions in place and keeps your `maps` folder and settings.
NeoDex also checks GitHub for new versions on startup.
**Uninstalling:** run `unins000.exe` in the install folder.

One installer covers every 3ds Max version from 2022 to 2027.

> [!NOTE]
> The installer is not code-signed. On a fresh download, Windows
> SmartScreen may say *"Windows protected your PC"*. Click
> **More info → Run anyway**.

### Option 2: From source, without an installer

Copy the [`NeoDex`](NeoDex) folder from this repository to
`%APPDATA%\Autodesk\ApplicationPlugins` and restart 3ds Max.

<details>
<summary><b>Where the plugin goes, and what the folder must look like</b></summary>

Paste this into the Explorer address bar:

```
%APPDATA%\Autodesk\ApplicationPlugins
```

It expands to `C:\Users\<you>\AppData\Roaming\Autodesk\ApplicationPlugins`.
3ds Max scans this folder on every start.

The `NeoDex` folder has to end up looking like this:

```text
%APPDATA%\Autodesk\ApplicationPlugins\
└── NeoDex\
    ├── PackageContents.xml              the package manifest 3ds Max reads
    ├── version.txt
    ├── WhiteoutTexCLI.exe               texture extraction and conversion
    ├── pre-start-up scripts parts\      core: readers, writers, import, export
    ├── scripted plugins parts\          material, emitters, lights, events ...
    ├── post-start-up scripts parts\     tools, sidebar, menu, updater
    ├── macroscripts parts\              menu and toolbar actions
    ├── extra tools\                     Keyframe Optimizer, Cell Shade Creator
    ├── native plugins\
    │   ├── Max2022\blp.bmi              one BLP plugin per Max version
    │   ├── ...
    │   ├── Max2027\blp.bmi
    │   ├── Max2022-2025\NeoDexNative.dll
    │   └── Max2026+\NeoDexNative.dll
    ├── neodex_icons\
    └── maps\Neodex\TeamGlow\
```

> [!WARNING]
> **`PackageContents.xml` must sit directly inside `NeoDex`.** In any
> other place, 3ds Max ignores the whole folder without a message.
>
> **Keep the folder names exactly as they are**, spaces included.
> The manifest lists every file by its path.

</details>

After starting 3ds Max, the MAXScript Listener shows a line about BLP
support, for example:

```
NeoDex: Native BLP support detected (...)
```

---

## Starting it

| Way | Where | Note |
| :--- | :--- | :--- |
| **Menu** | *NeoDex → Importer / Exporter / Manager / Settings / About* | Extra tools are in *NeoDex → Extra Tools* |
| **Sidebar** | Docked at the left edge of the viewport | One button per tool. Switch it on or off in *NeoDex → Settings* |
| **Customize** | *Customize → Customize User Interface → Category "NeoDex Toolkit"* | Put any tool on a toolbar, quad menu or shortcut |
| **Listener** | `macros.run "NeoDex Toolkit" "NeoDex_Manager"` | Works for every action of the category |

The tool panels inside the **NeoDex Manager** can each be undocked into
their own window, for example to keep the Sequence Manager open on a
second monitor.

<details>
<summary><b>The NeoDex menu does not show up?</b></summary>

- Check that *Customize → Customize User Interface* lists the category
  **NeoDex Toolkit**. If it does, NeoDex is loaded and only the menu is
  missing. Use the sidebar or put the actions on a toolbar.
- If the category is missing, the package was not loaded. Check the
  folder layout above, especially the place of `PackageContents.xml`.

</details>

---

## Using it

### Importing

1. Open **NeoDex → Importer**.
2. Pick a model with **Open Model**, or import directly from the game
   files with the **MPQ** or **CASC** browser.
3. NeoDex detects Classic or Reforged and shows the matching options.
   Choose what to import, then click **Import**.

| Option | What it does |
| :--- | :--- |
| Fast Settings | Presets: *Static No Materials*, *Static Materials*, *Animated No Skinning*, *Animated No objects*, *All* |
| Mode | *New Scene* or *Merge* into the open scene |
| Geometry / Materials / Textures | Meshes with skinning, Warcraft III materials and their textures |
| Objects | Bones, helpers, lights, attachments, particle emitters 1 and 2, ribbons, event objects, collision shapes, cameras. Reforged adds Corn emitters and FaceFX |
| Animations | Rotation, translation, scale, parameters, texture and UV animation, visibility, colour |
| Import Helpers as Point Helpers | Uses the 3ds Max Point helper for Warcraft III helpers |
| Optimizer | Optimize geometry, optimize bones and helpers |
| Search MPQ / CASC Archives for Textures | Looks up textures that are missing next to the model in the game archives |

### Exporting

1. Open **NeoDex → Exporter**.
2. Set model name and file name, and choose **Classic (v800)** or
   **Reforged (v1200)**.
3. Check the **Scene Status**. It lists problems such as invalid
   materials or bones before anything is written. **Fix All** repairs
   what can be repaired automatically.
4. Click **Export**.

| Option | What it does |
| :--- | :--- |
| Merge similar meshes | Combines similar geosets into one |
| Export Smoothgroups / Fix shared normals | Controls how normals are written across geosets |
| AT Skinning Fix normals | Normal fix for models skinned with the Art Tools method |
| Keep unused Bones/Helpers | Writes bones and helpers even when nothing uses them |
| Extents Calculation | *Animation Dependent* or *Global*, with adjustable precision |
| Open folder after export | Opens the target folder (as a new tab in Windows 11 Explorer) |
| Convert textures to BLP on export | BLP conversion with compression, JPEG quality, dithering and mipmaps |
| Export Mode | *Standard*, or *Debug* for extra output in the Listener |

### Settings

*NeoDex → Settings* holds the interface language, the paths to your
**MPQ** (Classic) and **CASC** (Reforged) game files, the sidebar switch
and the update check.

> [!TIP]
> Set the MPQ and CASC paths once. Then the importer finds missing
> textures in the game files, the team glow comes from the game, and
> the model browsers list every model of the game.

---

## The tools

| Tool | What it is for |
| :--- | :--- |
| **Sequence Manager** | Create, duplicate, rename and filter sequences; rarity, move speed, looping, nudge keys, export ignore list, presets |
| **Global Sequence Manager** | Find, record and edit global sequences, including those on geoset colour animation |
| **General Tools** | *One Click Tools*: attachment points from bone names, portrait camera, collision spheres, collision box |
| **Skinning** | Art Tools skinning: save and unlink, restore parents |
| **Controllers** | Sets position, rotation and scale tracks of the selection to Linear, Bezier/Smooth or TCB |
| **Model Scaler** | Scales a model to a target height or by a manual factor |
| **Visibility Keyer** | Visibility animation with None, Linear, Bezier and TCB keys |
| **Skin Changer** | Converts skin data to the Warcraft III layout |
| **Team Color Manager** | Team colour regions and preview colour |
| **Node Manager** | Show, hide, freeze or see-through nodes by type (geometry, bones, Biped, CAT, helpers, emitters ...) |
| **Object Settings** | Node flags: inheritance, billboarding, camera anchored, skinning method |
| **Object Manipulation Tools** | Copy and paste hierarchy, position and structure, with mirroring |
| **Grid and Dummy Creator** | Helper grids and dummy objects |
| **Keyframe Optimizer** | Reduces position, rotation and scale keys per sequence |
| **Cell Shade Creator** | Cel-shaded outlines with Warcraft III materials |

### Interface

- The NeoDex menu, a dockable sidebar, and tool panels that can be undocked.
- Six languages: English, German, Chinese, Russian, Japanese and Korean.
- An update check against the GitHub releases.

---

## Repository layout

| Path | Contents |
| :--- | :--- |
| [`NeoDex/`](NeoDex) | The plugin bundle, exactly as it is installed |
| [`NeoDex/PackageContents.xml`](NeoDex/PackageContents.xml) | Autodesk package manifest: load order and Max version ranges |
| `NeoDex/pre-start-up scripts parts/` | MDX/MDL readers and writers, scene parser and rebuilder, import, export, localisation |
| `NeoDex/scripted plugins parts/` | Warcraft III material, emitters, ribbons, lights, attachments, events, collision shapes |
| `NeoDex/post-start-up scripts parts/` | Managers, animation tools, sidebar, menu, auto-updater |
| `NeoDex/macroscripts parts/` | Menu and toolbar actions |
| `NeoDex/extra tools/` | Keyframe Optimizer, Cell Shade Creator |
| `NeoDex/native plugins/` | `blp.bmi` per Max version and `NeoDexNative.dll` |
| [`CHANGELOG.md`](CHANGELOG.md) | What changed in each version |

User settings are written at runtime to `NeoDex_Settings.ini` in the
install folder and are not part of the repository.

---

## Good to know

- **3ds Max 2022 or newer** is required. For 3ds Max 2016–2021, NeoDex
  2.8 is still available on the
  [Hive Workshop page](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/).
- **BLP plugin conflicts:** if another toolkit installs its own
  `blp.bmi`, the two can clash. NeoDex works without its own copy. It
  checks whether 3ds Max can open BLP anyway and otherwise falls back to
  its built-in decoder.
- **MDL has no bind pose chunk.** Reforged bind poses (BPOS) are written
  to MDX only. The game rebuilds them from frame 0 for MDL.

---

## Bugs and feedback

Found a bug or have an idea? Report it in
[GitHub issues](https://github.com/DennisHerrm/NeoDex/issues), in the
[Hive Workshop thread](https://www.hiveworkshop.com/threads/neodex-4-7-reforged-edition.354942/)
or on the [NeoDex Development Discord](https://discord.gg/6pt5v6sAEc).
Animation questions are also welcome on the
[WC3 Animations Discord](https://discord.gg/v8hYf4nTmb).

Tutorials are on the
[Wc3Tutorials YouTube channel](https://www.youtube.com/@Wc3Tutorials).

---

## Credits

NeoDex has passed through many hands over the years.

| Who | Role |
| :--- | :--- |
| **BlinkBoy / Fernando A. Sahmkow** | Original author of NeoDex |
| **Jaccouille, Blinkoon, Bensen** | Updaters of NeoDex 2.8 and 2.9 |
| **DennisH** | Lead developer from 3.0 |
| **Benjamin Schiefer** | Developer from 3.0 |
| **LxXDinjin** | Material, light, Blizzard Particle 1 and 2, ribbon emitter and collision shape plugins |
| **Republicola** | Creator of the original Dexporter |
| **Igni** | Biped support and various fixes |
| **Bensen** | Attachment point auto-generation, Sequence Manager safety features |
| **ghostheroine** | Testing, light export and colour fixes |
| **gluma** | Testing |
| **Adiktuz, BallisticTerrain, Manoo, skrab, Talavaj** | Beta testing |

| Library | By | Used for |
| :--- | :--- | :--- |
| [WhiteoutLib](https://github.com/FernandoS27/WhiteoutLib) | [FernandoS27](https://github.com/FernandoS27) | BLP support in the native plugin and in WhiteoutTex |

Further third-party components are listed in
[THIRD_PARTY.md](NeoDex/THIRD_PARTY.md).

NeoDex is a community-made fan tool. It is not affiliated with,
endorsed by or connected to Blizzard Entertainment, Inc.

---

## Support

If NeoDex helps you, you can support its development with a
[donation via PayPal](https://www.paypal.com/donate/?hosted_button_id=PQQQB3CHQ5FRG).

---

## License

[MIT](LICENSE.md) © 2026 DennisH & Benson
