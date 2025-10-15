//
//  YouTubePlayerView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
import WebKit

// SwiftUI wrapper for WKWebView
struct YouTubePlayerView: UIViewRepresentable {
    let controller: YouTubePlayerController

    func makeUIView(context: Context) -> WKWebView {
        return controller.webView ?? WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}
