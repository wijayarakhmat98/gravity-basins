import SwiftUI

struct editor_t : Equatable {
	let magnification_min : CGFloat
	let magnification_max : CGFloat

	let mass_min : Double
	let mass_max : Double
	let mass : Double
	let color : color_t

	var select : Int?
	var select_drag : Int?
	var in_motion : Bool
}
