//
//  SafariBrowserApp.swift
//  SafariBrowser
//
//

import SwiftUI

@main
struct SafariBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(ViewModel())
        }
    }
}
