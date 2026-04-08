import Combine
import SwiftUI

func dispatch(_ old : state_t, _ bus : bus_t, _ event : event_t) -> state_t {
	var new = switch (event) {
		case .in_motion(let in_motion):
			process_in_motion(old, in_motion)

		case .screen_resolution(let source, let screen_display_scale, let screen_resolution):
			process_screen_resolution(old, bus, source, screen_display_scale, screen_resolution)

		case .single_tap(let source, let screen_position, let screen_resolution):
			process_single_tap(old, bus, source, screen_position, screen_resolution)

		case .double_tap(_, let screen_position, let screen_resolution):
			process_double_tap(old, screen_position, screen_resolution)

		case .drag_start(let source, let screen_position, let screen_resolution):
			process_drag_start(old, source, screen_position, screen_resolution)

		case .drag(let source, let delta):
			process_drag(old, source, delta)

		case .drag_end(let source):
			process_drag_end(old, source)

		case .magnify(let source, let delta):
			process_magnify(old, source, delta)

		case .magnify_end(let source):
			process_magnify_end(old, source)

		case .body_modify(let mass, let color):
			process_body_modify(old, bus, mass, color)

		case .element_remove:
			process_element_remove(old)
	}
	if visual_update(old, new) {
		new = process_visual_update(new)
	}
	return new
}

private func process_in_motion(_ old : state_t, _ in_motion : Bool) -> state_t {
	var new = old
	new.editor.in_motion = in_motion
	return new
}

private func process_screen_resolution(_ old : state_t, _ bus : bus_t, _ source : source_t, _ screen_display_scale : CGFloat, _ screen_resolution : CGSize) -> state_t {
	let editor = old.editor
	let visual = old.visual
	var new = old
	if source == .visual {
		new.editor.in_motion = true
		new.visual = visual_resolution(visual, screen_display_scale, screen_resolution)
		bus.publish_debounce(
			id : "in_motion",
			for : editor.debounce_duration,
			schedule : { .in_motion(false) }
		)
	}
	return new
}

private func process_single_tap(_ old : state_t, _ bus : bus_t, _ source : source_t, _ screen_position : CGPoint, _ screen_resolution : CGSize) -> state_t {
	let editor = old.editor
	let elements = old.elements
	let simulation = old.simulation
	let bodies = old.bodies
	let camera = old.camera
	let world_position = screen_to_world(screen_position, screen_resolution, camera)
	let select = body_select(bodies, world_position)
	var new = old
	if source == .visual && select == nil {
		let delay = Duration.seconds(simulation.duration / simulation.speed)
		new.elements = element_add(elements, editor, world_position)
		bus.publish_delayed(for : delay, schedule : { .element_remove })
	} else {
		new.editor.select = (select == editor.select) ? nil : select
	}
	return new
}

private func process_double_tap(_ old : state_t, _ screen_position : CGPoint, _ screen_resolution : CGSize) -> state_t {
	let bodies = old.bodies
	let camera = old.camera
	let world_position = screen_to_world(screen_position, screen_resolution, camera)
	var new = old
	if let i = body_select(bodies, world_position) {
		new.bodies = body_remove(bodies, i)
		new.editor.select = nil
	} else {
		new.bodies = body_add(bodies, world_position)
	}
	return new
}

private func process_drag_start(_ old : state_t, _ source : source_t, _ screen_position : CGPoint, _ screen_resolution : CGSize) -> state_t {
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	if source == .editor {
		let world_position = screen_to_world(screen_position, screen_resolution, camera)
		new.editor.in_motion = true
		new.editor.select_drag = body_select(bodies, world_position)
	}
	return new
}

private func process_drag(_ old : state_t, _ source : source_t, _ delta : CGSize) -> state_t {
	let editor = old.editor
	let select_drag = editor.select_drag
	let bodies = old.bodies
	let camera = old.camera
	var new = old
	if source == .editor {
		new.editor.in_motion = true
		if select_drag == nil {
			new.camera = camera_translate(camera, delta)
		} else {
			new.bodies = body_translate(bodies, select_drag, delta, camera)
		}
	}
	return new
}

private func process_drag_end(_ old : state_t, _ source : source_t) -> state_t {
	var new = old
	new.editor.in_motion = false
	return new
}

private func process_magnify(_ old : state_t, _ source : source_t, _ delta : CGFloat) -> state_t {
	let editor = old.editor
	let camera = old.camera
	var new = old
	if source == .editor {
		new.editor.in_motion = true
		new.camera = camera_magnify(camera, delta, editor)
	}
	return new
}

private func process_magnify_end(_ old : state_t, _ source : source_t) -> state_t {
	var new = old
	new.editor.in_motion = false
	return new
}

private func process_body_modify(_ old : state_t, _ bus : bus_t, _ mass : Double, _ color : color_t) -> state_t {
	let editor = old.editor
	let select = editor.select
	let bodies = old.bodies
	var new = old
	new.editor.in_motion = true
	new.bodies = body_modify(bodies, select, mass, color)
	bus.publish_debounce(
		id : "in_motion",
		for : editor.debounce_duration,
		schedule : { .in_motion(false) }
	)
	return new
}

private func process_element_remove(_ old : state_t) -> state_t {
	let elements = old.elements
	let simulation = old.simulation
	var new = old
	new.elements = element_remove(elements, simulation)
	return new
}

private func process_visual_update(_ old : state_t) -> state_t {
	var new = old
	let editor = new.editor
	let bodies = new.bodies
	let simulation = new.simulation
	let camera = new.camera
	let visual = new.visual
	new.visual = visual_fragment(editor, bodies, simulation, camera, visual)
	return new
}
