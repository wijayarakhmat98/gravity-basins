import Combine
import SwiftUI

class controller_t {
	let store : store_t
	private var cancellable = Set<AnyCancellable>()

	init(store : store_t) {
		self.store = store
		store.bus.subscribe()
			.sink { event in self.dispatch(event) }
			.store(in : &cancellable)
	}

	func dispatch(_ event : event_t) {
		switch event {
			case .log(let message):
				print(message)
			case .double_click_gravity(let position, let resolution):
				body_remove(screen_to_world(position, resolution, store.state.origin, store.state.scale))
			case .click_gravity(let position, let resolution):
				body_add(screen_to_world(position, resolution, store.state.origin, store.state.scale))
			case .click_basin(let position, let resolution):
				simulate_add(screen_to_world(position, resolution, store.state.origin, store.state.scale))
			case .drag(let delta):
				update_origin(delta)
			case .zoom(let delta):
				update_zoom(delta)
			case .simulate_remove:
				simulate_remove()
		}
	}

	func body_add(_ position : CGPoint) {
		store.state.body.append(body_t(
			position : position,
			color : Color(red : .random(in : 0...1), green : .random(in : 0...1), blue : .random(in : 0...1))
		))
	}

	func body_remove(_ position : CGPoint) {
		store.state.body = store.state.body.filter { b in
			let d = hypot(position.x - b.position.x, position.y - b.position.y)
			return d > 1.0
		}
	}

	func update_origin(_ delta : CGSize) {
		store.state.origin.x -= delta.width
		store.state.origin.y += delta.height
	}

	func update_zoom(_ delta : CGFloat) {
		store.state.scale *= delta
		store.state.origin.x *= 2 - 1 / delta
		store.state.origin.y *= 2 - 1 / delta
	}

	func simulate_add(_ position : CGPoint) {
		store.state.simulate = simulate_t(
			start : Date.now,
			position : position
		)
	}

	func simulate_remove() {
		let duration = Double(store.state.duration)
		let simulate_scale = Double(store.state.simulate_scale)
		let now = Date.now
		if (store.state.simulate != nil) {
			let start = store.state.simulate!.start
			let elapsed = start.distance(to : now) * simulate_scale
			if (elapsed > duration) {
				store.state.simulate = nil
			}
		}
	}
}
