protocol destructurable {}

infix operator ~>

func ~> <U : destructurable, T>(object : U, k : KeyPath<U, T>) -> T {
	object[keyPath : k]
}

func ~> <U : destructurable, each T>(object : U, k : (repeat KeyPath<U, each T>)) -> (repeat each T) {
	(repeat object[keyPath : each k])
}

func ~> <T>(old : T, f : (inout T) -> Void) -> T {
	var new = old
	f(&new)
	return new
}

infix operator <~

func <~ <each T, U>(f : (repeat each T) -> U, args : (repeat each T)) -> U {
	f(repeat each args)
}
