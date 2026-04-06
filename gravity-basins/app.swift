import SwiftUI

struct app : App {
	private static var inject_store : store_t!

	static func main(store : store_t) {
		inject_store = store
		main()
	}

	@State private var store : store_t = inject_store

	var body : some Scene {
		WindowGroup {
			view(store : store)
		}
		.restorationBehavior(.disabled)
		.defaultSize(width: 1080, height: 720)
	}
}

#Preview {
	view(store : store_preview())
}
