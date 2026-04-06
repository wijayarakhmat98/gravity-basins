import SwiftUI

enum event_t {
	case log(_ message : String)
	case click_gravity(_ position : CGPoint, _ resolution : CGSize)
	case double_click_gravity(_ position : CGPoint, _ resolution : CGSize)
	case click_basin(_ position : CGPoint, _ resolution : CGSize)
	case drag(_ delta : CGSize)
	case zoom(_ delta : CGFloat)
	case simulate_remove
}
