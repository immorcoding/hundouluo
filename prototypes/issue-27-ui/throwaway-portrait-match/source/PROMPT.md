# Rifle material match — original prototype asset

Built-in ImageGen, transparent background, 2026-09-29. Output `exec-7b221b12-831c-49b3-8886-15f1f3772234.png`, unchanged source `rifle.png` (2176x723 RGBA).

References: Image 1 is the existing original `throwaway-ab/source/operative-portrait.png`, the detailed helmet chosen by the user. Image 2 is the project's approved #22 `assets/art_source/operative-sheet.png`. No external characters/assets. The helmet source is NOT edited. The new rifle only belongs to this throwaway prototype; no runtime resource replacement.

Full prompt:

```
Use case: stylized-concept. Original standalone HUD rifle icon for this project's approved operative. Image 1 is the EXISTING detailed cyan-white helmet portrait: match its pixel-art materials and palette without altering that portrait. Image 2 is the approved character sprite sheet: match the rifle's silhouette and identity. Generate ONLY ONE horizontal rifle, pointing right, side view, no hands, no arms, no person, no frame, no text, no effects. White/pale ivory receiver with desaturated blue-grey metal edge shadows, a slim luminous cyan TOP rail, short dark muzzle at right, small pistol grip under rear-middle, chunky industrial sci-fi silhouette. Material detail must use deliberate stepped pixel clusters, 3-4 controlled tones per local material, crisp edges, no smooth painterly shading or glow. Design for display about 76x24 logical pixels, with recognizable receiver/rail/muzzle/grip even at that scale. The old detailed portrait is the style anchor; do NOT simplify or redraw the portrait. Wide rifle with transparent background and small transparent margins. Keep source identity; no new scope, magazine counter, ammo, logo, inventory or firing mode controls.
```

Godot samples source region [136,118,1928,540] (transparent padding trimmed at draw time, source unchanged) into a 76x24 logical-pixel icon with nearest filtering. Source identity is recorded; this remains generated-assisted prototype art, not claimed hand-drawn or exclusive copyright. Reuse the project's existing font/license records. All material changes are restricted to the new rifle, never the approved helmet.
