//
//  PagerView.swift
//  SafariBrowser
//
//  Created by Top Star on 2/5/22.
//

import SwiftUI
import SwiftUIPager

struct PagerView: View {

    @EnvironmentObject var mainModel: ViewModel
    @Binding var tabs: [WebViewModel]

    var body: some View {
    }
}

struct PagerView_Previews: PreviewProvider {
    static var previews: some View {
        PagerView()
    }
}
