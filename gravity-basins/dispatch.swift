import Combine
import SwiftUI

func dispatch(_ state : state_t, _ bus : bus_t, _ event : event_t) -> state_t {
	let result : state_t? = switch (event) {
		case .log(let message):
			process_log(message)

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
		if result.in_motion || state.in_motion {
			bus.publish(.log("in_motion? \(result.in_motion)"))
		}
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
	bus.publish(.log("display_scale: \(display_scale), resolution: \(resolution)"))
	var result = state
	if source == .visual {
		result = visual_update_resolution(result, display_scale, resolution)
	}
	return result
}

private func process_single_tap(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	bus.publish(.log("single_tap, source: \(source), position: \(position), resolution: \(resolution)"))
	var result = state
	let world_position = screen_to_world(position, resolution, state.translation, state.magnification)
	if source == .editor {
		let select = body_select(state, world_position)
		result.select = (select == result.select) ? nil : select
	}
	if source == .visual {
		let select = body_select(state, world_position)
		if select == nil {
			result = simulate_add(state, bus, world_position)
			bus.publish(.log("simulate: \(result.simulate)"))
		}
		result.select = (select == result.select) ? nil : select
	}
	return result
}

private func process_double_tap(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	bus.publish(.log("double_tap, source: \(source), position: \(position), resolution: \(resolution)"))
	var result = state
	if source == .editor {
		let world_position = screen_to_world(position, resolution, state.translation, state.magnification)
		if let i = body_select(state, world_position) {
			result = body_remove(state, i)
			result.select = nil
		} else {
			result = body_add(state, world_position)
		}
		bus.publish(.log("bodies: \(result.bodies)"))
	}
	return result
}

private func process_drag_start(_ state : state_t, _ bus : bus_t, _ source : source_t, _ position : CGPoint, _ resolution : CGSize) -> state_t {
	bus.publish(.log("drag_start, source: \(source), position: \(position)"))
	var result = state
	if source == .editor {
		let world_position = screen_to_world(position, resolution, state.translation, state.magnification)
		result.in_motion = true
		result.select_drag = body_select(state, world_position)
	}
	return result
}

private func process_drag(_ state : state_t, _ bus : bus_t, _ source : source_t, _ delta : CGSize) -> state_t {
	var result = state
	bus.publish(.log("drag, source: \(source), delta: \(delta)"))
	if source == .editor {
		result.in_motion = true
		if let _ = state.select_drag {
			result = body_translate(state, delta)
		} else {
			result = update_translation(result, delta)
		}
		bus.publish(.log("translation: \(result.translation)"))
	}
	return result
}

private func process_drag_end(_ state : state_t, _ bus : bus_t, _ source : source_t) -> state_t {
	bus.publish(.log("drag_end, source: \(source)"))
	var result = state
	result.in_motion = false
	return result
}

private func process_magnify(_ state : state_t, _ bus : bus_t, _ source : source_t, _ delta : CGFloat) -> state_t {
	bus.publish(.log("magnify, source: \(source), delta: \(delta)"))
	var result = state
	if source == .editor {
		result.in_motion = true
		result = update_magnification(result, delta)
		bus.publish(.log("magnification: \(result.magnification)"))
	}
	return result
}

private func process_magnify_end(_ state : state_t, _ bus : bus_t, _ source : source_t) -> state_t {
	bus.publish(.log("magnify_end, source: \(source)"))
	var result = state
	result.in_motion = false
	return result
}
