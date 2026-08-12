import SwiftUI

// MARK: - 全域色票

/// App 全域可用的顏色色票，供時間圓環、課表、主題等各處使用
enum ColorPalette {

    // MARK: - 色票分類

    struct ColorGroup: Identifiable {
        let id: String
        let name: String
        let colors: [PaletteColor]
    }

    struct PaletteColor: Identifiable, Hashable {
        let id: String   // hex
        let hex: String
        let name: String

        var color: Color {
            Color(hex: hex)
        }
    }

    // MARK: - 所有色票

    /// 色名是在地化字串，不能用 static let（process 內只算一次，切語言後會凍住）。
    /// 但 256 個色票在色票選擇器裡會被反覆讀取，每次重建太浪費，
    /// 所以用「語言」當 key 做快取：語言沒變就直接回傳上次的結果。
    nonisolated(unsafe) private static var groupsCache: (language: String, groups: [ColorGroup])?

    static var allGroups: [ColorGroup] {
        if let cached = groupsCache, cached.language == AppLocalization.languageID {
            return cached.groups
        }
        let groups = [jpRed, jpOrange, jpYellow, jpGreen, jpBlue, jpPurple, jpNeutral]
        groupsCache = (AppLocalization.languageID, groups)
        return groups
    }

    /// 所有顏色（平鋪）
    nonisolated(unsafe) private static var colorsCache: (language: String, colors: [PaletteColor])?

    static var allColors: [PaletteColor] {
        if let cached = colorsCache, cached.language == AppLocalization.languageID {
            return cached.colors
        }
        let colors = allGroups.flatMap { $0.colors }
        colorsCache = (AppLocalization.languageID, colors)
        return colors
    }

    /// 快速用 hex 查顏色名稱
    static func name(for hex: String) -> String? {
        allColors.first { $0.hex.uppercased() == hex.uppercased() }?.name
    }

    // MARK: - 紅・桃系

    static var jpRed: ColorGroup {
        ColorGroup(id: "jp_red", name: String(localized: "紅・桃"), colors: [
        PaletteColor(id: "FEDFE1", hex: "FEDFE1", name: String(localized: "桜")),
        PaletteColor(id: "F8C3CD", hex: "F8C3CD", name: String(localized: "退紅")),
        PaletteColor(id: "F4A7B9", hex: "F4A7B9", name: String(localized: "一斥染")),
        PaletteColor(id: "F596AA", hex: "F596AA", name: String(localized: "桃")),
        PaletteColor(id: "EEA9A9", hex: "EEA9A9", name: String(localized: "鴇")),
        PaletteColor(id: "E87A90", hex: "E87A90", name: String(localized: "薄紅")),
        PaletteColor(id: "EB7A77", hex: "EB7A77", name: String(localized: "甚三紅")),
        PaletteColor(id: "DC9FB4", hex: "DC9FB4", name: String(localized: "撫子")),
        PaletteColor(id: "E16B8C", hex: "E16B8C", name: String(localized: "紅梅")),
        PaletteColor(id: "D05A6E", hex: "D05A6E", name: String(localized: "今様")),
        PaletteColor(id: "DB4D6D", hex: "DB4D6D", name: String(localized: "中紅")),
        PaletteColor(id: "D75455", hex: "D75455", name: String(localized: "鉛丹")),
        PaletteColor(id: "CB4042", hex: "CB4042", name: String(localized: "赤紅")),
        PaletteColor(id: "CB1B45", hex: "CB1B45", name: String(localized: "紅")),
        PaletteColor(id: "D0104C", hex: "D0104C", name: String(localized: "韓紅花")),
        PaletteColor(id: "C73E3A", hex: "C73E3A", name: String(localized: "銀朱")),
        PaletteColor(id: "AB3B3A", hex: "AB3B3A", name: String(localized: "真朱")),
        PaletteColor(id: "B5495B", hex: "B5495B", name: String(localized: "苺")),
        PaletteColor(id: "B55D4C", hex: "B55D4C", name: String(localized: "芝翫茶")),
        PaletteColor(id: "B54434", hex: "B54434", name: String(localized: "紅樺")),
        PaletteColor(id: "CC543A", hex: "CC543A", name: String(localized: "緋")),
        PaletteColor(id: "E83015", hex: "E83015", name: String(localized: "猩猩緋")),
        PaletteColor(id: "9F353A", hex: "9F353A", name: String(localized: "燕脂")),
        PaletteColor(id: "9E7A7A", hex: "9E7A7A", name: String(localized: "梅鼠")),
        PaletteColor(id: "B19693", hex: "B19693", name: String(localized: "桜鼠")),
        PaletteColor(id: "BF6766", hex: "BF6766", name: String(localized: "長春")),
        PaletteColor(id: "A96360", hex: "A96360", name: String(localized: "蘇芳香")),
        PaletteColor(id: "954A45", hex: "954A45", name: String(localized: "小豆")),
        PaletteColor(id: "8E354A", hex: "8E354A", name: String(localized: "蘇芳")),
        PaletteColor(id: "86473F", hex: "86473F", name: String(localized: "深緋")),
        PaletteColor(id: "D7C4BB", hex: "D7C4BB", name: String(localized: "灰桜")),
        PaletteColor(id: "904840", hex: "904840", name: String(localized: "栗梅")),
        PaletteColor(id: "734338", hex: "734338", name: String(localized: "海老茶")),
        PaletteColor(id: "64363C", hex: "64363C", name: String(localized: "桑染")),
        PaletteColor(id: "554236", hex: "554236", name: String(localized: "黒鳶")),
        PaletteColor(id: "E03C8A", hex: "E03C8A", name: String(localized: "躑躅")),
        PaletteColor(id: "C1328E", hex: "C1328E", name: String(localized: "牡丹")),
        PaletteColor(id: "A8497A", hex: "A8497A", name: String(localized: "梅紫")),
    ])
    }

    // MARK: - 橙・茶系

    static var jpOrange: ColorGroup {
        ColorGroup(id: "jp_orange", name: String(localized: "橙・茶"), colors: [
        PaletteColor(id: "F0A986", hex: "F0A986", name: String(localized: "宍")),
        PaletteColor(id: "FFBA84", hex: "FFBA84", name: String(localized: "洒落柿")),
        PaletteColor(id: "FB966E", hex: "FB966E", name: String(localized: "洗朱")),
        PaletteColor(id: "FB9966", hex: "FB9966", name: String(localized: "深支子")),
        PaletteColor(id: "F19483", hex: "F19483", name: String(localized: "曙")),
        PaletteColor(id: "F17C67", hex: "F17C67", name: String(localized: "珊瑚朱")),
        PaletteColor(id: "F75C2F", hex: "F75C2F", name: String(localized: "紅緋")),
        PaletteColor(id: "F05E1C", hex: "F05E1C", name: String(localized: "黄丹")),
        PaletteColor(id: "ED784A", hex: "ED784A", name: String(localized: "纁")),
        PaletteColor(id: "E79460", hex: "E79460", name: String(localized: "洗柿")),
        PaletteColor(id: "E3916E", hex: "E3916E", name: String(localized: "赤香")),
        PaletteColor(id: "E1A679", hex: "E1A679", name: String(localized: "赤白橡")),
        PaletteColor(id: "ECB88A", hex: "ECB88A", name: String(localized: "薄柿")),
        PaletteColor(id: "E9A368", hex: "E9A368", name: String(localized: "梅染")),
        PaletteColor(id: "E98B2A", hex: "E98B2A", name: String(localized: "紅鬱金")),
        PaletteColor(id: "E2943B", hex: "E2943B", name: String(localized: "朽葉")),
        PaletteColor(id: "DB8E71", hex: "DB8E71", name: String(localized: "ときがら茶")),
        PaletteColor(id: "D7B98E", hex: "D7B98E", name: String(localized: "砥粉")),
        PaletteColor(id: "CA7853", hex: "CA7853", name: String(localized: "遠州茶")),
        PaletteColor(id: "CA7A2C", hex: "CA7A2C", name: String(localized: "琥珀")),
        PaletteColor(id: "C78550", hex: "C78550", name: String(localized: "赤朽葉")),
        PaletteColor(id: "C7802D", hex: "C7802D", name: String(localized: "金茶")),
        PaletteColor(id: "C46243", hex: "C46243", name: String(localized: "照柿")),
        PaletteColor(id: "C1693C", hex: "C1693C", name: String(localized: "樺")),
        PaletteColor(id: "B9887D", hex: "B9887D", name: String(localized: "水がき")),
        PaletteColor(id: "B47157", hex: "B47157", name: String(localized: "唐茶")),
        PaletteColor(id: "B35C37", hex: "B35C37", name: String(localized: "樺茶")),
        PaletteColor(id: "B17844", hex: "B17844", name: String(localized: "枇杷茶")),
        PaletteColor(id: "B07736", hex: "B07736", name: String(localized: "丁子染")),
        PaletteColor(id: "AF5F3C", hex: "AF5F3C", name: String(localized: "江戸茶")),
        PaletteColor(id: "A35E47", hex: "A35E47", name: String(localized: "柿渋")),
        PaletteColor(id: "A0674B", hex: "A0674B", name: String(localized: "宗伝唐茶")),
        PaletteColor(id: "A36336", hex: "A36336", name: String(localized: "代赭")),
        PaletteColor(id: "9A5034", hex: "9A5034", name: String(localized: "弁柄")),
        PaletteColor(id: "994639", hex: "994639", name: String(localized: "紅鳶")),
        PaletteColor(id: "985F2A", hex: "985F2A", name: String(localized: "礪茶")),
        PaletteColor(id: "967249", hex: "967249", name: String(localized: "柴染")),
        PaletteColor(id: "947A6D", hex: "947A6D", name: String(localized: "胡桃")),
        PaletteColor(id: "8F5A3C", hex: "8F5A3C", name: String(localized: "雀茶")),
        PaletteColor(id: "884C3A", hex: "884C3A", name: String(localized: "紅檜皮")),
        PaletteColor(id: "854836", hex: "854836", name: String(localized: "檜皮")),
        PaletteColor(id: "855B32", hex: "855B32", name: String(localized: "煎茶")),
        PaletteColor(id: "82663A", hex: "82663A", name: String(localized: "銀煤竹")),
        PaletteColor(id: "7D532C", hex: "7D532C", name: String(localized: "黄櫨染")),
        PaletteColor(id: "78552B", hex: "78552B", name: String(localized: "伽羅")),
        PaletteColor(id: "724938", hex: "724938", name: String(localized: "百塩茶")),
        PaletteColor(id: "724832", hex: "724832", name: String(localized: "鳶")),
        PaletteColor(id: "6E552F", hex: "6E552F", name: String(localized: "煤竹")),
        PaletteColor(id: "6A4028", hex: "6A4028", name: String(localized: "栗皮茶")),
        PaletteColor(id: "96632E", hex: "96632E", name: String(localized: "丁子茶")),
        PaletteColor(id: "9B6E23", hex: "9B6E23", name: String(localized: "狐")),
        PaletteColor(id: "563F2E", hex: "563F2E", name: String(localized: "焦茶")),
        PaletteColor(id: "52433D", hex: "52433D", name: String(localized: "紅消鼠")),
        PaletteColor(id: "43341B", hex: "43341B", name: String(localized: "憲法染")),
        PaletteColor(id: "FC9F4D", hex: "FC9F4D", name: String(localized: "萱草")),
        PaletteColor(id: "EBB471", hex: "EBB471", name: String(localized: "薄香")),
    ])
    }

    // MARK: - 黄・金系

    static var jpYellow: ColorGroup {
        ColorGroup(id: "jp_yellow", name: String(localized: "黄・金"), colors: [
        PaletteColor(id: "FBE251", hex: "FBE251", name: String(localized: "黄蘗")),
        PaletteColor(id: "F7D94C", hex: "F7D94C", name: String(localized: "菜の花")),
        PaletteColor(id: "FFC408", hex: "FFC408", name: String(localized: "籐黄")),
        PaletteColor(id: "F7C242", hex: "F7C242", name: String(localized: "花葉")),
        PaletteColor(id: "F9BF45", hex: "F9BF45", name: String(localized: "玉子")),
        PaletteColor(id: "F6C555", hex: "F6C555", name: String(localized: "梔子")),
        PaletteColor(id: "FFB11B", hex: "FFB11B", name: String(localized: "山吹")),
        PaletteColor(id: "FAD689", hex: "FAD689", name: String(localized: "浅黄")),
        PaletteColor(id: "EFBB24", hex: "EFBB24", name: String(localized: "鬱金")),
        PaletteColor(id: "E9CD4C", hex: "E9CD4C", name: String(localized: "刈安")),
        PaletteColor(id: "E8B647", hex: "E8B647", name: String(localized: "玉蜀黍")),
        PaletteColor(id: "DDD23B", hex: "DDD23B", name: String(localized: "女郎花")),
        PaletteColor(id: "DDA52D", hex: "DDA52D", name: String(localized: "櫨染")),
        PaletteColor(id: "DCB879", hex: "DCB879", name: String(localized: "白橡")),
        PaletteColor(id: "DAC9A6", hex: "DAC9A6", name: String(localized: "鳥の子")),
        PaletteColor(id: "D9CD90", hex: "D9CD90", name: String(localized: "蒸栗")),
        PaletteColor(id: "D9AB42", hex: "D9AB42", name: String(localized: "黄朽葉")),
        PaletteColor(id: "D19826", hex: "D19826", name: String(localized: "山吹茶")),
        PaletteColor(id: "CAAD5F", hex: "CAAD5F", name: String(localized: "芥子")),
        PaletteColor(id: "C99833", hex: "C99833", name: String(localized: "桑茶")),
        PaletteColor(id: "C18A26", hex: "C18A26", name: String(localized: "黄唐茶")),
        PaletteColor(id: "BC9F77", hex: "BC9F77", name: String(localized: "白茶")),
        PaletteColor(id: "BA9132", hex: "BA9132", name: String(localized: "黄橡")),
        PaletteColor(id: "B68E55", hex: "B68E55", name: String(localized: "黄土")),
        PaletteColor(id: "B4A582", hex: "B4A582", name: String(localized: "利休白茶")),
        PaletteColor(id: "A28C37", hex: "A28C37", name: String(localized: "菜種油")),
        PaletteColor(id: "8D742A", hex: "8D742A", name: String(localized: "肥後煤竹")),
        PaletteColor(id: "897D55", hex: "897D55", name: String(localized: "利休茶")),
        PaletteColor(id: "876633", hex: "876633", name: String(localized: "媚茶")),
        PaletteColor(id: "867835", hex: "867835", name: String(localized: "黄海松茶")),
        PaletteColor(id: "7D6C46", hex: "7D6C46", name: String(localized: "生壁")),
        PaletteColor(id: "74673E", hex: "74673E", name: String(localized: "路考茶")),
        PaletteColor(id: "6C6024", hex: "6C6024", name: String(localized: "鶯茶")),
        PaletteColor(id: "62592C", hex: "62592C", name: String(localized: "海松茶")),
    ])
    }

    // MARK: - 緑系

    static var jpGreen: ColorGroup {
        ColorGroup(id: "jp_green", name: String(localized: "緑"), colors: [
        PaletteColor(id: "A8D8B9", hex: "A8D8B9", name: String(localized: "白緑")),
        PaletteColor(id: "B5CAA0", hex: "B5CAA0", name: String(localized: "裏柳")),
        PaletteColor(id: "91B493", hex: "91B493", name: String(localized: "薄青")),
        PaletteColor(id: "91AD70", hex: "91AD70", name: String(localized: "柳染")),
        PaletteColor(id: "90B44B", hex: "90B44B", name: String(localized: "鶸萌黄")),
        PaletteColor(id: "BEC23F", hex: "BEC23F", name: String(localized: "鶸")),
        PaletteColor(id: "B1B479", hex: "B1B479", name: String(localized: "麹塵")),
        PaletteColor(id: "ADA142", hex: "ADA142", name: String(localized: "青朽葉")),
        PaletteColor(id: "A5A051", hex: "A5A051", name: String(localized: "鶸茶")),
        PaletteColor(id: "939650", hex: "939650", name: String(localized: "柳茶")),
        PaletteColor(id: "89916B", hex: "89916B", name: String(localized: "梅幸茶")),
        PaletteColor(id: "86C166", hex: "86C166", name: String(localized: "苗")),
        PaletteColor(id: "838A2D", hex: "838A2D", name: String(localized: "苔")),
        PaletteColor(id: "808F7C", hex: "808F7C", name: String(localized: "柳鼠")),
        PaletteColor(id: "7BA23F", hex: "7BA23F", name: String(localized: "萌黄")),
        PaletteColor(id: "6C6A2D", hex: "6C6A2D", name: String(localized: "鶯")),
        PaletteColor(id: "646A58", hex: "646A58", name: String(localized: "岩井茶")),
        PaletteColor(id: "616138", hex: "616138", name: String(localized: "璃寛茶")),
        PaletteColor(id: "5DAC81", hex: "5DAC81", name: String(localized: "若竹")),
        PaletteColor(id: "5B622E", hex: "5B622E", name: String(localized: "海松")),
        PaletteColor(id: "516E41", hex: "516E41", name: String(localized: "青丹")),
        PaletteColor(id: "4B4E2A", hex: "4B4E2A", name: String(localized: "藍媚茶")),
        PaletteColor(id: "4D5139", hex: "4D5139", name: String(localized: "千歳茶")),
        PaletteColor(id: "4A593D", hex: "4A593D", name: String(localized: "柳煤竹")),
        PaletteColor(id: "42602D", hex: "42602D", name: String(localized: "松葉")),
        PaletteColor(id: "36563C", hex: "36563C", name: String(localized: "千歳緑")),
        PaletteColor(id: "227D51", hex: "227D51", name: String(localized: "緑")),
        PaletteColor(id: "1B813E", hex: "1B813E", name: String(localized: "常磐")),
        PaletteColor(id: "6A8372", hex: "6A8372", name: String(localized: "老竹")),
        PaletteColor(id: "2D6D4B", hex: "2D6D4B", name: String(localized: "木賊")),
        PaletteColor(id: "465D4C", hex: "465D4C", name: String(localized: "御納戸茶")),
        PaletteColor(id: "24936E", hex: "24936E", name: String(localized: "緑青")),
        PaletteColor(id: "86A697", hex: "86A697", name: String(localized: "錆青磁")),
        PaletteColor(id: "00896C", hex: "00896C", name: String(localized: "青竹")),
        PaletteColor(id: "096148", hex: "096148", name: "ビロード"),
        PaletteColor(id: "20604F", hex: "20604F", name: String(localized: "虫襖")),
        PaletteColor(id: "0F4C3A", hex: "0F4C3A", name: String(localized: "藍海松茶")),
        PaletteColor(id: "00AA90", hex: "00AA90", name: String(localized: "青緑")),
        PaletteColor(id: "69B0AC", hex: "69B0AC", name: String(localized: "青磁")),
        PaletteColor(id: "4F726C", hex: "4F726C", name: String(localized: "沈香茶")),
        PaletteColor(id: "26453D", hex: "26453D", name: String(localized: "鉄")),
    ])
    }

    // MARK: - 青・藍系

    static var jpBlue: ColorGroup {
        ColorGroup(id: "jp_blue", name: String(localized: "青・藍"), colors: [
        PaletteColor(id: "A5DEE4", hex: "A5DEE4", name: String(localized: "瓶覗")),
        PaletteColor(id: "81C7D4", hex: "81C7D4", name: String(localized: "水")),
        PaletteColor(id: "78C2C4", hex: "78C2C4", name: String(localized: "白群")),
        PaletteColor(id: "7DB9DE", hex: "7DB9DE", name: String(localized: "勿忘草")),
        PaletteColor(id: "66BAB7", hex: "66BAB7", name: String(localized: "水浅葱")),
        PaletteColor(id: "58B2DC", hex: "58B2DC", name: String(localized: "空")),
        PaletteColor(id: "51A8DD", hex: "51A8DD", name: String(localized: "群青")),
        PaletteColor(id: "33A6B8", hex: "33A6B8", name: String(localized: "浅葱")),
        PaletteColor(id: "2EA9DF", hex: "2EA9DF", name: String(localized: "露草")),
        PaletteColor(id: "3A8FB7", hex: "3A8FB7", name: String(localized: "千草")),
        PaletteColor(id: "1E88A8", hex: "1E88A8", name: String(localized: "花浅葱")),
        PaletteColor(id: "0089A7", hex: "0089A7", name: String(localized: "新橋")),
        PaletteColor(id: "268785", hex: "268785", name: String(localized: "青碧")),
        PaletteColor(id: "77969A", hex: "77969A", name: String(localized: "深川鼠")),
        PaletteColor(id: "6699A1", hex: "6699A1", name: String(localized: "錆浅葱")),
        PaletteColor(id: "577C8A", hex: "577C8A", name: String(localized: "舛花")),
        PaletteColor(id: "566C73", hex: "566C73", name: String(localized: "藍鼠")),
        PaletteColor(id: "405B55", hex: "405B55", name: String(localized: "錆鉄御納戸")),
        PaletteColor(id: "376B6D", hex: "376B6D", name: String(localized: "御召茶")),
        PaletteColor(id: "336774", hex: "336774", name: String(localized: "錆御納戸")),
        PaletteColor(id: "305A56", hex: "305A56", name: String(localized: "高麗納戸")),
        PaletteColor(id: "2E5C6E", hex: "2E5C6E", name: String(localized: "御召御納戸")),
        PaletteColor(id: "2B5F75", hex: "2B5F75", name: String(localized: "熨斗目花")),
        PaletteColor(id: "255359", hex: "255359", name: String(localized: "鉄御納戸")),
        PaletteColor(id: "0C4842", hex: "0C4842", name: String(localized: "御納戸")),
        PaletteColor(id: "0D5661", hex: "0D5661", name: String(localized: "藍")),
        PaletteColor(id: "006284", hex: "006284", name: String(localized: "縹")),
        PaletteColor(id: "005CAF", hex: "005CAF", name: String(localized: "瑠璃")),
        PaletteColor(id: "7B90D2", hex: "7B90D2", name: String(localized: "紅碧")),
        PaletteColor(id: "113285", hex: "113285", name: String(localized: "紺青")),
        PaletteColor(id: "0B346E", hex: "0B346E", name: String(localized: "瑠璃紺")),
        PaletteColor(id: "0F2540", hex: "0F2540", name: String(localized: "紺")),
        PaletteColor(id: "08192D", hex: "08192D", name: String(localized: "褐")),
        PaletteColor(id: "0B1013", hex: "0B1013", name: String(localized: "黒橡")),
    ])
    }

    // MARK: - 紫・藤系

    static var jpPurple: ColorGroup {
        ColorGroup(id: "jp_purple", name: String(localized: "紫・藤"), colors: [
        PaletteColor(id: "B28FCE", hex: "B28FCE", name: String(localized: "薄")),
        PaletteColor(id: "B481BB", hex: "B481BB", name: String(localized: "紅藤")),
        PaletteColor(id: "9B90C2", hex: "9B90C2", name: String(localized: "楝")),
        PaletteColor(id: "8F77B5", hex: "8F77B5", name: String(localized: "紫苑")),
        PaletteColor(id: "8B81C3", hex: "8B81C3", name: String(localized: "藤")),
        PaletteColor(id: "8A6BBE", hex: "8A6BBE", name: String(localized: "藤紫")),
        PaletteColor(id: "986DB2", hex: "986DB2", name: String(localized: "半")),
        PaletteColor(id: "6E75A4", hex: "6E75A4", name: String(localized: "藤鼠")),
        PaletteColor(id: "70649A", hex: "70649A", name: String(localized: "二藍")),
        PaletteColor(id: "6A4C9C", hex: "6A4C9C", name: String(localized: "桔梗")),
        PaletteColor(id: "77428D", hex: "77428D", name: String(localized: "江戸紫")),
        PaletteColor(id: "6F3381", hex: "6F3381", name: String(localized: "菖蒲")),
        PaletteColor(id: "66327C", hex: "66327C", name: String(localized: "菫")),
        PaletteColor(id: "4E4F97", hex: "4E4F97", name: String(localized: "紅掛花")),
        PaletteColor(id: "592C63", hex: "592C63", name: String(localized: "紫")),
        PaletteColor(id: "4A225D", hex: "4A225D", name: String(localized: "深紫")),
        PaletteColor(id: "622954", hex: "622954", name: String(localized: "杜若")),
        PaletteColor(id: "6D2E5B", hex: "6D2E5B", name: String(localized: "蒲葡")),
        PaletteColor(id: "572A3F", hex: "572A3F", name: String(localized: "茄子紺")),
        PaletteColor(id: "562E37", hex: "562E37", name: String(localized: "似紫")),
        PaletteColor(id: "574C57", hex: "574C57", name: String(localized: "藤煤竹")),
        PaletteColor(id: "5E3D50", hex: "5E3D50", name: String(localized: "葡萄鼠")),
        PaletteColor(id: "533D5B", hex: "533D5B", name: String(localized: "滅紫")),
        PaletteColor(id: "3C2F41", hex: "3C2F41", name: String(localized: "紫紺")),
        PaletteColor(id: "3F2B36", hex: "3F2B36", name: String(localized: "黒紅")),
        PaletteColor(id: "261E47", hex: "261E47", name: String(localized: "鉄紺")),
        PaletteColor(id: "211E55", hex: "211E55", name: String(localized: "紺桔梗")),
        PaletteColor(id: "60373E", hex: "60373E", name: String(localized: "紫鳶")),
        PaletteColor(id: "72636E", hex: "72636E", name: String(localized: "鳩羽鼠")),
    ])
    }

    // MARK: - 白・灰・黒

    static var jpNeutral: ColorGroup {
        ColorGroup(id: "jp_neutral", name: String(localized: "白・灰・黒"), colors: [
        PaletteColor(id: "FFFFFB", hex: "FFFFFB", name: String(localized: "胡粉")),
        PaletteColor(id: "FCFAF2", hex: "FCFAF2", name: String(localized: "白練")),
        PaletteColor(id: "BDC0BA", hex: "BDC0BA", name: String(localized: "白鼠")),
        PaletteColor(id: "91989F", hex: "91989F", name: String(localized: "銀鼠")),
        PaletteColor(id: "877F6C", hex: "877F6C", name: String(localized: "灰汁")),
        PaletteColor(id: "828282", hex: "828282", name: String(localized: "灰")),
        PaletteColor(id: "787D7B", hex: "787D7B", name: String(localized: "素鼠")),
        PaletteColor(id: "787878", hex: "787878", name: String(localized: "鉛")),
        PaletteColor(id: "707C74", hex: "707C74", name: String(localized: "利休鼠")),
        PaletteColor(id: "656765", hex: "656765", name: String(localized: "鈍")),
        PaletteColor(id: "535953", hex: "535953", name: String(localized: "青鈍")),
        PaletteColor(id: "4F4F48", hex: "4F4F48", name: String(localized: "溝鼠")),
        PaletteColor(id: "434343", hex: "434343", name: String(localized: "消炭")),
        PaletteColor(id: "373C38", hex: "373C38", name: String(localized: "藍墨茶")),
        PaletteColor(id: "3A3226", hex: "3A3226", name: String(localized: "檳榔子染")),
        PaletteColor(id: "1C1C1C", hex: "1C1C1C", name: String(localized: "墨")),
        PaletteColor(id: "0C0C0C", hex: "0C0C0C", name: String(localized: "呂")),
        PaletteColor(id: "080808", hex: "080808", name: String(localized: "黒")),
    ])
    }
}
