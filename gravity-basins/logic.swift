import Combine
import SwiftUI

@Observable
final class box<T> {
	var value : T
	init(_ value : T) { self.value = value }
}

struct color_t : Equatable {
	var red : Double
	var green : Double
	var blue : Double
}

struct body_t : Equatable {
	var mass : Double
	var position : CGPoint
	var color : color_t
}

struct simulate_t : Equatable {
	var timestamp : Date
	var mass : Double
	var position : CGPoint
}

struct visual_t : Equatable {
	let division : Int
	let overdraw : CGFloat
	var display_scale : CGFloat
	var resolution : CGSize
	var fragments : [Image]?
}

struct state_t : Equatable {
	let duration : Double
	let dt : Double
	let epsilon : Double

	let mass_min : Double
	let mass_max : Double
	var body_task : Task<Void, Never>?

	var bodies : [body_t]

	var select : Int?
	var select_drag : Int?

	let speed : Double
	var mass : Double
	var simulate : [simulate_t]

	let magnification_min : CGFloat
	let magnification_max : CGFloat

	var in_motion : Bool
	var translation : CGPoint
	var magnification : CGFloat

	var visual : visual_t
}

let state_default = state_t(
	duration : 1000,
	dt : 0.2,
	epsilon : 0.4,

	mass_min : 1,
	mass_max : 48,
	body_task : nil,

	bodies : [
		body_t(mass : 5, position : CGPoint(x : 0, y :  25), color : color_t(red : 1, green : 0, blue : 0)),
		body_t(mass : 5, position : CGPoint(x : 0, y : -25), color : color_t(red : 0, green : 1, blue : 1))
	],

	select : nil,
	select_drag : nil,

	speed : 50,
	mass : 2,
	simulate : [],

	magnification_min : 0.001,
	magnification_max : 1000,

	in_motion : false,
	translation : CGPoint(x : 0, y : 0),
	magnification : 5,

	visual : visual_t(
		division : 24,
		overdraw : 1,
		display_scale : 1,
		resolution : .zero,
		fragments : nil
	)
)

enum source_t {
	case editor
	case visual
}

enum event_t {
	case log(_ message : String)
	case resolution(_ source : source_t, _ display_scale : CGFloat, _ resolution : CGSize)
	case single_tap(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case double_tap(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case drag_start(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case drag(_ source : source_t, _ delta : CGSize)
	case drag_end(_ source : source_t)
	case magnify(_ source : source_t, _ delta : CGFloat)
	case magnify_end(_ source : source_t)
	case simulate_remove
	case body_update(_ mass : Double, _ red : Double, _ green : Double, _ blue : Double)
	case body_update_done
}

@Observable
class bus_t {
	private let subject = PassthroughSubject<event_t, Never>()

	func subscribe() -> AnyPublisher<event_t, Never> {
		subject.eraseToAnyPublisher()
	}

	func publish(_ event : event_t) {
		subject.send(event)
	}

	func publish_delayed(for duration : Duration, schedule : @escaping @Sendable () -> event_t) {
		Task {
			try? await Task.sleep(for : duration)
			publish(schedule())
		}
	}
}

class controller_t {
	let state_b : box<state_t>
	let bus : bus_t

	private var cancellable = Set<AnyCancellable>()

	init(_ state_b : box<state_t>, _ bus : bus_t) {
		self.state_b = state_b
		self.bus = bus

		bus.subscribe()
			.sink { event in
				let result = dispatch(state_b.value, bus, event)
				if state_b.value != result {
					state_b.value = result
				}
			}
			.store(in : &cancellable)
	}
}

func body_serialize_mass(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.map {body in Float(body.mass) })
}

func body_serialize_position(_ bodies : [body_t]) -> Shader.Argument {
	return .floatArray(bodies.flatMap {body in [Float(body.position.x), Float(body.position.y)] })
}

func body_serialize_color(_ bodies : [body_t]) -> Shader.Argument {
	return .colorArray(bodies.map {body in
		let color = body.color
		return Color(red : color.red, green : color.green, blue : color.blue)
	})
}

private func body_select(_ state : state_t, _ position : CGPoint) -> Int? {
	var nearest_r : Double = .infinity
	var nearest_i : Int = -1
	var in_body = false
	for i in stride(from : 0, to : state.bodies.count, by : 1)  {
		let body = state.bodies[i]
		let dx = body.position.x - position.x
		let dy = body.position.y - position.y
		let r = hypot(dx, dy)
		if r < nearest_r {
			nearest_r = r
			nearest_i = i
			if r < body.mass {
				in_body = true
			}
		}
	}
	return in_body ? nearest_i : nil
}

private func body_add(_ state : state_t, _ position : CGPoint) -> state_t {
	var result = state
	result.bodies.append(body_t(
		mass : 5,
		position : position,
		color : color_t(red : .random(in : 0..<1), green : .random(in : 0..<1), blue : .random(in : 0..<1))
	))
	return result
}

private func body_remove(_ state : state_t, _ i : Int) -> state_t {
	var result = state
	result.bodies.remove(at : i)
	return result
}

private func body_translate(_ state : state_t, _ delta : CGSize) -> state_t {
	var result = state
	if let i = state.select_drag {
		var body = state.bodies[i]
		body.position.x += delta.width / state.magnification
		body.position.y -= delta.height / state.magnification
		result.bodies[i] = body
	}
	return result
}

private func body_update(_ state : state_t, _ bus : bus_t, _ mass : Double, _ red : Double, _ green : Double, _ blue : Double) -> state_t {
	var result = state
	if let i = state.select {
		var body = state.bodies[i]
		body.mass = mass
		body.color.red = red
		body.color.green = green
		body.color.blue = blue
		result.bodies[i] = body
	}
	result.in_motion = true
	result.body_task?.cancel()
	result.body_task = Task {
		try? await Task.sleep(nanoseconds : 100_000_000)
		if !Task.isCancelled {
			bus.publish(.body_update_done)
		}
	}
	return result
}

private func body_update_done(_ state : state_t) -> state_t {
	var result = state
	result.in_motion = false
	return result
}

func simulate_serialize_timestamp(_ simulate : [simulate_t]) -> Shader.Argument {
	let now = Date.now
	return .floatArray(simulate.map {s in Float(s.timestamp.distance(to : now)) })
}

func simulate_serialize_mass(_ simulate : [simulate_t]) -> Shader.Argument {
	return .floatArray(simulate.map {s in Float(s.mass) })
}

func simulate_serialize_position(_ simulate : [simulate_t]) -> Shader.Argument {
	return .floatArray(simulate.flatMap {s in [Float(s.position.x), Float(s.position.y)] })
}

private func simulate_add(_ state : state_t, _ bus : bus_t, _ position : CGPoint) -> state_t {
	var result = state
	let delay = Duration.seconds(state.duration / state.speed)
	result.simulate.append(simulate_t(
		timestamp : Date.now,
		mass : state.mass,
		position : position
	))
	bus.publish_delayed(for : delay, schedule : { .simulate_remove })
	return result
}

private func simulate_remove(_ state : state_t, _ bus : bus_t) -> state_t {
	var result = state
	let now = Date.now
	let delay = state.duration / state.speed
	result.simulate = result.simulate.filter { s in
		let elapsed = s.timestamp.distance(to : now)
		return elapsed < delay
	}
	bus.publish(.log("simulate: \(result.simulate)"))
	return result
}

private func update_translation(_ state : state_t, _ delta : CGSize) -> state_t {
	var result = state
	result.translation.x -= delta.width
	result.translation.y += delta.height
	return result
}

private func update_magnification(_ state : state_t, _ delta : CGFloat) -> state_t {
	var result = state
	if !delta.isNaN {
		result.translation.x *= 2 - 1 / delta
		result.translation.y *= 2 - 1 / delta
		result.magnification *= delta
		if result.magnification < state.magnification_min || result.magnification > state.magnification_max {
			result = state
		}
	}
	return result
}

private func visual_update_check(_ old : state_t, _ new : state_t) -> state_t? {
	if new.in_motion {
		return nil
	}
	if old.bodies != new.bodies {
		return new
	}
	if old.mass != new.mass {
	 	return new
	}
	if old.in_motion && !new.in_motion {
	 	return new
	}
	if old.visual.resolution != new.visual.resolution {
		return new
	}
	return nil
}

private func visual_update_resolution(_ state : state_t, _ display_scale : CGFloat, _ resolution : CGSize) -> state_t {
	var result = state
	result.visual.display_scale = display_scale
	result.visual.resolution = resolution
	return result
}

private func visual_update_fragments(_ state : state_t) -> state_t {
	var result = state
	let shader = { (_ resolution : CGSize, _ translation : CGPoint) in
		ShaderLibrary.visual(
			.float2(resolution),
			.float2(translation),
			.float(state.magnification),
			body_serialize_mass(state.bodies),
			body_serialize_position(state.bodies),
			body_serialize_color(state.bodies),
			.float(state.duration),
			.float(state.dt),
			.float(state.epsilon),
			.float(state.mass)
		)
	}
	result.visual.fragments = visual_fragments_create(state.visual, state.translation, shader)
	return result
}

private func dispatch(_ state : state_t, _ bus : bus_t, _ event : event_t) -> state_t {
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
