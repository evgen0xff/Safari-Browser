//
//  WebViewModel.swift
//  SafariBrowser
//

import Foundation
import Combine

typealias WEB_NAVIGATION = WebViewModel.NAVIGATION

class WebViewModel: ObservableObject, Identifiable, Equatable {
    
    static func == (lhs: WebViewModel, rhs: WebViewModel) -> Bool { lhs.id == rhs.id }
    
    
    let id = UUID()
    
    enum NAVIGATION {
        case BACK, FORWARD, REFRESH
    }
    
    @Published var searchUrl: String = ""
    
    // Event sender whenever Url of WebView is chagned
    var changedUrlSubject = PassthroughSubject<URL, Never>()

    // Event sender for WebView navigation
    var webNavigationSubject = PassthroughSubject<WEB_NAVIGATION, Never>()
    
    // Website Title Event sender
    var webSiteTitleSubject = PassthroughSubject<String, Never>()
    
    // Event for Loading Indicator
    var shouldShowLoading = PassthroughSubject<Bool, Never>()
    
    // Event for Js to Native : JS -> iOS
    var jsAlertEvent = PassthroughSubject<JsAlert, Never>()
    
    func onChangedUrl() {
        guard !searchUrl.isEmpty else { return }
        if !searchUrl.contains("https://") && !searchUrl.contains("http://") {
            searchUrl = "https://" + searchUrl
        }
        guard let url = URL(string: searchUrl), !url.isFileURL else { return }
        
        changedUrlSubject.send(url)
    }
    
}
