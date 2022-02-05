//
//  LoadingScreenView.swift
//  SafariBrowser
//
//

import SwiftUI

struct LoadingScreenView: View {

    var body: some View {
        ZStack(alignment: .center) {
            Color.black
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            LoadingIndicator()
        }
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView()
    }
}
