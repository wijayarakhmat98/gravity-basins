import SwiftUI

func screen_to_world(_ position : CGPoint, _ resolution : CGSize, _ translation : CGPoint, _ magnification : CGFloat) -> CGPoint {
	let x = (translation.x - resolution.width  / 2 + position.x) / magnification
	let y = (translation.y + resolution.height / 2 - position.y) / magnification
	return CGPoint(x : x, y : y)
}

func world_to_screen(_ position : CGPoint, _ resolution : CGSize, _ translation : CGPoint, _ magnification : CGFloat) -> CGPoint {
	let x = resolution.width  / 2 - translation.x + position.x * magnification
	let y = resolution.height / 2 + translation.y - position.y * magnification
	return CGPoint(x : x, y : y)
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
