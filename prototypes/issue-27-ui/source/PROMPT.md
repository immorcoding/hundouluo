# Original UI panel / 2026-09-29

Built-in ImageGen; transparent background enabled. Output: `exec-fe4476f0-8f66-414c-94d2-7b88d0646e00.png`.

```
Use case: ui-mockup. Asset type: ORIGINAL reusable game UI panel background texture, standalone raster production source. Create ONE wide rectangular sci-fi rescue hangar console panel, front view perfectly flat orthographic, width to height 2:1. Dark desaturated navy blue gunmetal with crisp pixel-art stepped bevels, two thin muted steel blue inset edge lines, small inset fasteners at corners, restrained worn metal detail ONLY on the outermost 8% border, clipped angular corners. The entire inner 84% must be empty solid very dark navy #0a1722, completely clean space for readable live UI typography. No words, letters, symbols, logos, numbers, screens or decorative center graphics. No orange or cyan lights; neutral steel-blue trim to support both warning amber and information cyan overlays later. No outside objects. Transparent background outside panel, no shadow outside silhouette, no perspective, no glows, no gradients. Pixel art with dense industrial edge detail matching a blue-grey orbital rescue hangar; sharp pixels. One panel only, centered, near fills canvas. Output landscape 1536x1024 with panel itself 2:1 and transparent margins.
```

No external image inputs. Original PNG preserved as `console-panel.png`. Godot samples source region `[20,92,1734,682]` at render time; PNG is not overwritten. The neutral frame is reused for both outcomes. Text, HUD plates, life pips, progress, separators and R keycap are editable Godot drawing commands in `render_previews.gd`, not baked into the generated source.
