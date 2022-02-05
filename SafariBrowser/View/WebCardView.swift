//
//  WebCardView.swift
//  SafariBrowser
//
//

import SwiftUI

struct WebCardView: View {
    
    @EnvironmentObject var viewModel: WebViewModel
    @EnvironmentObject var mainModel: ViewModel
    // All Tab...
    @Binding var tabs: [WebViewModel]
    
    // Tab Title...
    @State var tabTitle = ""
    
    // Gestures...
    @State var offset: CGFloat = 0
    @GestureState var isDragging: Bool = false
    
    var body: some View {
        
        VStack(spacing: 10) {
            // Web View...
            WebView(urlToLoad: viewModel.searchUrl)
            .frame(height: 250)
            .overlay(Color.primary.opacity(0.01))
            .cornerRadius(15)
            .overlay(
                Button {
                    withAnimation {
                        offset = -(getRect().width + 200)
                        removeTab()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                    .padding(10),
                
                alignment: .topTrailing
            )
            .onReceive(viewModel.webSiteTitleSubject) { webTitle in
                print("Content - webTitle: ", webTitle)
                self.tabTitle = webTitle
            }
            
            Text(tabTitle)
                .fontWeight(.bold)
                .lineLimit(1)
                .frame(height: 50)
            
        }
        .scaleEffect(getScale())
        .contentShape(Rectangle())
        .offset(x: offset)
        .gesture(
            DragGesture()
                .updating($isDragging, body: { _, out, _ in
                    out = true
                })
                .onChanged({ value in
                    // Safety...
                    if isDragging {
                        let translation = value.translation.width
                        offset = translation > 0 ? translation / 10 : translation

                    }
                })
                .onEnded({ value in
                    let translation = value.translation.width > 0 ? 0 : -value.translation.width

                    // Left side one translation width for removal
                    // right side one ...
                    if getIndex() % 2 == 0 {
                        print("left")
                        if translation > 100 {
                            // moving tab aside and removing
                            withAnimation {
                                offset = -(getRect().width + 200)
                                removeTab()
                            }
                        }else {
                            withAnimation{
                                offset = 0
                            }
                        }
                    }else {
                        print("right")
                        if translation > getRect().width - 150 {
                            withAnimation {
                                offset = -(getRect().width + 200)
                                removeTab()
                            }

                        }else {
                            withAnimation{
                                offset = 0
                            }
                        }
                    }
                })
            
        )
        .onTapGesture {
            mainModel.currentWebModel = viewModel
            mainModel.isHome = false
        }
    }
    
    func getScale() -> CGFloat {
        // Scaling little bit while dragging..
        let progress = (offset > 0 ? offset : -offset) / 50
        let scale = (progress < 1 ? progress : 1) * 0.08
        
        return 1 + scale
    }
    
    func getIndex() -> Int {
        let index = tabs.firstIndex { currentTab in
            return currentTab.id == viewModel.id
        } ?? 0
        
        return index
    }
    
    func removeTab() {
        // safe Remove..
        tabs.removeAll { tab in
            return self.viewModel.id == tab.id
        }
    }
    
}
