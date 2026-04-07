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
