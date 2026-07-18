//  ReviewView.swift
//  에이전트가 작성한 논문 리뷰 페이지(paper.reviewURL)를 여는 전체 화면 리더.
//  Pushed from the detail screen (no tab bar). Draws its own top bar like
//  PaperDetailView: back · paper title · share. A thin determinate progress bar
//  tracks the page load; a styled error state with retry appears on failure.

import SwiftUI
import WebKit

struct ReviewView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let paper: Paper
    let url: URL

    @State private var progress: Double = 0
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var attempt = 0        // bump → reload (retry)

    /// reviewURL + `app=1` — 페이지가 자체 상단 바(뒤로/arXiv 행)를 숨기고 네이티브 바만 남긴다.
    /// 공유(ShareLink)는 원본 URL 그대로 사용.
    private var embeddedURL: URL {
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: "app", value: "1"))
        comps.queryItems = items
        return comps.url ?? url
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바 (뒤로 · 논문 제목 · 공유) — PaperDetailView와 같은 커스텀 바
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("←")
                        .font(AppFont.sans(15, .semibold))
                        .foregroundStyle(Palette.muted)
                }
                .buttonStyle(.plain)

                Text(paper.feedTitle)
                    .font(AppFont.sans(14, .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)

                ShareLink(item: url) {
                    Text(app.strings.detailShare)
                        .font(AppFont.sans(14, .medium))
                        .foregroundStyle(Palette.accentDeep)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 46)
            .padding(.horizontal, 24)

            ZStack(alignment: .top) {
                ReviewWebView(
                    url: embeddedURL,
                    attempt: attempt,
                    progress: $progress,
                    isLoading: $isLoading,
                    loadFailed: $loadFailed
                )

                if loadFailed {
                    VStack(spacing: 18) {
                        Text(app.strings.reviewLoadFail)
                            .font(AppFont.sans(14))
                            .foregroundStyle(Palette.muted)
                        OutlineButton(title: app.strings.reviewRetry, height: 44, radius: 12) {
                            loadFailed = false
                            isLoading = true
                            progress = 0
                            attempt += 1
                        }
                        .frame(width: 160)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.appBg)
                }

                // 얇은 로딩 진행 바 (estimatedProgress 연동)
                GeometryReader { geo in
                    Rectangle()
                        .fill(Palette.accent)
                        .frame(width: max(0, min(1, progress)) * geo.size.width)
                }
                .frame(height: 2.5)
                .opacity(isLoading ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: progress)
                .animation(.easeOut(duration: 0.3), value: isLoading)
            }
        }
        .background(Palette.appBg.ignoresSafeArea())   // 다크 모드에서도 흰 플래시 없음
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - WKWebView wrapper

private struct ReviewWebView: UIViewRepresentable {
    let url: URL
    let attempt: Int
    @Binding var progress: Double
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false                       // 페이지 로드 전 앱 배경이 비침
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        context.coordinator.observeProgress(of: webView)
        context.coordinator.loadedAttempt = attempt
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.loadedAttempt != attempt {   // retry 요청
            context.coordinator.loadedAttempt = attempt
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ReviewWebView
        var loadedAttempt = 0
        private var observation: NSKeyValueObservation?

        init(_ parent: ReviewWebView) { self.parent = parent }
        deinit { observation?.invalidate() }

        func observeProgress(of webView: WKWebView) {
            observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                let value = webView.estimatedProgress
                DispatchQueue.main.async { self?.parent.progress = value }
            }
        }

        // 리뷰 본문 안의 외부 링크(arXiv·GitHub 등)는 Safari로 연다.
        // 리더 안에는 웹 뒤로가기가 없으므로 웹뷰에는 피드 호스트 페이지만 남긴다.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let target = navigationAction.request.url,
               target.host != parent.url.host {
                UIApplication.shared.open(target)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // target="_blank" 링크도 죽은 탭이 되지 않게 Safari로 넘긴다.
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let target = navigationAction.request.url {
                UIApplication.shared.open(target)
            }
            return nil
        }

        // 페이지가 404/500 등으로 응답하면 (전송은 성공해도) 실패 상태로 전환한다.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame,
               let http = navigationResponse.response as? HTTPURLResponse,
               http.statusCode >= 400 {
                parent.isLoading = false
                parent.loadFailed = true
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.loadFailed = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            fail(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            fail(error)
        }

        private func fail(_ error: Error) {
            // 리다이렉트 등으로 취소된 내비게이션은 실패로 치지 않는다.
            if (error as NSError).code == NSURLErrorCancelled { return }
            parent.isLoading = false
            parent.loadFailed = true
        }
    }
}
