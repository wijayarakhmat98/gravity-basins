import SwiftUI

struct visual_t : Equatable {
	var display_scale : CGFloat
	var resolution : CGSize
	var fragment : Image?
}

func visual_update_check(_ old : state_t, _ new : state_t) -> state_t? {
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

func visual_update_resolution(_ state : state_t, _ display_scale : CGFloat, _ resolution : CGSize) -> state_t {
	var result = state
	result.visual.display_scale = display_scale
	result.visual.resolution = resolution
	return result
}

func visual_update_fragments(_ state : state_t) -> state_t {
	var result = state
	let visual = state.visual
	let shader = shader_visual(state)
	result.visual.fragment = view_to_image(
		Rectangle()
			.frame(width : visual.resolution.width, height : visual.resolution.height)
			.colorEffect(shader),
		scale : visual.display_scale
	)
	return result
}

@MainActor
private func view_to_image(_ view : some View, scale : CGFloat = 1) -> Image? {
	let renderer = ImageRenderer(content : view)

	renderer.scale = scale

	if let nsImage = renderer.nsImage {
		return Image(nsImage : nsImage)
	}

	return nil
}
