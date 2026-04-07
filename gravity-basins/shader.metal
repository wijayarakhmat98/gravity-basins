#include <metal_stdlib>

using namespace metal;

float2 screen_to_world(float2 position, float2 resolution, float2 translation, float magnification) {
	return float2(
		(translation.x - resolution.x / 2 + position.x) / magnification,
		(translation.y + resolution.y / 2 - position.y) / magnification
	);
}

float2 world_to_screen(float2 position, float2 resolution, float2 translation, float magnification) {
	return float2(
		resolution.x / 2 - translation.x + position.x * magnification,
		resolution.y / 2 + translation.y - position.y * magnification
	);
}

bool in_body(float2 self, int n, device float const* mass, device float2 const* position) {
	for (int i = 0; i < n; ++i)
		if (distance(self, position[i]) < mass[i])
			return true;
	return false;
}

float2 simulation(float2 self, int n, device float const* mass, device float2 const* position, float duration, float dt, float epsilon, float m) {
	float2 v = float2(0, 0);

	for (float t = 0; t < duration; t += dt) {
		float2 f_sum = float2(0, 0);

		for (int i = 0; i < n; ++i) {
			float r = distance(self, position[i]);
			float f_mag = mass[i] * m / (r * r + epsilon);
			float2 d = position[i] - self;
			float2 f = f_mag * (d / r);
			f_sum += f;
		}

		float2 a = f_sum / m;
		v += a * dt;

		self += v * dt;
	}

	return self;
}

int nearest(float2 self, int n, device float2 const* position) {
	float nearest_r = INFINITY;
	int nearest_i = -1;
	for (int i = 0; i < n; ++i) {
		float r = distance(self, position[i]);
		if (r < nearest_r) {
			nearest_r = r;
			nearest_i = i;
		}
	}
	return nearest_i;
}

[[stitchable]] half4 draw_bodies(
	float2 canvas_position,
	half4 canvas_color,
	float2 canvas_resolution,
	float2 translation,
	float magnification,
	device float const* mass,
	int n,
	device float2 const* position,
	int,
	device half4 const* color,
	int
) {
	float2 self = screen_to_world(canvas_position, canvas_resolution, translation, magnification);

	bool in_planet = false;
	half3 result = half3(1, 1, 1);

	for (int i = 0; i < n; ++i)
		if (distance(self, position[i]) < mass[i]) {
			result *= color[i].xyz;
			in_planet = true;
		}

	return in_planet ? half4(result, 1) : canvas_color;
}

[[stitchable]] half4 draw_select(
	float2 canvas_position,
	half4 canvas_color,
	float2 canvas_resolution,
	float2 translation,
	float magnification,
	float const mass,
	float2 const position
) {
	float2 self = screen_to_world(canvas_position, canvas_resolution, translation, magnification);

	float d = distance(self, position);
	if (d < mass) {
		if (d < mass - 1.25) {
			if (d < mass - 2.5)
				return canvas_color;
			else
				return half4(0, 0, 0, 1);
		} else {
			return half4(canvas_color.xyz / 4 + 0.75, 1);
		}
	}

	return canvas_color;
}

[[stitchable]] half4 visual(
	float2 canvas_position,
	half4 canvas_color,
	float2 canvas_resolution,
	float2 translation,
	float magnification,
	device float const* mass,
	int n,
	device float2 const* position,
	int,
	device half4 const* color,
	int,
	float duration,
	float dt,
	float epsilon,
	float m
) {
	float2 self = screen_to_world(canvas_position, canvas_resolution, translation, magnification);

	if (in_body(self, n, mass, position))
		return canvas_color;

	self = simulation(self, n, mass, position, duration, dt, epsilon, m);

	return color[nearest(self, n, position)];
}
