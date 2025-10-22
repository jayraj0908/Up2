import SwiftUI
import WebKit

#if canImport(UIKit)
/// A reusable SwiftUI wrapper around `WKWebView` for displaying web content inside the app.
struct Up2WebView: UIViewRepresentable {
    /// The URL to load inside the web view.
    let url: URL

    /// Controls whether the user can navigate using swipe gestures.
    var allowsBackForwardNavigationGestures: Bool = true

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard uiView.url != url else { return }
        uiView.load(URLRequest(url: url))
    }
}
#elseif canImport(AppKit)
struct Up2WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard nsView.url != url else { return }
        nsView.load(URLRequest(url: url))
    }
}
#endif
