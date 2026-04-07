import SwiftUI

func shader_draw_bodies(_ state : state_t, _ resolution : CGSize) -> Shader {
	return ShaderLibrary.draw_bodies(
		.float2(resolution),
		.float2(state.camera.translation),
		.float(state.camera.magnification),
		serialize_mass(state.bodies),
		serialize_position(state.bodies),
		serialize_color(state.bodies)
	)
}

func shader_draw_simulate(_ state : state_t, _ resolution : CGSize, _ elements : [body_t]) -> Shader {
	return ShaderLibrary.draw_bodies(
		.float2(resolution),
		.float2(state.camera.translation),
		.float(state.camera.magnification),
		serialize_mass(elements),
		serialize_position(elements),
		serialize_color(elements)
	)
}

func shader_draw_select(_ state : state_t, _ resolution : CGSize) -> Shader? {
	if let i = state.select {
		let body = state.bodies[i]
		return ShaderLibrary.draw_select(
			.float2(resolution),
			.float2(state.camera.translation),
			.float(state.camera.magnification),
			.float(body.mass),
			.float2(body.position)
		)
	}
	return nil
}

func shader_visual(_ state : state_t) -> Shader {
	return ShaderLibrary.visual(
		.float2(state.visual.resolution),
		.float2(state.camera.translation),
		.float(state.camera.magnification),
		serialize_mass(state.bodies),
		serialize_position(state.bodies),
		serialize_color(state.bodies),
		.float(state.duration),
		.float(state.dt),
		.float(state.epsilon),
		.float(state.mass)
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
