import SwiftUI

struct visual_t : Equatable {
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
	var new = old
	new.display_scale = screen_display_scale
	new.resolution = screen_resolution
	return new
}

func visual_fragment(_ editor : editor_t, _ bodies : [body_t], _ simulation : simulation_t, _ camera : camera_t, _ visual : visual_t) -> visual_t {
	let shader = shader_visual(editor, bodies, simulation, camera, visual)
	var new = visual
	new.fragment = view_to_image(
		Rectangle()
			.frame(width : visual.resolution.width, height : visual.resolution.height)
			.colorEffect(shader),
		scale : visual.display_scale
	)
	return new
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
