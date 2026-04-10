import SwiftUI

extension View {
	func modify<T : View>(@ViewBuilder _ transform : (Self) -> T) -> some View {
		transform(self)
	}

	@ViewBuilder
	func modify_if<T : View>(_ predicate : Bool, @ViewBuilder _ transform : (Self) -> T) -> some View {
		if predicate {
			transform(self)
		}
		else { self }
	}

	@ViewBuilder
	func modify_if_let<U, T : View>(_ predicate : U?, @ViewBuilder _ transform : (Self, U) -> T) -> some View {
		if let predicate {
			transform(self, predicate)
		}
		else { self }
	}
}

extension EnvironmentValues {
	@Entry var bus = bus_t()
	@Entry var screen_resolution = CGSize.zero
}

extension View {
	func track_resolution(publish source : source_t? = nil) -> some View {
		self.modifier(modifier_track_resolution(source : source))
	}

	func publish_single_tap(from source : source_t) -> some View {
		self.modifier(modifier_publish_single_tap(source : source))
	}

	func publish_double_tap(from source : source_t) -> some View {
		self.modifier(modifier_publish_double_tap(source : source))
	}

	func publish_drag(from source : source_t) -> some View {
		self.modifier(modifier_publish_drag(source : source))
	}

	func publish_magnify(from source : source_t) -> some View {
		self.modifier(modifier_publish_magnify(source : source))
	}
}

private struct modifier_track_resolution : ViewModifier {
	@Environment(\.displayScale) private var displayScale
	@Environment(\.bus) private var bus

	@State private var screen_resolution = CGSize.zero

	let source : source_t?

	func body(content : Content) -> some View {
		content
			.environment(\.screen_resolution, screen_resolution)
			.onGeometryChange(
				for : CGSize.self,
				of : { proxy in proxy.size },
				action : { size in
					screen_resolution = size
					if let source {
						bus.publish(.screen_resolution(source, displayScale, screen_resolution))
					}
				}
			)
	}
}

private struct modifier_publish_single_tap : ViewModifier {
	@Environment(\.bus) private var bus
	@Environment(\.screen_resolution) private var screen_resolution

	let source : source_t

	func body(content : Content) -> some View {
		content.gesture(SpatialTapGesture(count : 1).onEnded { event in
			bus.publish(.single_tap(source, event.location, screen_resolution))
		})
	}
}

private struct modifier_publish_double_tap : ViewModifier {
	@Environment(\.bus) private var bus
	@Environment(\.screen_resolution) private var screen_resolution

	let source : source_t

	func body(content : Content) -> some View {
		content.gesture(SpatialTapGesture(count : 2).onEnded { event in
			bus.publish(.double_tap(source, event.location, screen_resolution))
		})
	}
}

private struct modifier_publish_drag : ViewModifier {
	@Environment(\.bus) private var bus
	@Environment(\.screen_resolution) private var screen_resolution

	@State private var start : Bool = false
	@State private var translation : CGSize = .zero

	let source : source_t

	func body(content : Content) -> some View {
		content.gesture(DragGesture()
			.onChanged { event in
				if !start {
					start = true
					bus.publish(.drag_start(source, event.startLocation, screen_resolution))
				}
				let delta = CGSize(
					width : event.translation.width - translation.width,
					height : event.translation.height - translation.height
				)
				translation = event.translation
				bus.publish(.drag(source, delta))
			}
			.onEnded { _ in
				start = false
				translation = .zero
				bus.publish(.drag_end(source))
			}
		)
	}
}

private struct modifier_publish_magnify : ViewModifier {
	@Environment(\.bus) private var bus

	@State private var magnification : CGFloat = 1

	let source : source_t

	func body(content : Content) -> some View {
		content.gesture(MagnifyGesture()
			.onChanged { event in
				let delta = event.magnification / magnification
				magnification = event.magnification
				bus.publish(.magnify(source, delta))
			}
			.onEnded { _ in
				magnification = 1
				bus.publish(.magnify_end(source))
			}
		)
	}
}
