//
//  MainView.swift
//  SafariBrowser
//

import SwiftUI
import Combine
import SwiftUIPager

struct MainView: View {
    
    // Color Scheme ...
    @Environment(\.colorScheme) var scheme
    
    @EnvironmentObject var viewModel: ViewModel

    @State var tabs = [WebViewModel]()
    
    @StateObject var currentPage: Page = .first()
    
    @State var offsetPager = CGSize.zero
    
    @State var pageSize: CGSize = UIScreen.main.bounds.size
    
    var backgroundView: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            Image("bgSplash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .cornerRadius(0)
        }
        .overlay(scheme == .dark ? Color.black : Color.white).opacity(0.7)
        .overlay(.ultraThinMaterial)
        .ignoresSafeArea()
    }

    
    var body: some View {
        ZStack {
            backgroundView
            if viewModel.isHome {
                HomeView(tabs: $tabs)
            }else {
                Pager(page: currentPage, data: tabs, id:\.id) { tab in
                    ContentView().environmentObject(tab)
                }
                .preferredItemSize(pageSize)
                .itemSpacing(10)
                .onPageChanged{ _ in addBlankPage() }
                .onAppear { addBlankPage() }
                .onReceive(viewModel.$pageSize) { value in
                    print("changed page size : ", value)
                    withAnimation {
                        self.pageSize = value
                    }
                }
            }
        }
        .onReceive(viewModel.$currentWebModel) { current in
            if let model = current, let index = tabs.firstIndex(of: model) {
                withAnimation {
                    currentPage.index = index
                }
            }else {
                viewModel.isHome = true
            }
        }
    }
    
    func addBlankPage() {
        if let last = tabs.last, !last.searchUrl.isEmpty, currentPage.index == (tabs.count - 1) {
            let newWebVM = WebViewModel()
            newWebVM.searchUrl = ""
            withAnimation {
                tabs.append(newWebVM)
            }
        }
    }
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
