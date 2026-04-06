import SwiftUI

struct view_basin : View {
	@Bindable var store : store_t

	@State var resolution : CGSize = .zero
	@State var translation : CGSize = .zero
	@State var magnification : CGFloat = 1.0

	var body : some View {
		Rectangle().fill(.black)
			.onGeometryChange(
				for : CGSize.self,
				of : { proxy in proxy.size },
				action : { size in resolution = size }
			)
			.colorEffect(ShaderLibrary.basins(
				.float2(resolution),
				.float2(store.state.origin),
				.float(store.state.scale),
				serialize_position(store.state.body),
				serialize_color(store.state.body),
				.float(store.state.duration),
				.float(store.state.dt),
				.float(store.state.epsilon)
			))
			.gesture(SpatialTapGesture().onEnded { event in
				store.bus.publish(.click_basin(event.location, resolution))
			})
			.gesture(DragGesture()
				.onChanged { event in
					let delta = CGSize(
						width : event.translation.width - translation.width,
						height : event.translation.height - translation.height
					)
					translation = event.translation
					store.bus.publish(.drag(delta))
				}
				.onEnded { _ in translation = .zero }
			)
			.gesture(MagnifyGesture()
				.onChanged { event in
					let delta = event.magnification / magnification
					store.bus.publish(.zoom(delta))
					magnification = event.magnification
				}
				.onEnded { _ in magnification = 1.0 }
			)
	}
}

#Preview {
	view_basin(store : store_preview())
}
