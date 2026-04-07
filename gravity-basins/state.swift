import SwiftUI

struct state_t : Equatable {
	let mass_min : Double
		let mass_max : Double

	var bodies : [body_t]
	var elements : [body_t]

	var select : Int?
	var select_drag : Int?

	var in_motion : Bool

	var simulation : simulation_t
	var camera : camera_t
	var visual : visual_t
}

let state_default = state_t(
	mass_min : 1,
	mass_max : 48,

	bodies : [
		body_t(mass : 5, position : CGPoint(x : 0, y :  25), color : color_t(1, 0, 0)),
		body_t(mass : 5, position : CGPoint(x : 0, y : -25), color : color_t(0, 1, 1))
	],
	elements : [],

	select : nil,
	select_drag : nil,

	in_motion : false,

	simulation : simulation_t(
		duration : 1000,
		dt : 0.2,
		epsilon : 0.4,
		speed : 50,
		mass : 2
	),

	camera : camera_t(
		magnification_min : 0.001,
		magnification_max : 1000,

		translation : CGPoint(x : 0, y : 0),
		magnification : 5,
	),

	visual : visual_t(
		display_scale : 1,
		resolution : .zero,
		fragment : nil
	)
)
