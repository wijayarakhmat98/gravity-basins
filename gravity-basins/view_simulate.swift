import SwiftUI

struct view_simulate : View {
	@Bindable var store : store_t

	@State var resolution : CGSize = .zero
	@State var translation : CGSize = .zero
	@State var magnification : CGFloat = 1.0

	var body : some View {
		TimelineView(.animation) { tl in
			store.bus.publish(.simulate_remove)

			var body = store.state.body

			if (store.state.simulate != nil) {
				let simulate = store.state.simulate!

				let simulate_scale = store.state.simulate_scale
				let elapsed = Float(simulate.start.distance(to : tl.date)) * simulate_scale
				var position_x = Float(simulate.position.x)
				var position_y = Float(simulate.position.y)
				var velocity_x : Float = 0.0
				var velocity_y : Float = 0.0

				let dt = store.state.dt
				let epsilon = store.state.epsilon

				for _ in stride(from : 0, to : elapsed, by : dt) {
					var force_sum_x : Float = 0
					var force_sum_y : Float = 0

					for b in body {
						let dx = Float(b.position.x) - position_x
						let dy = Float(b.position.y) - position_y
						let r = Float(hypot(dx, dy))
						let f = 1.0 / (r * r + epsilon)
						let force_x = f * (dx / r)
						let force_y = f * (dy / r)
						force_sum_x += force_x
						force_sum_y += force_y
					}

//					let speed = hypot(velocity_x, velocity_y)
//					let force_drag_x = epsilon * speed * velocity_x
//					let force_drag_y = epsilon * speed * velocity_y
//					force_sum_x -= force_drag_x
//					force_sum_y -= force_drag_y

					let acceleration_x = force_sum_x
					let acceleration_y = force_sum_y
					velocity_x += acceleration_x * dt
					velocity_y += acceleration_y * dt

					position_x += velocity_x * dt
					position_y += velocity_y * dt
				}

				body.append(body_t(
					position : CGPoint(x : Double(position_x), y : Double(position_y)),
					color : .white
				))
			}
			return Rectangle().fill(.black)
				.onGeometryChange(
					for : CGSize.self,
					of : { proxy in proxy.size },
					action : { size in resolution = size }
				)
				.colorEffect(ShaderLibrary.simulate(
					.float2(resolution),
					.float2(store.state.origin),
					.float(store.state.scale),
					serialize_position(body),
					serialize_color(body)
				))
				.gesture(SpatialTapGesture(count : 2).onEnded { event in
					store.bus.publish(.double_click_gravity(event.location, resolution))
				})
				.gesture(SpatialTapGesture().onEnded { event in
					store.bus.publish(.click_gravity(event.location, resolution))
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
}

#Preview {
	view_simulate(store : store_preview())
}
