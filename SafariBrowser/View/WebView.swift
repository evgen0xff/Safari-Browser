//
//  WebView.swift
//  SafariBrowser
//
//

import SwiftUI
import WebKit
import Combine

struct WebView: UIViewRepresentable {

    @EnvironmentObject var viewModel: WebViewModel
    @EnvironmentObject var mainModel: ViewModel

    var urlToLoad: String = ""
    
    // RefreshController Helper
    let refreshHelper = WebViewRefreshControlHelper()
    
    var subscriptions = Set<AnyCancellable>()

    

    // UI view creation
    func makeUIView(context: Context) -> WKWebView {
        
        // Create an instance of WKWebView
        let webView = WKWebView(frame: .zero, configuration: createWKWebConfig())
        
        // WKWebView's delegate
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true // Allows to swipe to go back
        
        // Add Refresh Contoller
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.tintColor = .blue
        webView.scrollView.refreshControl = myRefreshControl
        webView.scrollView.bounces = true // set if the bouncing is enable.
        
        myRefreshControl.addTarget(refreshHelper, action: #selector(WebViewRefreshControlHelper.didRefresh), for: .valueChanged)
        
        // RefreshController Helper
        refreshHelper.viewModel = viewModel
        refreshHelper.refreshControl = myRefreshControl
        
        // Load a web page with url
        if let url = URL(string: urlToLoad) {
            webView.load(URLRequest(url: url))
        }

        viewModel
            .changedUrlSubject
            .compactMap { $0 }
            .sink { changedUrl in
                print("Url changed: \(changedUrl)")
                webView.load(URLRequest(url: changedUrl))
            }.store(in: &(context.coordinator as Coordinator).subscriptions)

        return webView
    }
    
    // Updating UI view
    
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        if mainModel.isHome {
            let actualWidth = (getRect().width - 60)
            let cardWidth = actualWidth / 2
            let scale = cardWidth / actualWidth

            uiView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }else {
            uiView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func createWKWebConfig() -> WKWebViewConfiguration {
        // Confige Webview
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        
        let wkWebConfig = WKWebViewConfiguration()
        
        // User controller of WebView
        let userContentController = WKUserContentController()
        userContentController.add(self.makeCoordinator(), name: "callbackHandler")
        wkWebConfig.userContentController = userContentController
        wkWebConfig.preferences = preferences

        return wkWebConfig
    }
    
    class Coordinator: NSObject {
        var myWebView: WebView // SwiftUI View
        var subscriptions = Set<AnyCancellable>()
        
        init(_ myWebView: WebView) {
            self.myWebView = myWebView
        }
    }
}

//MARK: - WKUIDelegate
extension WebView.Coordinator: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        
        myWebView.viewModel.jsAlertEvent.send(JsAlert(message, .JS_ALERT))
        
        completionHandler()
    }
    
}

//MARK: - WKNavigationDelegate - Related to link and transfor screens
extension WebView.Coordinator: WKNavigationDelegate {
    
    // It is called when the navigation action comes
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("webView decidePolicyFor navigationAction")

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        
        switch url.scheme {
        case "tel", "mailto":
            // Open Link
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        default:
            myWebView.viewModel.searchUrl = url.absoluteString
            decisionHandler(.allow)
        }

    }
    
    // When searching on WebView was started
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView didStartProvisionalNavigation")
        
        if let strUrl = webView.url?.absoluteString {
            myWebView.viewModel.searchUrl = strUrl
        }

        // Send Loading Started Event
        myWebView.viewModel.shouldShowLoading.send(true)
        
        myWebView
            .viewModel
            .webNavigationSubject
            .sink { (action: WEB_NAVIGATION) in
                print("Action incomed : \(action)")
                switch action {
                case .BACK:
                    if webView.canGoBack {
                        webView.goBack()
                    }
                case .FORWARD:
                    if webView.canGoForward {
                        webView.goForward()
                    }
                case .REFRESH:
                    webView.reload()
                }
            }.store(in: &subscriptions)
    }
    
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView - didCommit")
        // Send Loading Event
        myWebView.viewModel.shouldShowLoading.send(true)
    }

    // When searching on WebView was finished
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish")
        
        if let strUrl = webView.url?.absoluteString {
            myWebView.viewModel.searchUrl = strUrl
        }
        
        webView.evaluateJavaScript("document.title") { (response, error) in
            if error != nil {
                print("An error occured")
            }
            if let title = response as? String {
                self.myWebView.viewModel.webSiteTitleSubject.send(title)
            }
        }
        
        // Send Loading Ended Event
        myWebView.viewModel.shouldShowLoading.send(false)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("webView - webViewWebContentProcessDidTerminate")
        // Send Loading Ended Event
        myWebView.viewModel.shouldShowLoading.send(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webView - didFail")
        // Send Loading Ended Event
        myWebView.viewModel.shouldShowLoading.send(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("webView - didFailProvisionalNavigation")
        // Send Loading Ended Event
        myWebView.viewModel.shouldShowLoading.send(false)
    }
}

//MARK: - WKScriptMessageHandler
extension WebView.Coordinator: WKScriptMessageHandler {
    
    // It is called from Javascript in WebView
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKWebViewCoordinator - userContentController / message: \(message)")
    }
}

