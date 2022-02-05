//
//  ContentView.swift
//  SafariBrowser
//
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var viewModel: WebViewModel
    @EnvironmentObject var mainModel: ViewModel

    

    @State var jsAlert: JsAlert?
    @State var webTitle: String = ""
    @State var isLoading = false
    @State var swipeUpOnBottom = false
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                WebView(urlToLoad: viewModel.searchUrl)
                VStack(spacing: 0) {
                    Divider()
                    searchBar
                    Divider()
                    bottomTabbar
                }
                .opacity(abs(mainModel.offsetPager.height) < 30 ? 1 : 0)
                .gesture(
                    DragGesture(minimumDistance: 10.0, coordinateSpace: .local)
                    .onChanged{ value in
                        mainModel.offsetPager = value.translation
                    }
                    .onEnded { value in
                        print(value.translation)
                        
                        if value.translation.width < 0 && value.translation.height > -30 && value.translation.height < 30 {
                            print("left swipe")
                        }
                        else if value.translation.width > 0 && value.translation.height > -30 && value.translation.height < 30 {
                            print("right swipe")
                        }
                        else if value.translation.height < 0 && value.translation.width < 100 && value.translation.width > -100 {
                            print("up swipe")
                            mainModel.currentWebModel = nil
                            mainModel.isHome = true
                        }
                        else if value.translation.height > 0 && value.translation.width < 100 && value.translation.width > -100 {
                            print("down swipe")
                        }
                        else {
                            print("no clue")
                        }
                        mainModel.offsetPager = CGSize.zero
                    }
                )
            } // Vstack
            .alert(item: $jsAlert) { createAlert($0) }
//            if isLoading { LoadingScreenView() }
        } // Zstack
        .background(.clear)
        .onReceive(viewModel.webSiteTitleSubject) { webTitle in
            print("Content - webTitle: ", webTitle)
            self.webTitle = webTitle
        }
        .onReceive(viewModel.jsAlertEvent) { jsAlert in
            print("Content - jsAlert: ", jsAlert)
            self.jsAlert = jsAlert
        }
        .onReceive(viewModel.shouldShowLoading) { isLoading in
            print("Content - isLoading: ", isLoading)
            self.isLoading = isLoading
        }
    } // body

    var searchBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                TextField("Search or enter website", text: $viewModel.searchUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .submitLabel(.go)
                    .onSubmit { viewModel.onChangedUrl() }
                    .frame(height: 40)
                    .padding(.horizontal, 10)
            }
            .background(.gray.opacity(0.3))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    var bottomTabbar: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                print("Back")
                viewModel.webNavigationSubject.send(.BACK)
            } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 20))
            }

            Group {
                Spacer()
                Divider()
                Spacer()
            }

            Button {
                print("Forward")
                viewModel.webNavigationSubject.send(.FORWARD)
            } label: {
                Image(systemName: "arrow.forward")
                    .font(.system(size: 20))
            }

            Group {
                Spacer()
                Divider()
                Spacer()
            }

            Button {
                print("Refresh")
                viewModel.webNavigationSubject.send(.REFRESH)
            } label: {
                Image(systemName: "goforward")
                    .font(.system(size: 20))
            }
            Spacer()
        }
        .frame(height: 45)
    }

}

    
extension ContentView {
    // Alert
    func createAlert(_ alert: JsAlert) -> Alert {
        Alert(title: Text(alert.type.description), message: Text(alert.message), dismissButton: .default(Text("OK"), action: {
            print("Alert Ok button clicked")
        }))
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
