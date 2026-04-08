import SwiftUI

struct visual_t : Equatable, destructurable {
	var display_scale : CGFloat
	var resolution : CGSize
	var fragment : Image?
}

func visual_update(_ old : state_t, _ new : state_t) -> Bool {
	if new.editor.in_motion {
		return false
	}
	if old.bodies != new.bodies {
		return true
	}
	if old.editor.in_motion && !new.editor.in_motion {
		return true
	}
	return false
}

func visual_resolution(_ old : visual_t, _ screen_display_scale : CGFloat, _ screen_resolution : CGSize) -> visual_t {
	(old)~>{ new in
		new.display_scale = screen_display_scale
		new.resolution = screen_resolution
	}
}

func visual_fragment(_ old : state_t) -> visual_t {
	(old.visual)~>{ new in
		let (display_scale, resolution) = (old)~>(\.visual.display_scale, \.visual.resolution)
		let shader = shader_visual(old)
		new.fragment = view_to_image(
			Rectangle()
				.frame(width : resolution.width, height : resolution.height)
				.colorEffect(shader),
			scale : display_scale
		)
	}
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
