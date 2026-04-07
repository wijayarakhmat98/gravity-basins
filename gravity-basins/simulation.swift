import SwiftUI

struct simulate_t : Equatable {
	var timestamp : Date
	var mass : Double
	var position : CGPoint
}

func simulate_add(_ state : state_t, _ bus : bus_t, _ position : CGPoint) -> state_t {
	var result = state
	let delay = Duration.seconds(state.duration / state.speed)
	result.simulate.append(simulate_t(
		timestamp : Date.now,
		mass : state.mass,
		position : position
	))
	bus.publish_delayed(for : delay, schedule : { .simulate_remove })
	return result
}

func simulate_remove(_ state : state_t, _ bus : bus_t) -> state_t {
	var result = state
	let now = Date.now
	let delay = state.duration / state.speed
	result.simulate = result.simulate.filter { s in
		let elapsed = s.timestamp.distance(to : now)
		return elapsed < delay
	}
	return result
}

func simulation(_ simulate : [simulate_t], _ bodies : [body_t], _ duration : Double, _ dt : Double, _ epsilon : Double, _ speed : Double) -> [simulate_t] {
	let now = Date.now

	return simulate.map { s in
		var px = s.position.x
		var py = s.position.y
		var vx : Double = 0
		var vy : Double = 0

		let elapsed = s.timestamp.distance(to : now) * speed

		for _ in stride(from : 0, to : elapsed, by : dt) {
			var fx_sum : Double = 0
			var fy_sum : Double = 0

			for body in bodies {
				let dx = body.position.x - px
				let dy = body.position.y - py
				let r = hypot(dx, dy)
				let f_mag = body.mass * s.mass / (r * r + epsilon)
				let fx = f_mag * (dx / r)
				let fy = f_mag * (dy / r)
				fx_sum += fx
				fy_sum += fy
			}

			let ax = fx_sum / s.mass
			let ay = fy_sum / s.mass
			vx += ax * dt
			vy += ay * dt
			px += vx * dt
			py += vy * dt
		}

		var result = s
		result.position = CGPoint(x : px, y : py)
		return result
	}
}
