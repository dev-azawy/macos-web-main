import Foundation
import Capacitor
import WebKit

/// Renders one real WKWebView per open "browser" window (Safari / Chrome / Google /
/// GitHub / YouTube) directly on top of the Capacitor root view, positioned to match
/// the on-screen frame of the Svelte window that represents it.
///
/// Using a real, separately-navigated WKWebView (instead of an <iframe> inside the
/// app's own webview) is what lets Google / GitHub load at all: those sites send
/// X-Frame-Options / CSP frame-ancestors headers that block iframes, but that
/// restriction only applies to *framed* content, not to a WKWebView doing its own
/// top-level navigation.
@objc(NativeWebviewPlugin)
public class NativeWebviewPlugin: CAPPlugin, CAPBridgedPlugin, WKNavigationDelegate {
    public let identifier = "NativeWebviewPlugin"
    public let jsName = "NativeWebview"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "update", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "focus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "goBack", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "goForward", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reload", returnType: CAPPluginReturnPromise)
    ]

    private var webviews: [String: WKWebView] = [:]

    @objc func open(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
              let urlString = call.getString("url"),
              let url = URL(string: urlString) else {
            call.reject("id and url are required")
            return
        }

        let x = call.getDouble("x") ?? 0
        let y = call.getDouble("y") ?? 0
        let width = call.getDouble("width") ?? 300
        let height = call.getDouble("height") ?? 300

        DispatchQueue.main.async {
            guard let rootView = self.bridge?.viewController?.view else {
                call.reject("no root view")
                return
            }

            let alreadyExisted = self.webviews[id] != nil
            let webView: WKWebView

            if let existing = self.webviews[id] {
                webView = existing
            } else {
                let config = WKWebViewConfiguration()
                webView = WKWebView(
                    frame: CGRect(x: x, y: y, width: width, height: height),
                    configuration: config
                )
                webView.navigationDelegate = self
                webView.allowsBackForwardNavigationGestures = true
                webView.clipsToBounds = true
                webView.scrollView.contentInsetAdjustmentBehavior = .never
                self.webviews[id] = webView
                rootView.addSubview(webView)
            }

            webView.frame = CGRect(x: x, y: y, width: width, height: height)
            rootView.bringSubviewToFront(webView)

            if !alreadyExisted {
                webView.load(URLRequest(url: url))
            }

            call.resolve()
        }
    }

    @objc func update(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }

        let x = call.getDouble("x") ?? 0
        let y = call.getDouble("y") ?? 0
        let width = call.getDouble("width") ?? 300
        let height = call.getDouble("height") ?? 300
        let visible = call.getBool("visible") ?? true

        DispatchQueue.main.async {
            guard let webView = self.webviews[id] else {
                call.resolve()
                return
            }
            webView.isHidden = !visible
            webView.frame = CGRect(x: x, y: y, width: width, height: height)
            call.resolve()
        }
    }

    @objc func focus(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }
        DispatchQueue.main.async {
            guard let webView = self.webviews[id], let rootView = self.bridge?.viewController?.view else {
                call.resolve()
                return
            }
            rootView.bringSubviewToFront(webView)
            call.resolve()
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("id is required")
            return
        }
        DispatchQueue.main.async {
            if let webView = self.webviews[id] {
                webView.stopLoading()
                webView.removeFromSuperview()
                self.webviews.removeValue(forKey: id)
            }
            call.resolve()
        }
    }

    @objc func loadUrl(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
              let urlString = call.getString("url"),
              let url = URL(string: urlString) else {
            call.reject("id and url are required")
            return
        }
        DispatchQueue.main.async {
            self.webviews[id]?.load(URLRequest(url: url))
            call.resolve()
        }
    }

    @objc func goBack(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("id is required"); return }
        DispatchQueue.main.async {
            self.webviews[id]?.goBack()
            call.resolve()
        }
    }

    @objc func goForward(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("id is required"); return }
        DispatchQueue.main.async {
            self.webviews[id]?.goForward()
            call.resolve()
        }
    }

    @objc func reload(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("id is required"); return }
        DispatchQueue.main.async {
            self.webviews[id]?.reload()
            call.resolve()
        }
    }

    private func idFor(_ webView: WKWebView) -> String? {
        webviews.first(where: { $0.value === webView })?.key
    }

    private func emitState(_ webView: WKWebView, loading: Bool) {
        guard let id = idFor(webView) else { return }
        notifyListeners("navigationStateChanged", data: [
            "id": id,
            "url": webView.url?.absoluteString ?? "",
            "title": webView.title ?? "",
            "canGoBack": webView.canGoBack,
            "canGoForward": webView.canGoForward,
            "loading": loading
        ])
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        emitState(webView, loading: true)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        emitState(webView, loading: false)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        emitState(webView, loading: false)
    }
}
