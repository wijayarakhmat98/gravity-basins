import SwiftUI

struct camera_t : Equatable {
	var translation : CGPoint
	var magnification : CGFloat
}

func camera_translate(_ old : camera_t, _ delta : CGSize) -> camera_t {
	var new = old
	new.translation.x -= delta.width
	new.translation.y += delta.height
	return new
}

func camera_magnify(_ old : camera_t, _ delta : CGFloat, _ editor : editor_t) -> camera_t {
	if delta.isNaN {
		return old
	}
	let magnification_min = editor.magnification_min
	let magnification_max = editor.magnification_max
	var new = old
	new.translation.x *= 2 - 1 / delta
	new.translation.y *= 2 - 1 / delta
	new.magnification *= delta
	if new.magnification < magnification_min || new.magnification > magnification_max {
		new = old
	}
	return new
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
