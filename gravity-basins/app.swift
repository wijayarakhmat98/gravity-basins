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
	@State private var bus : bus_t = inject_bus

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
	@Environment(\.bus) private var bus

	var body : some View {
		bus.publish(.log("REFRESH"))
		let state = state_b.value
		return VStack(spacing : 16) {
			HStack(spacing : 16) {
				if state.simulate.count > 0 {
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
	@State private var resolution : CGSize = .zero

	var body : some View {
		Rectangle()
			.fill(.black)
			.track_resolution(to : $resolution)
			.publish_double_tap(from : .editor, with : resolution)
			.publish_single_tap(from : .editor, with : resolution)
			.publish_drag(from : .editor, with : resolution)
			.publish_magnify(from : .editor)
			.draw_bodies(resolution)
			.draw_select(resolution)
	}
}

private struct view_simulate : View {
	@Environment(\.state_b) private var state_b

	@State private var resolution : CGSize = .zero

	var body : some View {
		TimelineView(.animation) { tl in
			let state = state_b.value
			let simulate = simulation(state.simulate, state.bodies, state.duration, state.dt, state.epsilon, state.speed)
			Rectangle()
				.fill(.black)
				.track_resolution(to : $resolution)
				.publish_double_tap(from : .editor, with : resolution)
				.publish_single_tap(from : .editor, with : resolution)
				.publish_drag(from : .editor, with : resolution)
				.publish_magnify(from : .editor)
				.draw_bodies(resolution)
				.draw_select(resolution)
				.draw_simulate(simulate, resolution)
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
			.overlay_fragments(state_b.value.visual)
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

	func draw_bodies(_ resolution : CGSize) -> some View {
		self.modifier(modifier_draw_bodies(resolution))
	}

	func draw_simulate(_ simulate : [simulate_t], _ resolution : CGSize) -> some View {
		self.modifier(modifier_draw_simulate(simulate, resolution))
	}

	func draw_select( _ resolution : CGSize) -> some View {
		self.modifier(modifier_draw_select(resolution))
	}

	func overlay_fragments(_ visual : visual_t) -> some View {
		self.modifier(modifier_overlay_fragments(visual))
	}
}

private struct modifier_track_resolution : ViewModifier {
	@Environment(\.displayScale) private var displayScale
	@Environment(\.bus) private var bus

	@Binding var resolution : CGSize

	@State private var task : Task<Void, Never>?

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
					task?.cancel()
					task = Task {
						try? await Task.sleep(nanoseconds : 100_000_000)
						if !Task.isCancelled {
							bus.publish(.resolution(source, displayScale, resolution))
						}
					}
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

private struct modifier_draw_bodies : ViewModifier {
	@Environment(\.state_b) private var state_b

	let resolution : CGSize

	init(_ resolution : CGSize) {
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		let state = state_b.value
		let shader = ShaderLibrary.draw_bodies(
			.float2(resolution),
			.float2(state.translation),
			.float(state.magnification),
			body_serialize_mass(state.bodies),
			body_serialize_position(state.bodies),
			body_serialize_color(state.bodies)
		)
		content.colorEffect(shader)
	}
}

private struct modifier_draw_simulate : ViewModifier {
	@Environment(\.state_b) private var state_b

	let simulate : [simulate_t]
	let resolution : CGSize

	init(_ simulate : [simulate_t], _ resolution : CGSize) {
		self.simulate = simulate
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		let state = state_b.value
		let shader = ShaderLibrary.draw_simulate(
			.float2(resolution),
			.float2(state.translation),
			.float(state.magnification),
			simulate_serialize_mass(simulate),
			simulate_serialize_position(simulate)
		)
		content.colorEffect(shader)
	}
}

private struct modifier_draw_select : ViewModifier {
	@Environment(\.state_b) private var state_b

	let resolution : CGSize

	init(_ resolution : CGSize) {
		self.resolution = resolution
	}

	func body(content : Content) -> some View {
		let state = state_b.value
		if let i = state.select {
			let body = state.bodies[i]
			let shader = ShaderLibrary.draw_select(
				.float2(resolution),
				.float2(state.translation),
				.float(state.magnification),
				.float(body.mass),
				.float2(body.position)
			)
			content.colorEffect(shader)
		} else {
			content
		}
	}
}

private struct modifier_overlay_fragments : ViewModifier {
	let visual : visual_t

	init(_ visual : visual_t) {
		self.visual = visual
	}

	func body(content : Content) -> some View {
		if let fragments = visual.fragments {
			content
				.overlay(VStack(spacing : -visual.overdraw) {
					ForEach(0 ..< fragments.count, id : \.self) { i in fragments[i] }
				})
				.clipped()
		} else {
			content
		}
	}
}
