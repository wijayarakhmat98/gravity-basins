import SwiftUI

struct body_t : Equatable {
	var timestamp = Date.now
	var mass : Double
	var position : CGPoint
	var color : color_t
}

func body_select(_ state : state_t, _ position : CGPoint) -> Int? {
	var nearest_r : Double = .infinity
	var nearest_i : Int = -1
	var in_body = false
	for i in stride(from : 0, to : state.bodies.count, by : 1)  {
		let body = state.bodies[i]
		let dx = body.position.x - position.x
		let dy = body.position.y - position.y
		let r = hypot(dx, dy)
		if r < nearest_r {
			nearest_r = r
			nearest_i = i
			if r < body.mass {
				in_body = true
			}
		}
	}
	return in_body ? nearest_i : nil
}

func body_add(_ state : state_t, _ position : CGPoint) -> state_t {
	var result = state
	result.bodies.append(body_t(
		mass : 5,
		position : position,
		color : color_t(.random(in : 0..<1), .random(in : 0..<1), .random(in : 0..<1))
	))
	return result
}

func body_remove(_ state : state_t, _ i : Int) -> state_t {
	var result = state
	result.bodies.remove(at : i)
	return result
}

func body_translate(_ state : state_t, _ delta : CGSize) -> state_t {
	var result = state
	if let i = state.select_drag {
		var body = state.bodies[i]
		body.position.x += delta.width / state.camera.magnification
		body.position.y -= delta.height / state.camera.magnification
		result.bodies[i] = body
	}
	return result
}

func body_update(_ state : state_t, _ bus : bus_t, _ mass : Double, _ red : Double, _ green : Double, _ blue : Double) -> state_t {
	var result = state
	if let i = state.select {
		var body = state.bodies[i]
		body.mass = mass
		body.color.red = red
		body.color.green = green
		body.color.blue = blue
		result.bodies[i] = body
	}
	result.in_motion = true
	bus.publish_debounce(
		id : "body",
		for : .nanoseconds(100_000_000),
		schedule : { .body_update_done }
	)
	return result
}

func body_update_done(_ state : state_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}
