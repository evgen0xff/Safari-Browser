//
//  LoadingIndicator.swift
//  SafariBrowser
//

import SwiftUI
import UIKit

struct LoadingIndicator: UIViewRepresentable {

    var isAnimating = true
    var color: UIColor = .white

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        uiView.style = .large
        uiView.color = color
    }
}

