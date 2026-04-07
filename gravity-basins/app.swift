import SwiftUI

struct app : App {
	private static var inject_state_b : box<state_t>!
	private static var inject_bus : bus_t!

	static func main(_ state_b : box<state_t>, _ bus : bus_t) {
		inject_state_b = state_b
		inject_bus = bus
		main()
	}

	@State private var state_b : box<state_t> = inject_state_b
	private let bus : bus_t = inject_bus

	var body : some Scene {
		WindowGroup {
			view()
				.environment(\.state_b, state_b)
				.environment(\.bus, bus)
		}
		.restorationBehavior(.disabled)
		.defaultSize(width : 1080, height : 720)
	}
}

private extension EnvironmentValues {
	@Entry var state_b = box<state_t>(state_default)
	@Entry var bus = bus_t()
}

private struct view : View {
	@Environment(\.state_b) private var state_b

	var body : some View {
		let state = state_b.value
		return VStack(spacing : 16) {
			HStack(spacing : 16) {
				if state.elements.count > 0 {
					view_simulate()
						.clipShape(RoundedRectangle(cornerRadius : 16))
				} else {
					view_editor()
						.clipShape(RoundedRectangle(cornerRadius : 16))
				}
				view_visual()
					.clipShape(RoundedRectangle(cornerRadius : 16))
			}
			view_toolbar()
				.frame(minHeight : 32)
		}
		.padding()
		.onAppear {
			NSApplication.shared.activate(ignoringOtherApps : true)
		}
	}
}

private struct view_toolbar : View {
	@Environment(\.state_b) private var state_b
	@Environment(\.bus) private var bus

	@State private var red : Double = 0

	var body : some View {
		let state = state_b.value
		HStack(spacing : 0) {
			if let i = state.select {
				let body = state.bodies[i]
				let color = body.color
				Spacer(minLength : 32)
				Text("Mass:")
				Slider(value : Binding( get : { body.mass }, set : { mass in bus.publish(.body_update(mass, color.red, color.green, color.blue)) }), in : state.mass_min...state.mass_max)
				Spacer(minLength : 32)
				Text("Red:")
				Slider(value : Binding( get : { color.red }, set : { red in bus.publish(.body_update(body.mass, red, color.green, color.blue)) }), in : 0...1)
				Spacer(minLength : 32)
				Text("Green:")
				Slider(value : Binding( get : { color.green }, set : { green in bus.publish(.body_update(body.mass, color.red, green, color.blue)) }), in : 0...1)
				Spacer(minLength : 32)
				Text("Blue:")
				Slider(value : Binding( get : { color.blue }, set : { blue in bus.publish(.body_update(body.mass, color.red, color.green, blue)) }), in : 0...1)
				Spacer(minLength : 32)
			}
		}
	}
}

private struct view_editor : View {
	@Environment(\.state_b) private var state_b

	@State private var resolution : CGSize = .zero

	var body : some View {
		let state = state_b.value
		Rectangle()
			.fill(.black)
			.track_resolution(to : $resolution)
			.publish_double_tap(from : .editor, with : resolution)
			.publish_single_tap(from : .editor, with : resolution)
			.publish_drag(from : .editor, with : resolution)
			.publish_magnify(from : .editor)
			.apply_shader(shader_draw_bodies(state, resolution))
			.apply_shader(shader_draw_select(state, resolution))
	}
}

private struct view_simulate : View {
	@Environment(\.state_b) private var state_b

	@State private var resolution : CGSize = .zero

	var body : some View {
		TimelineView(.animation) { tl in
			let state = state_b.value
			let elements = simulate_elements(state.elements, state.bodies, state.simulation)
			Rectangle()
				.fill(.black)
				.track_resolution(to : $resolution)
				.publish_double_tap(from : .editor, with : resolution)
				.publish_single_tap(from : .editor, with : resolution)
				.publish_drag(from : .editor, with : resolution)
				.publish_magnify(from : .editor)
				.apply_shader(shader_draw_bodies(state, resolution))
				.apply_shader(shader_draw_select(state, resolution))
				.apply_shader(shader_draw_simulate(state, resolution, elements))
		}
	}
}

private struct view_visual : View {
	@Environment(\.state_b) private var state_b

	@State private var resolution : CGSize = .zero

	var body : some View {
		Rectangle()
			.fill(.black)
			.track_resolution(to : $resolution, publish : .visual)
			.overlay_fragment(state_b.value.visual)
			.publish_single_tap(from : .visual, with : resolution)
	}
}

private extension View {
	func track_resolution(to resolution : Binding<CGSize>, publish source : source_t? = nil) -> some View {
		self.modifier(modifier_track_resolution(to : resolution, publish : source))
	}

	func publish_single_tap(from source : source_t, with resolution : CGSize) -> some View {
		self.modifier(modifier_publish_single_tap(from : source, with : resolution))
	}

	func publish_double_tap(from source : source_t, with resolution : CGSize) -> some View {
		self.modifier(modifier_publish_double_tap(from : source, with : resolution))
	}

	func publish_drag(from source : source_t, with resolution : CGSize) -> some View {
		self.modifier(modifier_publish_drag(from : source, with : resolution))
	}

	func publish_magnify(from source : source_t) -> some View {
		self.modifier(modifier_publish_magnify(from : source))
	}

	func apply_shader(_ shader : Shader?) -> some View {
		self.modifier(modifier_apply_shader(shader))
	}

	func overlay_fragment(_ visual : visual_t) -> some View {
		self.modifier(modifier_overlay_fragment(visual))
	}
}

private struct modifier_track_resolution : ViewModifier {
	@Environment(\.displayScale) private var displayScale
	@Environment(\.bus) private var bus

	@Binding var resolution : CGSize

	let source : source_t?

	init(to resolution : Binding<CGSize>, publish source : source_t? = nil) {
		self._resolution = resolution
		self.source = source
	}

	func body(content : Content) -> some View {
		content.onGeometryChange(
			for : CGSize.self,
			of : { proxy in proxy.size },
			action : { size in
				resolution = size
				if let source {
					bus.publish_debounce(
						id : "resolution",
						for : .nanoseconds(100_000_000),
						schedule : {
							.resolution(source, displayScale, resolution)
						}
					)
				}
			}
		)
	}
}

private struct modifier_publish_single_tap : ViewModifier {
	@Environment(\.bus) private var bus

	let source : source_t
	let resolution : CGSize

	init(from source : source_t, with resolution : CGSize) {
		self.source = source
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		content.gesture(SpatialTapGesture(count : 1).onEnded { event in
			bus.publish(.single_tap(source, event.location, resolution))
		})
	}
}

private struct modifier_publish_double_tap : ViewModifier {
	@Environment(\.bus) private var bus

	let source : source_t
	let resolution : CGSize

	init(from source : source_t, with resolution : CGSize) {
		self.source = source
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		content.gesture(SpatialTapGesture(count : 2).onEnded { event in
			bus.publish(.double_tap(source, event.location, resolution))
		})
	}
}

private struct modifier_publish_drag : ViewModifier {
	@Environment(\.bus) private var bus

	@State private var start : Bool = false
	@State private var translation : CGSize = .zero

	let source : source_t
	let resolution : CGSize

	init(from source : source_t, with resolution : CGSize) {
		self.source = source
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		content.gesture(DragGesture()
			.onChanged { event in
				if !start {
					start = true
					bus.publish(.drag_start(source, event.startLocation, resolution))
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

	init(from source : source_t) {
		self.source = source
	}

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

private struct modifier_apply_shader : ViewModifier {
	let shader : Shader?

	init(_ shader : Shader?) {
		self.shader = shader
	}

	func body(content : Content) -> some View {
		if let shader {
			content.colorEffect(shader)
		} else {
			content
		}
	}
}

private struct modifier_overlay_fragment : ViewModifier {
	let visual : visual_t

	init(_ visual : visual_t) {
		self.visual = visual
	}

	func body(content : Content) -> some View {
		if let fragment = visual.fragment {
			content.overlay(fragment)
		} else {
			content
		}
	}
}
