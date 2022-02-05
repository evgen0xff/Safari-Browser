//
//  JsAlert.swift
//  SwiftUI_WebView_tutorial
//
//

import Foundation

// Javascript Alert
struct JsAlert: Identifiable {
    enum TYPE: CustomStringConvertible {
        case JS_ALERT, JS_BRIDGE, BLOCKED_SITE
        var description: String {
            switch self {
            case .JS_ALERT:
                return "JS_ALERT TYPE"
            case .JS_BRIDGE:
                return "JS_BRIDGE TYPE"
            case .BLOCKED_SITE:
                return "Site blocked"
            }
        }
    }
    
    let id: UUID = UUID()
    var message: String = ""
    var type: TYPE
    
    init(_ message: String? = nil, _ type: TYPE) {
        self.message = message ?? "No Message"
        self.type = type
    }
}
