protocol destructurable {}

infix operator ~>

nonisolated
func ~> <U : destructurable, each T>(object : U, k : (repeat KeyPath<U, each T>)) -> (repeat each T) {
	(repeat object[keyPath : each k])
}

nonisolated
func ~> <T>(old : T, f : (inout T) -> Void) -> T {
	var new = old
	f(&new)
	return new
}

infix operator <~

nonisolated
func <~ <each T, U>(f : (repeat each T) -> U, args : (repeat each T)) -> U {
	f(repeat each args)
}
