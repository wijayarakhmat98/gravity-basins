import SwiftUI

struct body_t : Equatable, destructurable {
	var timestamp = Date.now
	var position : CGPoint
	var mass : Double
	var color : color_t
}

func body_select(_ bodies : [body_t], _ position : CGPoint) -> Int? {
	var nearest_r : Double = .infinity
	var nearest_i : Int? = nil
	for (i, body) in bodies.enumerated()  {
		let r = hypot(body.position.x - position.x, body.position.y - position.y)
		if r < nearest_r {
			nearest_r = r
			if r < body.mass {
				nearest_i = i
			}
		}
	}
	return nearest_i
}

func body_add(_ old : [body_t], _ position : CGPoint) -> [body_t] {
	(old)~>{ new in
		new.append(body_t(
			position : position,
			mass : 5,
			color : color_t(.random(in : 0..<1), .random(in : 0..<1), .random(in : 0..<1))
		))
	}
}

func body_remove(_ old : [body_t], _ i : Int?) -> [body_t] {
	guard let i else {
		return old
	}
	return (old)~>{ new in
		new.remove(at : i)
	}
}

func body_translate(_ old : [body_t], _ i : Int?, _ delta : CGSize, _ camera : camera_t) -> [body_t] {
	guard let i else {
		return old
	}
	return (old)~>{ new in
		new[i].position.x += delta.width / camera.magnification
		new[i].position.y -= delta.height / camera.magnification
	}
}

func body_modify(_ old : [body_t], _ i : Int?, _ mass : Double, _ color : color_t) -> [body_t] {
	guard let i else {
		return old
	}
	return (old)~>{ new in
		new[i].mass = mass
		new[i].color = color
	}
}
