import Combine
import SwiftUI

func dispatch(_ state : state_t, _ bus : bus_t, _ event : event_t) -> state_t {
	let result : state_t? = switch (event) {
		case .resolution(let source, let display_scale, let resolution):
			process_resolution(state, source, display_scale, resolution)

		case .single_tap(let source, let position, let resolution):
			process_single_tap(state, bus, source, position, resolution)

		case .double_tap(let source, let position, let resolution):
			process_double_tap(state, source, position, resolution)

		case .drag_start(let source, let position, let resolution):
			process_drag_start(state, source, position, resolution)

		case .drag(let source, let delta):
			process_drag(state, source, delta)

		case .drag_end(let source):
			process_drag_end(state, source)

		case .magnify(let source, let delta):
			process_magnify(state, source, delta)

		case .magnify_end(let source):
			process_magnify_end(state, source)

		case .simulate_remove:
			simulate_remove(state, bus)

		case .body_modify(let mass, let color):
			process_body_modify(state, bus, mass, color)

		case .in_motion(let in_motion):
			process_in_motion(state, in_motion)
	}
	if var result {
		if let new = visual_update_check(state, result) {
			result = visual_update_fragments(new)
		}
		return result
	}
	return state
}

private func process_resolution(_ state : state_t, _ source : source_t, _ display_scale : CGFloat, _ resolution : CGSize) -> state_t {
	var result = state
	if source == .visual {
		result = visual_update_resolution(result, display_scale, resolution)
	}
	return result
}

private func process_single_tap(_ old : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	let world_position = screen_to_world(position, resolution, camera)
	let select = body_select(bodies, world_position)
	if source == .visual && select == nil {
		new = simulate_add(old, bus, world_position)
	} else {
		new.select = (select == old.select) ? nil : select
	}
	return new
}

private func process_double_tap(_ old : state_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	if source == .editor {
		let world_position = screen_to_world(position, resolution, camera)
		if let i = body_select(bodies, world_position) {
			new.bodies = body_remove(bodies, i)
			new.select = nil
		} else {
			new.bodies = body_add(bodies, world_position)
		}
	}
	return new
}

private func process_drag_start(_ old : state_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	if source == .editor {
		let world_position = screen_to_world(position, resolution, camera)
		new.in_motion = true
		new.select_drag = body_select(bodies, world_position)
	}
	return new
}

private func process_drag(_ old : state_t, _ source : source_t, _ delta : CGSize) -> state_t {
	let select = old.select
	let select_drag = old.select_drag
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	if source == .editor {
		new.in_motion = true
		if select_drag == nil {
			new.camera = camera_translate(camera, delta)
		} else {
			new.bodies = body_translate(bodies, select, delta, camera)
		}
	}
	return new
}

private func process_drag_end(_ state : state_t, _ source : source_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}

private func process_magnify(_ state : state_t, _ source : source_t, _ delta : CGFloat) -> state_t {
	var result = state
	if source == .editor {
		result.in_motion = true
		result.camera = camera_magnify(result.camera, delta)
	}
	return result
}

private func process_magnify_end(_ state : state_t, _ source : source_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}

private func process_body_modify(_ old : state_t, _ bus : bus_t, _ mass : Double, _ color : color_t) -> state_t {
	let select = old.select
	let bodies = old.bodies
	var new = old
	new.in_motion = true
	new.bodies = body_modify(bodies, select, mass, color)
	bus.publish_debounce(
		id : "in_motion",
		for : .nanoseconds(100_000_000),
		schedule : { .in_motion(false) }
	)
	return new
}

private func process_in_motion(_ old : state_t, _ in_motion : Bool) -> state_t {
	var new = old
	new.in_motion = in_motion
	return new
}
