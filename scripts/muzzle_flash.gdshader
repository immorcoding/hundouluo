shader_type canvas_item;

uniform float rear_column;

void fragment() {
	// Clip only the atlas export residue behind the visible muzzle seam.
	float cell_x = mod(UV.x / TEXTURE_PIXEL_SIZE.x, 48.0);
	if (cell_x < rear_column) {
		COLOR.a = 0.0;
	}
}
