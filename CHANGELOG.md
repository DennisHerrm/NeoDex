# Changelog

Summary of each release. Full release notes with technical details are on the
[releases page](https://github.com/DennisHerrm/NeoDex/releases).

## Unreleased

Fixes made after the 4.7.0 release (August 2026) in:
`Wc3Material.ms`, `NeoDexSceneRebuilder.ms`, `NeoDexImportFunctions.ms`,
`AnimTools.ms`, `Wc3Animation.ms`.

## [4.7.0] — 2026-08-01

### Added
- One Click Tools

### Fixed
- Duplicating a sequence only copied part of the animation (visibility, material opacity,
  colour animation, Biped transforms, multi-layer materials, geoset colour animation)
- Two global sequences missing from the Sequence Manager and Global Sequence Manager
  (KGAC tracks on `Wc3VertexMod`, composite and multi/sub-object materials)
- Second UV set lost on import and destroyed on export
- Meshes torn apart on export when vertices shared UV coordinates
- Skin weights scrambled when a modifier was shared or the object was frozen
- Sequence Manager wiped the menu registration
- Global Sequence Manager destroyed the rest pose, cancel left keys behind
- Cell Shade Creator: clicking a colour swatch threw an error
- Material editor: sequence folder browser failed on first use
- Auto-updater blocked startup; now deferred, and prefers the setup asset
- Hermite cache leaked between exports
- Dead reference in the Popcorn plugin, missing localisation key, duplicate event keys
- Menu installer leaked a submenu on every startup

### Changed
- Native BLP support detection checks four locations and probes whether 3ds Max can
  open BLP on its own before falling back to the external decoder
- Silent failures in the core modules are now reported

## [4.6.0] — 2026-04-11

### Added
- Localisation for Keyframe Optimizer and Cell Shade Creator (all six languages)

### Fixed
- Biped bones exported with "don't inherit rotation/scaling" set
- Filter mode labels cut off on Windows 10 and on Chinese systems

## [4.5.0] — 2026-04-11

### Fixed
- Biped bones exported with "don't inherit rotation/scaling" set

## [4.4.0] — 2026-03-31

### Added
- Keyframe Optimizer (Ramer-Douglas-Peucker reduction for position, rotation and scale)
- Cell Shade Creator (outline meshes with Warcraft III materials)
- Export of MassFX-baked animation and Editable Poly objects
- Export folder opens as a tab in an existing Explorer window on Windows 11
- Complete sound event codes from `AnimLookups.slk`, with translations
- Team glow textures loaded from MPQ/CASC archives
- Texture preview follows the replaceable texture type

### Fixed
- Event objects with unknown sound codes imported incorrectly
- Texture preview and BLP conversion failed for `.max` files from another machine
  or with Unicode characters in the path
- Import crash on models with empty materials
- Controller assignment destroying MassFX data; missing sequence boundary keys for MassFX
- Editable Poly objects flagged as export problems
- Sequence order corruption on export

## [4.3.0] — 2026-03-31

### Added
- Native BLP Bitmap I/O plugin (`blp.bmi`) for 3ds Max 2022–2027
- 3ds Max 2027 support
- Event object plugin: linked type/code dropdowns, auto-detection, localisation

### Changed
- Reforged PBR texture slots support drag and drop from the Material Editor
- Reforged material layout fix, new material editor banner

[4.7.0]: https://github.com/DennisHerrm/NeoDex/releases/tag/v4.7.0
[4.6.0]: https://github.com/DennisHerrm/NeoDex/releases/tag/v4.6.0
[4.5.0]: https://github.com/DennisHerrm/NeoDex/releases/tag/v4.5.0
[4.4.0]: https://github.com/DennisHerrm/NeoDex/releases/tag/v4.4.0
[4.3.0]: https://github.com/DennisHerrm/NeoDex/releases/tag/v4.3.0
