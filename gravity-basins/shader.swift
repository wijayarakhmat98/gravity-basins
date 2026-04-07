import SwiftUI

func shader_draw_bodies(_ state : state_t, _ resolution : CGSize) -> Shader {
	let bodies = state.bodies
	let camera = state.camera
	return ShaderLibrary.draw_bodies(
		.float2(resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		serialize_mass(bodies),
		serialize_position(bodies),
		serialize_color(bodies)
	)
}

func shader_draw_simulate(_ state : state_t, _ resolution : CGSize, _ elements : [body_t]) -> Shader {
	let camera = state.camera
	return ShaderLibrary.draw_bodies(
		.float2(resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		serialize_mass(elements),
		serialize_position(elements),
		serialize_color(elements)
	)
}

func shader_draw_select(_ state : state_t, _ resolution : CGSize) -> Shader? {
	let bodies = state.bodies
	let camera = state.camera
	if let i = state.select {
		let body = bodies[i]
		return ShaderLibrary.draw_select(
			.float2(resolution),
			.float2(camera.translation),
			.float(camera.magnification),
			.float(body.mass),
			.float2(body.position)
		)
	}
	return nil
}

func shader_visual(_ state : state_t) -> Shader {
	let bodies = state.bodies
	let simulation = state.simulation
	let camera = state.camera
	let visual = state.visual
	return ShaderLibrary.visual(
		.float2(visual.resolution),
		.float2(camera.translation),
		.float(camera.magnification),
		serialize_mass(bodies),
		serialize_position(bodies),
		serialize_color(bodies),
		.float(simulation.duration),
		.float(simulation.dt),
		.float(simulation.epsilon),
		.float(simulation.mass)
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
