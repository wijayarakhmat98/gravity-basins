import SwiftUI

struct color_t : Equatable {
	var red : Double
	var green : Double
	var blue : Double
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
		display_scale : 1,
		resolution : .zero,
		fragment : nil
	)
)
