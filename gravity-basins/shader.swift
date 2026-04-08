import SwiftUI

func shader_draw_bodies(_ bodies : [body_t], _ camera : camera_t, _ screen_resolution : CGSize) -> Shader {
	ShaderLibrary.draw_bodies(
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

func shader_visual(_ state : state_t) -> Shader {
	let (editor, bodies, simulation, camera, visual) = (state)~>(\.editor, \.bodies, \.simulation, \.camera, \.visual)
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
	.floatArray(bodies.map { body in Float(body.mass) })
}

private func serialize_position(_ bodies : [body_t]) -> Shader.Argument {
	.floatArray(bodies.flatMap { body in [Float(body.position.x), Float(body.position.y)] })
}

private func serialize_color(_ bodies : [body_t]) -> Shader.Argument {
	.colorArray(bodies.map { body in
		let color = body.color
		return Color(red : color.red, green : color.green, blue : color.blue)
	})
}
