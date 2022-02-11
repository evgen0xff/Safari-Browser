//
//  WebView.swift
//  SafariWebBrowser
//
//

import UIKit
import WebKit
import Combine

class WebView: WKWebView  {

    var model: WebViewModel?
    var subscriptions = Set<AnyCancellable>()

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        initializeData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeData()
    }
    
    func initializeData() {
        
        // Confige Webview
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences

        // User controller of WebView
        let userContentController = WKUserContentController()
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        userContentController.add(self, name: "callbackHandler")
        configuration.userContentController = userContentController

        // Allows to swipe to go back
        allowsBackForwardNavigationGestures = true
    }
    
    func setData(_ model: WebViewModel?, uiDelegate: WKUIDelegate? = nil, navigationDelegate: WKNavigationDelegate? = nil) {
        self.model = model

        self.uiDelegate = uiDelegate ?? self
        self.navigationDelegate = navigationDelegate ?? self

        model?.changedUrlSubject
            .compactMap { $0 }
            .sink { [weak self] changedUrl in
                print("Url changed: \(changedUrl)")
                self?.isHidden = false
                self?.load(URLRequest(url: changedUrl))
            }.store(in: &subscriptions)
        
        if let strUrl = model?.searchUrl, let url = URL(string: strUrl) {
            isHidden = false
            load(URLRequest(url: url))
        }else {
            isHidden = true
        }
    }
    
}

//MARK: - WKUIDelegate
extension WebView: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        
        completionHandler()
    }
    
}

//MARK: - WKNavigationDelegate - Related to link and transfor screens
extension WebView: WKNavigationDelegate {
    
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
//            if model?.searchUrl != nil, model?.searchUrl.isEmpty != false {
//                model?.searchUrl = url.absoluteString
//            }
            decisionHandler(.allow)
        }

    }
    
    // When searching on WebView was started
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView didStartProvisionalNavigation")
        
//        if let strUrl = webView.url?.absoluteString {
//            if model?.searchUrl != nil, model?.searchUrl.isEmpty != false {
//                model?.searchUrl = strUrl
//            }
//        }

        // Send Loading Started Event
        model?.shouldShowLoading.send(true)
        
        model?
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
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
         webView.evaluateJavaScript(jscript)
        // Send Loading Event
        model?.shouldShowLoading.send(true)
    }

    // When searching on WebView was finished
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish")
        
//        if let strUrl = webView.url?.absoluteString {
//            if model?.searchUrl != nil, model?.searchUrl.isEmpty != false {
//                model?.searchUrl = strUrl
//            }
//        }
        
        webView.evaluateJavaScript("document.title") { (response, error) in
            if error != nil {
                print("An error occured")
            }
            if let title = response as? String {
                self.model?.webSiteTitleSubject.send(title)
            }
        }
        
        // Send Loading Ended Event
        model?.shouldShowLoading.send(false)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("webView - webViewWebContentProcessDidTerminate")
        // Send Loading Ended Event
        model?.shouldShowLoading.send(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webView - didFail")
        // Send Loading Ended Event
        model?.shouldShowLoading.send(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("webView - didFailProvisionalNavigation")
        // Send Loading Ended Event
        model?.shouldShowLoading.send(false)
    }
}

//MARK: - WKScriptMessageHandler
extension WebView: WKScriptMessageHandler {
    
    // It is called from Javascript in WebView
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKWebViewCoordinator - userContentController / message: \(message)")
    }
}





