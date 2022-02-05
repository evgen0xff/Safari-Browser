//
//  HomeView.swift
//  SafariBrowser
//

import SwiftUI

struct HomeView: View {

    // Color Scheme ...
    @Environment(\.colorScheme) var scheme
    
    @EnvironmentObject var mainModel: ViewModel
    
    @Binding var tabs: [WebViewModel]
    
    @State var draggedItem: WebViewModel?

    var body: some View {
        ZStack {
            // Content....
            ScrollView(.vertical, showsIndicators: false) {
                // Lazy Grid...
                let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                LazyVGrid(columns: columns, spacing: 15) {
                    // Tabs...
                    ForEach(tabs) { tab in
                        // Tab Card View...
                        WebCardView(tabs: $tabs).environmentObject(tab)
                            .opacity(draggedItem?.id == tab.id ? 0.01 : 1)
                            .onDrag {
                                draggedItem = tab
                                return NSItemProvider(item: nil, typeIdentifier: tab.id.uuidString)
                            }
                            .onDrop(of: [tab.id.uuidString],
                                    delegate: MyDropDelegate(currentItem: tab, dataList: $tabs, draggedItem: $draggedItem))

                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                // bottom tool bar
                HStack {
                    Button {
                        mainModel.currentWebModel = WebViewModel()
                        mainModel.isHome = false
                        withAnimation {
                            tabs.append(mainModel.currentWebModel!)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    
                    Spacer()

                    Button {
                        mainModel.currentWebModel = tabs.last
                        mainModel.isHome = false
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }

                } // Plus "+" and Done buttons
                .overlay(
                    Button{
                        
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(tabs.count) Tabs")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.primary)
                    }
                ) // Center Text "Private"
                .padding([.horizontal, .top])
                .padding(.bottom, 10)
                .background(
                    scheme == .dark ? Color.black : Color.white
                )
            }
            
        }
        .background(.clear)
    }
}


struct MyDropDelegate: DropDelegate {

    var currentItem: WebViewModel
    
    @Binding var dataList: [WebViewModel]
    @Binding var draggedItem: WebViewModel?
    
    
    // Drop exited
    func dropExited(info: DropInfo) {
        
    }
    // Drop updated
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    // Drop validation
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    // Drop Started
    func dropEntered(info: DropInfo) {
        
        if draggedItem == nil {
            draggedItem = currentItem
        }
        
        if draggedItem?.id != currentItem.id {
            let from = dataList.firstIndex { $0.id == draggedItem?.id }!
            let to = dataList.firstIndex { $0.id == currentItem.id }!

            withAnimation {
                let item = dataList[from]
                dataList[from] = dataList[to]
                dataList[to] = item
            }
        }
                
    }
    
    // Process Drop
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
}

