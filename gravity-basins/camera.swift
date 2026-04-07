import SwiftUI

struct camera_t : Equatable {
	let magnification_min : CGFloat
	let magnification_max : CGFloat

	var translation : CGPoint
	var magnification : CGFloat
}

func update_translation(_ state : state_t, _ delta : CGSize) -> state_t {
	var result = state
	result.camera.translation.x -= delta.width
	result.camera.translation.y += delta.height
	return result
}

func update_magnification(_ state : state_t, _ delta : CGFloat) -> state_t {
	var result = state
	if !delta.isNaN {
		result.camera.translation.x *= 2 - 1 / delta
		result.camera.translation.y *= 2 - 1 / delta
		result.camera.magnification *= delta
		if result.camera.magnification < state.camera.magnification_min || result.camera.magnification > state.camera.magnification_max {
			result = state
		}
	}
	return result
}

func screen_to_world(_ position : CGPoint, _ resolution : CGSize, _ camera : camera_t) -> CGPoint {
	let translation = camera.translation
	let magnification = camera.magnification
	let x = (translation.x - resolution.width  / 2 + position.x) / magnification
	let y = (translation.y + resolution.height / 2 - position.y) / magnification
	return CGPoint(x : x, y : y)
}

func world_to_screen(_ position : CGPoint, _ resolution : CGSize, _ camera : camera_t) -> CGPoint {
	let translation = camera.translation
	let magnification = camera.magnification
	let x = resolution.width  / 2 - translation.x + position.x * magnification
	let y = resolution.height / 2 + translation.y - position.y * magnification
	return CGPoint(x : x, y : y)
}
