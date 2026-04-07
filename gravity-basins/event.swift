import SwiftUI

enum source_t {
	case editor
	case visual
}

enum event_t {
//	case log(_ message : String)
	case in_motion(_ in_motion : Bool)
	case resolution(_ source : source_t, _ display_scale : CGFloat, _ resolution : CGSize)
	case single_tap(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case double_tap(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case drag_start(_ source : source_t, _ position : CGPoint, _ resolution : CGSize)
	case drag(_ source : source_t, _ delta : CGSize)
	case drag_end(_ source : source_t)
	case magnify(_ source : source_t, _ delta : CGFloat)
	case magnify_end(_ source : source_t)
	case body_modify(_ mass : Double, _ color : color_t)
	case element_remove
}
