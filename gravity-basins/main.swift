import SwiftUI

func main() {
	let state = state_default()
	let bus = bus_t()
	let store = store_t(state : state, bus : bus)
	let _ = controller_t(store : store)
	app.main(store : store)
}

main()
