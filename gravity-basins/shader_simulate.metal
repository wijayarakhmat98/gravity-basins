#include <metal_stdlib>
#include "state.h"

using namespace metal;

[[stitchable]] half4 simulate(
	float2 position,
	half4 color,
	float2 resolution,
	float2 origin,
	float scale,
	device float2* const body_position,
	int body_position_n,
	device half4* const body_color,
	int body_color_n
) {
	int body_n = body_position_n / 2;

	position = screen_to_world(position, resolution, origin, scale);

	bool in_planet = false;
	half3 product = half3(1.0, 1.0, 1.0);

	for (int i = 0; i < body_n; ++i)
		if (distance(position, body_position[i]) < 1.0) {
			product *= body_color[i].xyz;
			in_planet = true;
		}

	return in_planet ? half4(product, 1.0) : color;
}
