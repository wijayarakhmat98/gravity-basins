import SwiftUI

struct view : View {
	@Bindable var store : store_t

	var body : some View {
		HStack {
			if store.state.simulate == nil {
				view_gravity(store : store)
				.clipShape(RoundedRectangle(cornerRadius : 16))
			} else {
				view_simulate(store : store)
				.clipShape(RoundedRectangle(cornerRadius : 16))
			}
			Spacer(minLength : 16)
			view_basin(store : store)
				.clipShape(RoundedRectangle(cornerRadius : 16))
		}
		.padding()
	}
}
