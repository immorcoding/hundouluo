# Font provenance — UI redesign / 2026-09-29

Selected file: `fusion-pixel-12px-proportional-zh_hans.otf`, unmodified upstream bytes.

- Author/project: TakWolf / Fusion Pixel Font.
- Official release: https://github.com/TakWolf/fusion-pixel-font/releases/tag/2026.09.25
- Exact archive: https://github.com/TakWolf/fusion-pixel-font/releases/download/2026.09.25/fusion-pixel-font-12px-proportional-otf-v2026.09.25.zip
- Tag target commit: `6c88c8ec0f16f05e06663890a043ecbc81d448ae` (annotated tag object `35b8aa0f69e477d415708692f4951e1ce5bc2e8e`).
- Archive SHA256: `b0138dfdb5b9fae0159b1e996710782aaf7f47d2b2db26ddc13cd066f6dbb14b`.
- OTF SHA256: `e84b6d1ab8f2e25084761eb61c88b373bf1fa0b0c5e9b559d5b1d90e4d658c86`.

Included verbatim from that archive: `OFL.txt` (Fusion Pixel copyright and SIL OFL 1.1), `LICENSES/ark-pixel/OFL.txt`, `LICENSES/cubic-11/OFL.txt`, and `LICENSES/galmuri/LICENSE.txt`. These upstream notices accompany the selected font, including the notices for its upstream sources. Other language font binaries and the archive itself are not part of this committed delivery.

The font is not relicensed under the game's root LICENSE. OFL 1.1 permits bundling/embedding and redistribution with the copyright and license, and prohibits selling the font alone. It has not been subsetted, renamed, converted, or edited. Keep these notices with any future game distribution containing it. Only this isolated review directory includes it now; no production scene or export asset list is changed.

Rendering: Godot FontFile reads these OTF bytes directly; system fallback disabled; antialiasing, hinting, MSDF and subpixel positioning disabled; oversampling 1. Text uses 12px, outcome title 24px. Integer coordinates and nearest texture sampling match the project's logical pixel canvas. Godot and Python glyph checks cover all Chinese UI phrases plus R and digits. Preview exports do not depend on Windows font installation.

Official references verified on 2026-09-29:
- Font copyright/license: https://github.com/TakWolf/fusion-pixel-font/blob/6c88c8ec0f16f05e06663890a043ecbc81d448ae/LICENSE-OFL
- Font rendering: https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html
