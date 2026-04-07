import Combine
import SwiftUI

func dispatch(_ state : state_t, _ bus : bus_t, _ event : event_t) -> state_t {
	let result : state_t? = switch (event) {
//		case .log(let message):
//			process_log(message)

		case .resolution(let source, let display_scale, let resolution):
			process_resolution(state, bus, source, display_scale, resolution)

		case .single_tap(let source, let position, let resolution):
			process_single_tap(state, bus, source, position, resolution)

		case .double_tap(let source, let position, let resolution):
			process_double_tap(state, bus, source, position, resolution)

		case .drag_start(let source, let position, let resolution):
			process_drag_start(state, bus, source, position, resolution)

		case .drag(let source, let delta):
			process_drag(state, bus, source, delta)

		case .drag_end(let source):
			process_drag_end(state, bus, source)

		case .magnify(let source, let delta):
			process_magnify(state, bus, source, delta)

		case .magnify_end(let source):
			process_magnify_end(state, bus, source)

		case .simulate_remove:
			simulate_remove(state, bus)

		case .body_update(let mass, let red, let green, let blue):
			body_update(state, bus, mass, red, green, blue)

		case .body_update_done:
			body_update_done(state)
	}
	if var result {
		if let new = visual_update_check(state, result) {
			result = visual_update_fragments(new)
		}
		return result
	}
	return state
}

private func process_log(_ message : String) -> state_t? {
	print(message)
	return nil
}

private func process_resolution(_ state : state_t, _ bus : bus_t, _ source : source_t, _ display_scale : CGFloat, _ resolution : CGSize) -> state_t {
	var result = state
	if source == .visual {
		result = visual_update_resolution(result, display_scale, resolution)
	}
	return result
}

private func process_single_tap(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	var result = state
	let world_position = screen_to_world(position, resolution, state.camera)
	if source == .editor {
		let select = body_select(state, world_position)
		result.select = (select == result.select) ? nil : select
	}
	if source == .visual {
		let select = body_select(state, world_position)
		if select == nil {
			result = simulate_add(state, bus, world_position)
		}
		result.select = (select == result.select) ? nil : select
	}
	return result
}

private func process_double_tap(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	var result = state
	if source == .editor {
		let world_position = screen_to_world(position, resolution, state.camera)
		if let i = body_select(state, world_position) {
			result = body_remove(state, i)
			result.select = nil
		} else {
			result = body_add(state, world_position)
		}
	}
	return result
}

private func process_drag_start(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	var result = state
	if source == .editor {
		let world_position = screen_to_world(position, resolution, state.camera)
		result.in_motion = true
		result.select_drag = body_select(state, world_position)
	}
	return result
}

private func process_drag(_ state : state_t, _ bus : bus_t, _ source : source_t, _ delta : CGSize) -> state_t {
	var result = state
	if source == .editor {
		result.in_motion = true
		if let _ = state.select_drag {
			result = body_translate(state, delta)
		} else {
			result.camera = camera_translate(result.camera, delta)
		}
	}
	return result
}

private func process_drag_end(_ state : state_t, _ bus : bus_t, _ source : source_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}

private func process_magnify(_ state : state_t, _ bus : bus_t, _ source : source_t, _ delta : CGFloat) -> state_t {
	var result = state
	if source == .editor {
		result.in_motion = true
		result.camera = camera_magnify(result.camera, delta)
	}
	return result
}

private func process_magnify_end(_ state : state_t, _ bus : bus_t, _ source : source_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}
