import SwiftUI

main()

private func main() {
	let state_b = box<state_t>(state_default)
	let bus = bus_t()
	withExtendedLifetime(controller_t(state_b, bus)) {
		app.main(state_b, bus)
	}
}
