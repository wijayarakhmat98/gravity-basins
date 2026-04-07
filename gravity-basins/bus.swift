import Combine
import SwiftUI

@Observable
class bus_t {
	private let subject = PassthroughSubject<event_t, Never>()
	private var debounce : [String : Task<Void, Never>] = [:]

	func subscribe() -> AnyPublisher<event_t, Never> {
		subject.eraseToAnyPublisher()
	}

	func publish(_ event : event_t) {
		subject.send(event)
	}

	func publish_delayed(for duration : Duration, schedule : @escaping @Sendable () -> event_t) {
		Task {
			try? await Task.sleep(for : duration)
			publish(schedule())
		}
	}

	func publish_debounce(id : String, for duration : Duration, schedule : @escaping @Sendable () -> event_t) {
		debounce[id]?.cancel()
		debounce[id] = Task {
			try? await Task.sleep(for : duration)
			if !Task.isCancelled {
				publish(schedule())
				debounce[id] = nil
			}
		}
	}
}
