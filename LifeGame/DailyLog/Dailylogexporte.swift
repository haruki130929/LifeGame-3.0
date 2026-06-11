import SwiftUI
import PDFKit
import UIKit

/// 每日紀錄匯出工具
///
/// 把選定日期區間的每日紀錄,匯出成「純文字檔」或「PDF」。
/// 純文字適合快速閱讀、貼到其他地方;PDF 適合保存、列印、分享。
enum DailyLogExporter {

    // MARK: - 對外主要方法

    /// 產生純文字內容
    static func makeText(entries: [DailyLogEntry], start: Date, end: Date) -> String {
        var lines: [String] = []
        lines.append("每日紀錄匯出")
        lines.append("期間：\(dateString(start)) ～ \(dateString(end))")
        lines.append("共 \(entries.count) 筆")
        lines.append(String(repeating: "═", count: 30))
        lines.append("")

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            lines.append(contentsOf: blockForEntry(entry))
            lines.append("")
            lines.append(String(repeating: "─", count: 30))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// 把純文字寫成 .txt 檔,回傳檔案位置
    static func writeTextFile(entries: [DailyLogEntry], start: Date, end: Date) throws -> URL {
        let text = makeText(entries: entries, start: start, end: end)
        let fileName = "每日紀錄_\(fileDateString(start))_\(fileDateString(end)).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// 產生 PDF 檔,回傳檔案位置
    static func writePDFFile(entries: [DailyLogEntry], start: Date, end: Date) throws -> URL {
        let text = makeText(entries: entries, start: start, end: end)
        let fileName = "每日紀錄_\(fileDateString(start))_\(fileDateString(end)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // A4 尺寸 (點為單位)
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 40
        let textRect = CGRect(x: margin, y: margin,
                              width: pageWidth - margin * 2,
                              height: pageHeight - margin * 2)

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.label
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)

        try renderer.writePDF(to: url) { ctx in
            // 用 CoreText 分頁排版,文字太長會自動換頁
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            var currentRange = CFRange(location: 0, length: 0)
            var done = false

            while !done {
                ctx.beginPage()
                let path = CGPath(rect: textRect, transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)

                let cgContext = ctx.cgContext
                // PDF 座標系是上下顛倒的,需要翻轉
                cgContext.translateBy(x: 0, y: pageHeight)
                cgContext.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, cgContext)
                // 翻轉回來,避免影響下一頁
                cgContext.scaleBy(x: 1, y: -1)
                cgContext.translateBy(x: 0, y: -pageHeight)

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                currentRange.location += visibleRange.length
                if currentRange.location >= attributed.length {
                    done = true
                }
            }
        }

        return url
    }

    // MARK: - 單筆紀錄的文字組裝

    private static func blockForEntry(_ entry: DailyLogEntry) -> [String] {
        var l: [String] = []
        l.append("【\(dateString(entry.date))】 天氣：\(entry.weather.rawValue)")
        l.append("起床：\(timeString(entry.wakeTime))　就寢：\(timeString(entry.bedTime))")
        l.append("整體情緒：\(entry.overallMoodScore)　焦慮分數：\(entry.anxietyScore)")
        l.append("疲勞分數：\(entry.fatigueScore)")

        // 情緒變化
        if entry.moodChangeType != .stable {
            l.append("情緒變化：\(entry.moodChangeType.rawValue)")
            if !entry.moodChangeOtherText.isEmpty {
                l.append("　變化說明：\(entry.moodChangeOtherText)")
            }
        }

        // 焦慮
        if entry.anxietyLevel != .none {
            l.append("焦慮程度：\(entry.anxietyLevel.rawValue)")
            if !entry.anxietyOtherText.isEmpty {
                l.append("　焦慮說明：\(entry.anxietyOtherText)")
            }
        }

        // 特別觀察
        let obs = entry.specialObservation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !obs.isEmpty {
            l.append("特別觀察：\(obs)")
        }

        // 照片數量(文字檔無法放圖,只標註數量)
        if !entry.photos.isEmpty {
            l.append("照片：\(entry.photos.count) 張")
        }

        return l
    }

    // MARK: - 格式化 helper

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年M月d日 (E)"
        return f.string(from: date)
    }

    private static func fileDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }

    private static func timeString(_ t: OptionalLogTime) -> String {
        if case .time(let d) = t {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: d)
        }
        return "未記錄"
    }
}
