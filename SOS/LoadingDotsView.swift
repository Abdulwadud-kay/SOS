//
//  LoadingDotsView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/25/25.
//

import Foundation
import SwiftUI

struct LoadingDotsView: View {
    @State private var scale: CGFloat = 0.5
    let animation = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale)
                    .animation(animation.delay( Double(index) * 0.2 ), value: scale)
            }
        }
        .onAppear {
            scale = 1.0
        }
    }
}
