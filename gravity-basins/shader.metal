#include <metal_stdlib>

using namespace metal;

auto screen_to_world(float2 const, float2 const, float2 const, float const) -> float2;
auto world_to_screen(float2 const, float2 const, float2 const, float const) -> float2;
auto body_nearest(float2 const, int const, float2 device const*) -> int;
auto simulate_element(float2, float const, int const, float2 device const*, float device const*, float const, float const, float const) -> float2;

[[stitchable]]
auto draw_bodies(
	float2 const screen_position,
	half4 const screen_color,
	float2 const screen_resolution,
	float2 const camera_translation,
	float const camera_magnification,
	float2 device const* bodies_position,
	int const,
	float device const* bodies_mass,
	int const bodies_n,
	half4 device const* bodies_color,
	int const
)
-> half4
{
	auto const position { screen_to_world(screen_position, screen_resolution, camera_translation, camera_magnification) };

	auto in_body { false };
	auto color = half3 { 1, 1, 1 };

	for (auto i { 0 }; i < bodies_n; ++i) {
		auto const body_position { bodies_position[i] };
		auto const body_mass { bodies_mass[i] };
		auto const body_color { bodies_color[i] };
		auto const r { distance(position, body_position) };

		if (r < body_mass) {
			color *= body_color.xyz;
			in_body = true;
		}
	}

	return in_body ? half4(color, 1) : screen_color;
}

[[stitchable]]
auto draw_select(
	float2 const screen_position,
	half4 const screen_color,
	float2 const screen_resolution,
	float2 const camera_translation,
	float const camera_magnification,
	float2 const body_position,
	float const body_mass
)
-> half4
{
	auto const position { screen_to_world(screen_position, screen_resolution, camera_translation, camera_magnification) };
	auto const r { distance(position, body_position) };

	if (r > body_mass || r < body_mass - 2.5)
		return screen_color;

	if (r > body_mass - 1.25)
		return half4(screen_color.xyz / 4 + 0.75, 1);

	return { 0, 0, 0, 1 };
}

[[stitchable]]
auto visual(
	float2 const screen_position,
	half4 const screen_color,
	float2 const screen_resolution,
	float2 const camera_translation,
	float const camera_magnification,
	float const mass,
	float2 device const* bodies_position,
	int const,
	float device const* bodies_mass,
	int const bodies_n,
	half4 device const* bodies_color,
	int const,
	float const duration,
	float const dt,
	float const epsilon
)
-> half4
{
	auto position { screen_to_world(screen_position, screen_resolution, camera_translation, camera_magnification) };

	for (auto i { 0 }; i < bodies_n; ++i) {
		auto const body_position { bodies_position[i] };
		auto const body_mass { bodies_mass[i] };
		auto const r { distance(position, body_position) };

		if (r < body_mass)
			return screen_color;
	}

	position = simulate_element(position, mass, bodies_n, bodies_position, bodies_mass, duration, dt, epsilon);

	auto const nearest { body_nearest(position, bodies_n, bodies_position) };
	auto const color { bodies_color[nearest] };

	return color;
}

auto screen_to_world(
	float2 const screen_position,
	float2 const screen_resolution,
	float2 const camera_translation,
	float const camera_magnification
)
-> float2
{
	return {
		(camera_translation.x - screen_resolution.x / 2 + screen_position.x) / camera_magnification,
		(camera_translation.y + screen_resolution.y / 2 - screen_position.y) / camera_magnification
	};
}

auto world_to_screen(
	float2 const world_position,
	float2 const screen_resolution,
	float2 const camera_translation,
	float const camera_magnification
)
-> float2
{
	return {
		screen_resolution.x / 2 - camera_translation.x + world_position.x * camera_magnification,
		screen_resolution.y / 2 + camera_translation.y - world_position.y * camera_magnification
	};
}

auto body_nearest(
	float2 const position,
	int const bodies_n,
	float2 device const* bodies_position
)
-> int
{
	auto nearest_r { INFINITY };
	auto nearest_i { -1 };

	for (auto i { 0 }; i < bodies_n; ++i) {
		auto const body_position { bodies_position[i] };
		auto const r { distance(position, body_position) };

		if (r < nearest_r) {
			nearest_r = r;
			nearest_i = i;
		}
	}

	return nearest_i;
}

auto simulate_element(
	float2 position,
	float const mass,
	int const bodies_n,
	float2 device const* bodies_position,
	float device const* bodies_mass,
	float const duration,
	float const dt,
	float const epsilon
)
-> float2
{
	auto velocity = float2 { 0, 0 };

	for (auto i { 0 }; i * dt < duration; ++i) {
		auto f_sum = float2 { 0, 0 };

		for (auto j { 0 }; j < bodies_n; ++j) {
			auto const body_position { bodies_position[j] };
			auto const body_mass { bodies_mass[j] };

			auto const d { body_position - position };
			auto const r { length(d) };
			auto const f_mag { mass * body_mass / (r * r + epsilon) };
			auto const f { f_mag * (d / r) };

			f_sum += f;
		}

		auto const acceleration { f_sum / mass };
		velocity += acceleration * dt;
		position += velocity * dt;
	}

	return position;
}
