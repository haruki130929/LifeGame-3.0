import SwiftUI
import UIKit

/// 把每日紀錄渲染成 A4 分頁 PDF（複用 DailyLogFullReviewCard，含照片）。
///
/// 做法：逐筆（＋頁首）各自渲染成圖，再排版到 PDF。
/// 不把整個區間疊成一張超長圖——那樣紀錄一多就會超過繪圖系統的單張圖片上限而渲染失敗。
@MainActor
enum DailyLogPDFRenderer {

    static func makePDF(for entries: [DailyLogEntry],
                        rangeTitle: String,
                        moduleStore: QuestionModuleStore) -> Data? {
        let pageWidth: CGFloat = 595   // A4 @ 72dpi
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 24
        let contentWidth = pageWidth - margin * 2
        let spacing: CGFloat = 14
        let scale: CGFloat = 2

        let sorted = entries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return nil }

        var blocks: [UIImage] = []

        // 頁首
        let header = VStack(alignment: .leading, spacing: 4) {
            Text("每日紀錄匯出").font(.title2.weight(.bold))
            Text(rangeTitle).font(.subheadline).foregroundStyle(.secondary)
            Text("共 \(sorted.count) 筆").font(.footnote).foregroundStyle(.secondary)
        }
        if let img = renderBlock(header, width: contentWidth, scale: scale, moduleStore: moduleStore) {
            blocks.append(img)
        }

        // 每筆紀錄各自渲染一塊（forExport: 照片改用不滑動的格狀排列）
        // autoreleasepool：每筆渲染會解碼該日的照片原檔（實測單張 24 MP 就要 24.5 MB），
        // 沒有 pool 的話這些暫時性配置會累積到整個迴圈結束才釋放。
        for entry in sorted {
            autoreleasepool {
                let card = DailyLogFullReviewCard(entry: entry, forExport: true)
                if let img = renderBlock(card, width: contentWidth, scale: scale, moduleStore: moduleStore) {
                    blocks.append(img)
                }
            }
        }

        guard !blocks.isEmpty else { return nil }

        return paginate(blocks: blocks,
                        pageWidth: pageWidth,
                        pageHeight: pageHeight,
                        margin: margin,
                        spacing: spacing)
    }

    /// 把單一 SwiftUI 區塊渲染成圖（固定寬度、高度自適應）
    private static func renderBlock(_ view: some View,
                                    width: CGFloat,
                                    scale: CGFloat,
                                    moduleStore: QuestionModuleStore) -> UIImage? {
        let content = view
            .frame(width: width, alignment: .leading)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            .environmentObject(moduleStore)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        renderer.scale = scale
        return renderer.uiImage
    }

    /// 把多個區塊圖依序排版到 A4 分頁 PDF
    private static func paginate(blocks: [UIImage],
                                 pageWidth: CGFloat,
                                 pageHeight: CGFloat,
                                 margin: CGFloat,
                                 spacing: CGFloat) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let usableHeight = pageHeight - margin * 2
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)

        return pdfRenderer.pdfData { ctx in
            var started = false
            var y = CGFloat.greatestFiniteMagnitude   // 讓第一塊觸發開新頁

            func startPage() {
                ctx.beginPage()
                y = margin
                started = true
            }

            for img in blocks {
                let w = img.size.width
                let h = img.size.height
                guard h > 0 else { continue }

                // 單一區塊比一頁還高 → 切片跨頁（每頁裁切到可用範圍）
                if h > usableHeight {
                    startPage()
                    var drawn: CGFloat = 0
                    while drawn < h {
                        if drawn > 0 { startPage() }
                        ctx.cgContext.saveGState()
                        ctx.cgContext.clip(to: CGRect(x: margin, y: margin, width: w, height: usableHeight))
                        img.draw(in: CGRect(x: margin, y: margin - drawn, width: w, height: h))
                        ctx.cgContext.restoreGState()
                        drawn += usableHeight
                    }
                    y = pageHeight   // 強制下一塊換頁
                    continue
                }

                // 一般情形：放不下就換頁
                if y + h > pageHeight - margin {
                    startPage()
                }
                img.draw(in: CGRect(x: margin, y: y, width: w, height: h))
                y += h + spacing
            }

            if !started { ctx.beginPage() }   // 保底至少一頁
        }
    }
}
