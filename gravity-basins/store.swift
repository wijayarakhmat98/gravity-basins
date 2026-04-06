import SwiftUI

@Observable
class store_t {
	var state : state_t
	var bus : bus_t

	init(
		state : state_t,
		bus : bus_t
	) {
		self.state = state
		self.bus = bus
	}
}

func store_preview() -> store_t {
	return store_t(
		state : state_default(),
		bus : bus_t()
	)
}
