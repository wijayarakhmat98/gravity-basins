import SwiftUI

func shader_draw_bodies(_ bodies : [body_t], _ camera : camera_t, _ screen_resolution : CGSize) -> Shader {
	return ShaderLibrary.draw_bodies(
		.float2(screen_resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		serialize_position(bodies),
		serialize_mass(bodies),
		serialize_color(bodies)
	)
}

func shader_draw_select(_ bodies : [body_t], _ camera : camera_t, _ screen_resolution : CGSize, _ i : Int?) -> Shader? {
	guard let i else {
		return nil
	}
	let body = bodies[i]
	return ShaderLibrary.draw_select(
		.float2(screen_resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		.float2(body.position),
		.float(body.mass)
	)
}

func shader_visual(_ editor : editor_t, _ bodies : [body_t], _ simulation : simulation_t, _ camera : camera_t, _ visual : visual_t) -> Shader {
	return ShaderLibrary.visual(
		.float2(visual.resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		.float(editor.mass),
		serialize_position(bodies),
		serialize_mass(bodies),
		serialize_color(bodies),
		.float(simulation.duration),
		.float(simulation.dt),
		.float(simulation.epsilon)
	)
}

private func serialize_mass(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.map {body in Float(body.mass) })
}

private func serialize_position(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.flatMap {body in [Float(body.position.x), Float(body.position.y)] })
}

private func serialize_color(_ bodies : [body_t]) -> Shader.Argument {
	return .colorArray(bodies.map {body in
		let color = body.color
		return Color(red : color.red, green : color.green, blue : color.blue)
	})
}
