import SwiftUI

struct body_t {
	var position : CGPoint
	var color : Color
}

struct simulate_t {
	var start = Date.now
	var position : CGPoint
}

struct state_t {
	var origin : CGPoint
	var scale : CGFloat
	var body : Array<body_t>
	var duration : Float
	var dt : Float
	var epsilon : Float
	var simulate : simulate_t?
	var simulate_scale : Float
}

func state_default() -> state_t {
	return state_t(
		origin : .zero,
		scale : 10.0,
		body : [
			body_t(position : CGPoint(x :  10.0, y : 0.0), color : Color(.red)),
			body_t(position : CGPoint(x : -10.0, y : 0.0), color : Color(.cyan))
		],
		duration : 320.0,
		dt : 0.2,
		epsilon : 0.2,
		simulate_scale : 30.0
	)
}

func serialize_position(_ body : Array<body_t>) -> Shader.Argument {
	return .floatArray(body.flatMap { [Float($0.position.x), Float($0.position.y)] })
}

func serialize_color(_ body : Array<body_t>) -> Shader.Argument {
	return .colorArray(body.map { $0.color })
}

func screen_to_world(_ position : CGPoint, _ resolution : CGSize, _ origin : CGPoint, _ scale : CGFloat) -> CGPoint {
	let x = (origin.x - resolution.width  / 2 + position.x) / scale
	let y = (origin.y + resolution.height / 2 - position.y) / scale
	return CGPoint(x : x, y : y)
}

func world_to_screen(_ position : CGPoint, _ resolution : CGSize, _ origin : CGPoint, _ scale : CGFloat) -> CGPoint {
	let x = resolution.width  / 2 - origin.x + position.x * scale
	let y = resolution.height / 2 + origin.y - position.y * scale
	return CGPoint(x : x, y : y)
}
