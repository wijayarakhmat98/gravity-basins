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
			let editor = state.editor
			if let i = editor.select {
				let (m, r, g, b) = (state.bodies[i])~>(\.mass, \.color.red, \.color.green, \.color.blue)
				let (min, max) = (state.editor)~>(\.mass_min, \.mass_max)
				Spacer(minLength : 32)
				Text("Mass:")
				Slider(value : Binding( get : { m }, set : { m in bus.publish(.body_modify(m, color_t(r, g, b))) }), in : min...max)
				Spacer(minLength : 32)
				Text("Red:")
				Slider(value : Binding( get : { r }, set : { r in bus.publish(.body_modify(m, color_t(r, g, b))) }), in : 0...1)
				Spacer(minLength : 32)
				Text("Green:")
				Slider(value : Binding( get : { g }, set : { g in bus.publish(.body_modify(m, color_t(r, g, b))) }), in : 0...1)
				Spacer(minLength : 32)
				Text("Blue:")
				Slider(value : Binding( get : { b }, set : { b in bus.publish(.body_modify(m, color_t(r, g, b))) }), in : 0...1)
				Spacer(minLength : 32)
			}
		}
	}
}

private struct view_editor : View {
	@Environment(\.state_b) private var state_b

	@State private var screen_resolution : CGSize = .zero

	var body : some View {
		let state = state_b.value
		let editor = state.editor
		let select = editor.select
		let bodies = state.bodies
		let camera = state.camera
		Rectangle()
			.fill(.black)
			.track_resolution(to : $screen_resolution)
			.publish_double_tap(from : .editor, with : screen_resolution)
			.publish_single_tap(from : .editor, with : screen_resolution)
			.publish_drag(from : .editor, with : screen_resolution)
			.publish_magnify(from : .editor)
			.apply_shader(shader_draw_bodies(bodies, camera, screen_resolution))
			.apply_shader(shader_draw_select(bodies, camera, screen_resolution, select))
	}
}

private struct view_simulate : View {
	@Environment(\.state_b) private var state_b

	@State private var screen_resolution : CGSize = .zero

	var body : some View {
		TimelineView(.animation) { tl in
			let state = state_b.value
			let editor = state.editor
			let select = editor.select
			let bodies = state.bodies
			let camera = state.camera
			let elements = simulate_elements(state.elements, state.bodies, state.simulation)
			Rectangle()
				.fill(.black)
				.track_resolution(to : $screen_resolution)
				.publish_double_tap(from : .editor, with : screen_resolution)
				.publish_single_tap(from : .editor, with : screen_resolution)
				.publish_drag(from : .editor, with : screen_resolution)
				.publish_magnify(from : .editor)
				.apply_shader(shader_draw_bodies(bodies, camera, screen_resolution))
				.apply_shader(shader_draw_select(bodies, camera, screen_resolution, select))
				.apply_shader(shader_draw_bodies(elements, camera, screen_resolution))
		}
	}
}

private struct view_visual : View {
	@Environment(\.state_b) private var state_b

	@State private var screen_resolution : CGSize = .zero

	var body : some View {
		Rectangle()
			.fill(.black)
			.track_resolution(to : $screen_resolution, publish : .visual)
			.overlay_fragment(state_b.value.visual)
			.publish_double_tap(from : .visual, with : screen_resolution)
			.publish_single_tap(from : .visual, with : screen_resolution)
	}
}
