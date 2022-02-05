//
//  ViewModel.swift
//  SafariBrowser
//
//  Created by Top Star on 2/5/22.
//

import Foundation
import UIKit
import SwiftUI
import Combine

class ViewModel: ObservableObject {

    @Published var isHome = true
    @Published var currentWebModel: WebViewModel?
    @Published var offsetPager = CGSize.zero
    @Published var pageSize = UIScreen.main.bounds.size

    var subscription = Set<AnyCancellable>()
    
    init() {
        $offsetPager
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .removeDuplicates(by: { (first, second) in
                return abs(abs(first.height) - abs(second.height)) < 10
            })
            .filter { value in
                let deltaX = abs(value.width)
                let deltaY = abs(value.height)
                return (deltaY > 10 && deltaX < 100) || (deltaX == 0 && deltaY == 0)
            }
            .map { value -> CGSize in
                let size = UIScreen.main.bounds.size
                let deltaY = abs(value.height)
                let scaleDelta = deltaY / size.height
                var scale = 1.0
                if value.height > 0 {
                    scale += scaleDelta
                }else {
                    scale -= scaleDelta
                }
                if scale > 1.0 {
                    scale = 1.0
                }
                if scale < 0.2 {
                    scale = 0.2
                }
                return CGSize(width: size.width * scale, height: size.height * scale)
            }
            .sink { size in
                print("ViewModel - page view size : ", size)
                self.pageSize = size
            }.store(in: &subscription)

    }
}
