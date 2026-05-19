import SwiftUI

struct simulation_t : Equatable, destructurable {
	let duration : Double
	let dt : Double
	let epsilon : Double
	let speed : Double
}

func element_add(_ old : [body_t], _ editor : editor_t, _ position : CGPoint) -> [body_t] {
	(old)~>{ new in
		new.append(body_t(
			timestamp : Date.now,
			position : position,
			mass : editor.mass,
			color : editor.color
		))
	}
}

func element_remove(_ elements : [body_t], _ simulation : simulation_t) -> [body_t] {
	let delay = simulation.duration / simulation.speed
	let now = Date.now
	return elements.filter { element in
		let elapsed = element.timestamp.distance(to : now)
		return elapsed < delay
	}
}

nonisolated
func simulate_element(
	_ old : body_t,
	_ bodies : [body_t],
	_ simulation : simulation_t,
	_ now : Date = .now
)
-> body_t
{
	var px = old.position.x
	var py = old.position.y
	var vx : Double = 0
	var vy : Double = 0

	let mass = old.mass
	let elapsed = old.timestamp.distance(to : now) * simulation.speed

	for _ in stride(from : 0, to : elapsed, by : simulation.dt) {
		var fx_sum : Double = 0
		var fy_sum : Double = 0

		for body in bodies {
			let dx = body.position.x - px
			let dy = body.position.y - py
			let r = hypot(dx, dy)
			let f_mag = mass * body.mass / (r * r + simulation.epsilon)
			let fx = f_mag * (dx / r)
			let fy = f_mag * (dy / r)
			fx_sum += fx
			fy_sum += fy
		}

		let ax = fx_sum / mass
		let ay = fy_sum / mass
		vx += ax * simulation.dt
		vy += ay * simulation.dt
		px += vx * simulation.dt
		py += vy * simulation.dt
	}

	return (old)~>{ new in
		new.position = CGPoint(x : px, y : py)
	}
}

func simulate_elements(
	_ elements : [body_t],
	_ bodies : [body_t],
	_ simulation : simulation_t,
	_ now : Date = .now
)
-> [body_t]
{
	elements.parallel_map { element in
		simulate_element(element, bodies, simulation, now)
	}
}

extension Array {
	func parallel_map<T>(chunk : Int? = nil, _ transform : @escaping @Sendable (Element) -> T) -> [T] {
		let safe = ProcessInfo.processInfo.activeProcessorCount * 4
		let chunk = chunk ?? self.count / safe
		let batch_size = Swift.max(1, chunk)
		let batch_n = (self.count + batch_size - 1) / batch_size

		let array = Array<T>(
			unsafeUninitializedCapacity : self.count
		) {
			buffer, count
		in
			guard let address = buffer.baseAddress else {
				count = 0
				return
			}
			DispatchQueue.global(qos: .utility).sync {
				DispatchQueue.concurrentPerform(iterations : batch_n) { batch_i in
					let start = batch_i * batch_size
					let end = Swift.min(start + batch_size, self.count)
					for i in start ..< end {
						(address + i).initialize(to : transform(self[i]))
					}
				}
			}
			count = self.count
		}

		return array
	}
}
