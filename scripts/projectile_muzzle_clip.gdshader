shader_type canvas_item;

uniform float muzzle_x;
uniform float direction;
varying float world_x;

void vertex() {
	world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
}

void fragment() {
	// Only an emitted projectile's visible tail can still overlap its gun.
	if (direction * (world_x - muzzle_x) <= 0.001) {
		COLOR.a = 0.0;
	}
}
