import SwiftUI

struct camera_t : Equatable, destructurable {
	var translation : CGPoint
	var magnification : CGFloat
}

func camera_translate(_ old : camera_t, _ delta : CGSize) -> camera_t {
	(old)~>{ new in
		new.translation.x -= delta.width
		new.translation.y += delta.height
	}
}

func camera_magnify(_ old : camera_t, _ delta : CGFloat, _ editor : editor_t) -> camera_t {
	if delta.isNaN {
		return old
	}
	return (old)~>{ new in
		let magnification_min = editor.magnification_min
		let magnification_max = editor.magnification_max
		new.translation.x *= 2 - 1 / delta
		new.translation.y *= 2 - 1 / delta
		new.magnification *= delta
		if new.magnification < magnification_min || new.magnification > magnification_max {
			new = old
		}
	}
}

func screen_to_world(_ screen_position : CGPoint, _ screen_resolution : CGSize, _ camera : camera_t) -> CGPoint {
	CGPoint(
		x : (camera.translation.x - screen_resolution.width  / 2 + screen_position.x) / camera.magnification,
		y : (camera.translation.y + screen_resolution.height / 2 - screen_position.y) / camera.magnification
	)
}

func world_to_screen(_ world_position : CGPoint, _ screen_resolution : CGSize, _ camera : camera_t) -> CGPoint {
	CGPoint(
		x : screen_resolution.width  / 2 - camera.translation.x + world_position.x * camera.magnification,
		y : screen_resolution.height / 2 + camera.translation.y - world_position.y * camera.magnification
	)
}
