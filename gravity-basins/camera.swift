import SwiftUI

func update_translation(_ state : state_t, _ delta : CGSize) -> state_t {
	var result = state
	result.translation.x -= delta.width
	result.translation.y += delta.height
	return result
}

func update_magnification(_ state : state_t, _ delta : CGFloat) -> state_t {
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

func screen_to_world(_ position : CGPoint, _ resolution : CGSize, _ translation : CGPoint, _ magnification : CGFloat) -> CGPoint {
	let x = (translation.x - resolution.width  / 2 + position.x) / magnification
	let y = (translation.y + resolution.height / 2 - position.y) / magnification
	return CGPoint(x : x, y : y)
}

func world_to_screen(_ position : CGPoint, _ resolution : CGSize, _ translation : CGPoint, _ magnification : CGFloat) -> CGPoint {
	let x = resolution.width  / 2 - translation.x + position.x * magnification
	let y = resolution.height / 2 + translation.y - position.y * magnification
	return CGPoint(x : x, y : y)
}
