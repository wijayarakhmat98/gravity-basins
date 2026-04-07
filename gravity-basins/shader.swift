import SwiftUI

func shader_draw_bodies(_ state : state_t, _ resolution : CGSize) -> Shader {
	return ShaderLibrary.draw_bodies(
		.float2(resolution),
		.float2(state.camera.translation),
		.float(state.camera.magnification),
		body_serialize_mass(state.bodies),
		body_serialize_position(state.bodies),
		body_serialize_color(state.bodies)
	)
}

func shader_draw_simulate(_ state : state_t, _ resolution : CGSize, _ simulate : [simulate_t]) -> Shader {
	return ShaderLibrary.draw_simulate(
		.float2(resolution),
		.float2(state.camera.translation),
		.float(state.camera.magnification),
		simulate_serialize_mass(simulate),
		simulate_serialize_position(simulate)
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
		body_serialize_mass(state.bodies),
		body_serialize_position(state.bodies),
		body_serialize_color(state.bodies),
		.float(state.duration),
		.float(state.dt),
		.float(state.epsilon),
		.float(state.mass)
	)
}

private func body_serialize_mass(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.map {body in Float(body.mass) })
}

private func body_serialize_position(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.flatMap {body in [Float(body.position.x), Float(body.position.y)] })
}

private func body_serialize_color(_ bodies : [body_t]) -> Shader.Argument {
	return .colorArray(bodies.map {body in
		let color = body.color
		return Color(red : color.red, green : color.green, blue : color.blue)
	})
}

private func simulate_serialize_timestamp(_ simulate : [simulate_t]) -> Shader.Argument {
	let now = Date.now
	return .floatArray(simulate.map {s in Float(s.timestamp.distance(to : now)) })
}

private func simulate_serialize_mass(_ simulate : [simulate_t]) -> Shader.Argument {
	return .floatArray(simulate.map {s in Float(s.mass) })
}

private func simulate_serialize_position(_ simulate : [simulate_t]) -> Shader.Argument {
	return .floatArray(simulate.flatMap {s in [Float(s.position.x), Float(s.position.y)] })
}
