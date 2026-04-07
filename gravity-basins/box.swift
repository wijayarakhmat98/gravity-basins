import SwiftUI

@Observable
final class box<T> {
	var value : T
	init(_ value : T) { self.value = value }
}
