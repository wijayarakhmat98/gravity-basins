import SwiftUI

@MainActor
func view_to_image(_ view : some View, scale : CGFloat = 1) -> Image? {
	let renderer = ImageRenderer(content : view)

	renderer.scale = scale

	if let nsImage = renderer.nsImage {
		return Image(nsImage : nsImage)
	}

	return nil
}

func visual_fragments_create(_ visual : visual_t, _ translation : CGPoint, _ shader : (CGSize, CGPoint) -> Shader) -> [Image]? {
	let division = visual.division
	let display_scale = visual.display_scale

	let width = visual.resolution.width
	let height = visual.resolution.height

	let height_fragment = height / CGFloat(division)

	var fragments : [Image] = []

	for i in 0 ..< division {
		let shift_x = translation.x
		let shift_y = translation.y + (height - height_fragment) / 2 - CGFloat(i) * height_fragment

		if let fragment = view_to_image(
			Rectangle()
				.fill(.black)
				.frame(width : width, height : height_fragment)
				.colorEffect(shader(
					CGSize(width : width, height : height_fragment),
					CGPoint(x : shift_x, y : shift_y)
				)),
			scale : display_scale
		) {
			fragments.append(fragment)
		} else {
			return nil
		}
	}

	return fragments
}
