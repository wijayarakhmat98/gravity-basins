import Combine

class controller_t {
	let state_b : box<state_t>
	let bus : bus_t
	let dispatch : (state_t, bus_t, event_t) -> state_t

	private var cancellable = Set<AnyCancellable>()

	init(
		_ state_b : box<state_t>,
		_ bus : bus_t,
		_ dispatch : @escaping (state_t, bus_t, event_t) -> state_t
	) {
		self.state_b = state_b
		self.bus = bus
		self.dispatch = dispatch

		bus.subscribe()
			.sink { event in
				let result = self.dispatch(state_b.value, bus, event)
				if state_b.value != result {
					state_b.value = result
				}
			}
			.store(in : &cancellable)
	}
}
