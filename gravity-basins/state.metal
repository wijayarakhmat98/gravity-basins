#include <metal_stdlib>

using namespace metal;

float2 screen_to_world(float2 position, float2 resolution, float2 origin, float scale) {
	return float2(
		(origin.x - resolution.x / 2 + position.x) / scale,
		(origin.y + resolution.y / 2 - position.y) / scale
	);
}

float2 world_to_screen(float2 position, float2 resolution, float2 origin, float scale) {
	return float2(
		resolution.x / 2 - origin.x + position.x * scale,
		resolution.y / 2 + origin.y - position.y * scale
	);
}
