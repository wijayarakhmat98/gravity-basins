#include <metal_stdlib>
#include "state.h"

using namespace metal;

[[stitchable]] half4 basins(
	float2 position,
	half4 color,
	float2 resolution,
	float2 origin,
	float scale,
	device float2* const body_position,
	int body_position_n,
	device half4* const body_color,
	int body_color_n,
	float duration,
	float dt,
	float epsilon
) {
	int body_n = body_position_n / 2;
	if (body_n == 0)
		return color;

	float2 velocity = float2(0.0, 0.0);
	position = screen_to_world(position, resolution, origin, scale);

	bool in_planet = false;
	half3 product = half3(1.0, 1.0, 1.0);

	for (int i = 0; i < body_n; ++i)
		if (distance(position, body_position[i]) < 1.0) {
			product *= body_color[i].xyz;
			in_planet = true;
		}

	if (in_planet)
		return half4(product, 1.0);

	for (float t = 0; t < duration; t += dt)
	{
		float2 force_sum = float2(0.0, 0.0);

		for (int i = 0; i < body_n; ++i) {
			float r = distance(position, body_position[i]);
			float f = 1.0 / (r * r + epsilon);
			float2 d = body_position[i] - position;
			float2 force = f * (d / r);
			force_sum += force;
		}

//		float2 force_drag = epsilon * length(velocity) * velocity;
//		force_sum -= force_drag;

		float2 acceleration = force_sum;
		velocity += acceleration * dt;

		position += velocity * dt;
	}

	float nearest_distance = INFINITY;
	int nearest_i = -1;

	for (int i = 0; i < body_n; ++i) {
		float d = distance(position, body_position[i]);
		if (d < nearest_distance) {
			nearest_distance = d;
			nearest_i = i;
		}
	}

	return body_color[nearest_i];
}
