import Combine
import SwiftUI

struct bus_t {
	private let subject = PassthroughSubject<event_t, Never>()

	func publish(_ event : event_t) {
		subject.send(event)
	}

	func publish_delayed(for duration : Duration, schedule : @escaping @Sendable () -> event_t) {
		Task {
			try? await Task.sleep(for : duration)
			publish(schedule())
		}
	}

	func subscribe() -> AnyPublisher<event_t, Never> {
		subject.eraseToAnyPublisher()
	}
}
