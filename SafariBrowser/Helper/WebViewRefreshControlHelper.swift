//
//  WebViewRefreshControlHelper.swift
//  SafariBrowser
//
//

import Foundation
import UIKit
import SwiftUI

class WebViewRefreshControlHelper {
    
    //MARK: - Properties
    var refreshControl: UIRefreshControl?
    var viewModel: WebViewModel?
    
    // Method for UIRefreshControl
    @objc func didRefresh() {
        print("WebViewRefreshControlHelper - didRefresh called")
        guard let refreshControl = refreshControl,
              let viewModel = viewModel else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Send Refresh Event
            viewModel.webNavigationSubject.send(.REFRESH)
            // End Refresh Animation
            refreshControl.endRefreshing()
        }
        
    }
    
}
