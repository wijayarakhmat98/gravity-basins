import SwiftUI

func simulate_add(_ state : state_t, _ bus : bus_t, _ position : CGPoint) -> state_t {
	var result = state
	let delay = Duration.seconds(state.duration / state.speed)
	result.elements.append(body_t(
		timestamp : Date.now,
		mass : state.mass,
		position : position,
		color : color_t(1, 1, 1)
	))
	bus.publish_delayed(for : delay, schedule : { .simulate_remove })
	return result
}

func simulate_remove(_ state : state_t, _ bus : bus_t) -> state_t {
	var result = state
	let now = Date.now
	let delay = state.duration / state.speed
	result.elements = result.elements.filter { element in
		let elapsed = element.timestamp.distance(to : now)
		return elapsed < delay
	}
	return result
}

func simulation(_ elements : [body_t], _ bodies : [body_t], _ duration : Double, _ dt : Double, _ epsilon : Double, _ speed : Double) -> [body_t] {
	let now = Date.now

	return elements.map { element in
		var px = element.position.x
		var py = element.position.y
		var vx : Double = 0
		var vy : Double = 0

		let elapsed = element.timestamp.distance(to : now) * speed

		for _ in stride(from : 0, to : elapsed, by : dt) {
			var fx_sum : Double = 0
			var fy_sum : Double = 0

			for body in bodies {
				let dx = body.position.x - px
				let dy = body.position.y - py
				let r = hypot(dx, dy)
				let f_mag = body.mass * element.mass / (r * r + epsilon)
				let fx = f_mag * (dx / r)
				let fy = f_mag * (dy / r)
				fx_sum += fx
				fy_sum += fy
			}

			let ax = fx_sum / element.mass
			let ay = fy_sum / element.mass
			vx += ax * dt
			vy += ay * dt
			px += vx * dt
			py += vy * dt
		}

		var result = element
		result.position = CGPoint(x : px, y : py)
		return result
	}
}
