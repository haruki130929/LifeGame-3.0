// File: Motivation/MotivationModels.swift
import Foundation

enum MotivationScenario: String, Identifiable, CaseIterable, Hashable {
    case first_step_action
    case ten_second_action
    case preparation_beforehand
    case location_anchoring
    case habit_stacking
    case physical_activation
    case desk_organization
    case digital_declutter
    case remove_actioin_brake
    case restart_cue
    case tomorrow_three_tasks
    case mind_dump
    case one_minute_reset
    case mood_consistency
    case exception_theory
    case optimal_stress
    case self_deadline
    case worst_case_visualization
    case reward_system
    case excuse_rewriting
    case past_self_comparison
    case ten_second_selfesteem
    case time_tracking
    case five_block_schedule
    case fifteen_minute_timer
    case serious_thirty
    case mood_reset_methods
    case fantasy_goal
    case desire_recognition
    case three_inner_voices
    case value_based_purpose
    case three_milestones
    case action_breakdown
    case goal_update_rule
    case self_identity_steps
    case weekly_review
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .first_step_action: return "初步決定、初步行動"
        case .ten_second_action: return "10秒行動"
        case .preparation_beforehand: return "前一天先做一點"
        case .location_anchoring: return "在相同地點做相同的事"
        case .habit_stacking: return "用舊習慣綁新習慣"
        case .physical_activation: return "感覺沒動力時先動一動"
        case .desk_organization: return "決定桌面物品固定位置"
        case .digital_declutter: return "每月整理電腦桌面"
        case .remove_actioin_brake: return "行動煞車器"
        case .restart_cue: return "工作中斷時寫第一步"
        case .tomorrow_three_tasks: return "每天結束時寫隔天三件事"
        case .mind_dump: return "無法專注時把在意的事情寫下來"
        case .one_minute_reset: return "感到壓力時閉眼 1 分鐘"
        case .mood_consistency: return "情緒一致性"
        case .exception_theory: return "把挫折視為特例"
        case .optimal_stress: return "適度壓力"
        case .self_deadline: return "設期限"
        case .worst_case_visualization: return "最糟情境具體化"
        case .reward_system: return "設獎勵"
        case .excuse_rewriting: return "藉口替換"
        case .past_self_comparison: return "與自己的過去比較"
        case .ten_second_selfesteem: return "十秒提升自我肯定"
        case .time_tracking: return "時間記帳"
        case .five_block_schedule: return "五大時段時間表"
        case .fifteen_minute_timer: return "工作切成 15 分鐘"
        case .serious_thirty: return "認真 30 分鐘"
        case .mood_reset_methods: return "情緒轉換方法"
        case .fantasy_goal: return "異想天開目標"
        case .desire_recognition: return "訂定目標 1：慾望"
        case .three_inner_voices: return "訂定目標 2：三種聲音"
        case .value_based_purpose: return "設定目的：價值觀"
        case .three_milestones: return "三個里程碑"
        case .action_breakdown: return "分解行動"
        case .goal_update_rule: return "目標達成八成就換新"
        case .self_identity_steps: return "三階段自我認知"
        case .weekly_review: return "回顧筆記"
        }
    }
    
    var subtitle: String {
        switch self {
        case .first_step_action: return "完美主義、訂定計畫後就結束的人"
        case .ten_second_action: return "獲得指示就能立刻行動的人"
        case .preparation_beforehand: return "需要花時間才能著手做事的人"
        case .location_anchoring: return "煩惱多工處理的人"
        case .habit_stacking: return "不擅長持續做一件事、想挑戰新事物的人"
        case .physical_activation: return "容易意志消沉的人"
        case .desk_organization: return "常常在找東西、會把不用的東西擺桌上的人"
        case .digital_declutter: return "電腦桌面塞滿圖示、花很多時間找資料的人"
        case .remove_actioin_brake: return "常常「心不甘情不願」做事、靠義務感和責任感行動的人"
        case .restart_cue: return "想在被打斷後快速回到工作狀態的人"
        case .tomorrow_three_tasks: return "只要早上一挫折整天都會受影響的人"
        case .mind_dump: return "該做的事情太多、會在意其他事情而無法專注的人"
        case .one_minute_reset: return "不擅長應付正式場合、容易精神緊繃的人"
        case .mood_consistency: return "心情好壞會大幅影響看事情角度的人"
        case .exception_theory: return "很在意失敗、容易整體否定自己的時候"
        case .optimal_stress: return "不小心就會太放縱自己的人"
        case .self_deadline: return "不到最後一刻不肯動手、常把自己排在最後的人"
        case .worst_case_visualization: return "總是拖到最後一刻才行動、太樂觀預估狀況的人"
        case .reward_system: return "需要外在獎勵才比較有動力的人"
        case .excuse_rewriting: return "很會找藉口、習慣逃避的人"
        case .past_self_comparison: return "看社群網站容易沮喪、容易嫉妒他人的人"
        case .ten_second_selfesteem: return "想加強自我肯定感的人"
        case .time_tracking: return "回過神時時間已經過去、維持現狀就很辛苦的人"
        case .five_block_schedule: return "被待辦清單追著跑、忙到毫無從容的人"
        case .fifteen_minute_timer: return "想要更加專注、讓工作張弛有度的人"
        case .serious_thirty: return "遲遲無法著手想做之事的人"
        case .mood_reset_methods: return "容易沮喪、容易累積壓力的人"
        case .fantasy_goal: return "有夢想或目標、被眼前事情耗盡力氣的人"
        case .desire_recognition: return "想面對自己慾望、或總是在壓抑慾望的人"
        case .three_inner_voices: return "在「自己心情」與「常識與社會觀感」之間拉扯的人"
        case .value_based_purpose: return "想釐清自己最重要的價值觀的人"
        case .three_milestones: return "需要規劃路線朝目標前進的人"
        case .action_breakdown: return "容易只用很大範圍在想事情的人"
        case .goal_update_rule: return "常常只顧眼前、很少更新長期目標的人"
        case .self_identity_steps: return "想提升自我認知、整理自我形象的人"
        case .weekly_review: return "想用一週為單位穩定回顧的人"
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .first_step_action:
            return ["寫下今天「一定要做」的最多三件事，其它放到明天或之後。","只做最小的一步，例如：只打開講義、只寫標題。","用 15 分鐘計時器，只在這 15 分鐘專心做一件小事。"]
        case .ten_second_action:
            return ["告訴自己：先連續行動 10 秒鐘，例如站起來、走到書桌、打開書。","把第一步寫得非常具體，像是「按下播放鍵」、「打開檔案」。","一旦開始 10 秒，就允許自己多做一點點，但沒有壓力。"]
        case .preparation_beforehand:
            return ["睡前先準備好明天要用的物品，例如：課本、筆袋、水壺。","前一天先完成 5 分鐘的「暖身」，例如先看一小段內容。","把「明天的第一步」寫在便條紙上，放在桌上顯眼的地方。"]
        case .location_anchoring:
            return ["替每一個重要活動選一個固定地點，例如：只在某張桌子寫作業。","避免在「休息用的位置」做工作，讓大腦更容易分辨模式。","在固定地點準備好專用工具，減少來回拿東西的時間。"]
        case .habit_stacking:
            return ["先找出一個已經很穩定的舊習慣，例如：吃完晚餐、刷牙後。","把新習慣設計成接在舊習慣之後的一個小動作，例如：刷牙後寫三行日記。","先從非常小的版本開始，成功幾天後再慢慢加長時間。"]
        case .physical_activation:
            return ["先做 30 秒到 1 分鐘的伸展或原地踏步，讓身體醒來。","換個姿勢：從躺著滑手機改成坐在桌前，先不要求立刻工作。","喝一點水或洗臉，給身體一個「要切換模式了」的訊號。"]
        case .desk_organization:
            return ["決定每樣常用物品的「家」，例如：筆袋、平板、充電線固定位置。","桌面只保留當天要用的東西，其餘收進抽屜或盒子裡。","每天結束前花 3 分鐘，把桌面快速恢復到「基本版」。"]
        case .digital_declutter:
            return ["每個月選一天，整理電腦桌面與下載資料夾。","建立幾個固定資料夾分類，不要太細，讓自己容易放東西。","把當週重要檔案放在一個「本週工作」資料夾，結束後再歸檔。"]
        case .remove_actioin_brake:
            return ["寫下「現在不想做的三個理由」，幫助看見真正的行動煞車器。","試著把理由改寫成需求，例如「很累」→「需要先休息 10 分鐘」。","在想到義務感之前，先問自己：這件事對未來的我有什麼幫助。"]
        case .restart_cue:
            return ["在被打斷前，快速寫下一行「下一步要做什麼」。","回來時先讀這一句話，再回到內容本身。","也可以用便利貼貼在桌面，讓視線一回來就看到。"]
        case .tomorrow_three_tasks:
            return ["每天結束前寫下「明天三件最重要的事」。","避免寫超過三件，如果有第四件就放到「備選」。","隔天早上先看這張清單，再開啟其它 App。"]
        case .mind_dump:
            return ["用計時器給自己 5 分鐘，把腦中在意的事全部寫下來。","寫完後用符號標記：現在要處理／可以延期／其實只是擔心。","選一件可以在 5 分鐘內處理的小事，先完成它當作開場。"]
        case .one_minute_reset:
            return ["坐好、閉上眼睛，專心感受呼吸 1 分鐘。","在心裡默數吸氣與吐氣的節奏，讓注意力從壓力抽離。","一分鐘後再問自己：現在真正需要的是什麼。"]
        case .mood_consistency:
            return ["在心情好的時候，寫下幾句想給心情差的自己的提醒。","當情緒很低落時，先看那幾句話，再決定今天要不要調整目標。","練習把「今天很糟」改寫成「今天只是比較難」。"]
        case .exception_theory:
            return ["當出現一次失敗或中斷，告訴自己：這是特例，不代表全部。","回頭看看最近一週的努力紀錄，幫自己放回長期軸線上。","寫下一句：即使今天做不好，明天還是可以繼續。"]
        case .optimal_stress:
            return ["替自己設定一點點壓力，例如：告訴朋友今天要完成什麼。","避免把行程塞滿，保留空白時間讓身體恢復。","觀察自己在壓力 1～10 分的哪個區間最有精神。"]
        case .self_deadline:
            return ["為任務設定「自己的期限」，比正式截止日提前幾天。","在行事曆上標出這個期限，當成真正的 deadline 看待。","如果超過自己設定的期限，要回頭檢查：哪個環節拖住了我。"]
        case .worst_case_visualization:
            return ["寫下最糟可能發生的情況，再寫下一行：真的發生時我要怎麼應對。","把「可能失敗」變成可以被處理的具體情境，而不是模糊的恐懼。","看完之後問自己：在這之前，我可以先做什麼預防。"]
        case .reward_system:
            return ["為自己設計小獎勵：完成一個區塊就可以休息或做喜歡的事。","讓獎勵和努力的大小大致相配，不要太重也不要太輕。","把獎勵寫下來，讓自己在做事時能記得前方有好事情在等。"]
        case .excuse_rewriting:
            return ["把常出現的藉口寫下來，例如「我現在太累」。","在旁邊改寫成新的句子：「我可以先做 5 分鐘再休息」。","每次發現自己又用舊藉口時，練習改用新的版本。"]
        case .past_self_comparison:
            return ["把比較的對象從「別人」換成「過去的自己」。","寫下這一週自己做過的三件小事，而不是看還沒做到什麼。","限制自己滑社群的時間，改成多看一點自己的紀錄。"]
        case .ten_second_selfesteem:
            return ["花 10 秒寫下今天做得不錯的三件小事，就算很小也算。","練習把「運氣好」改寫成「有努力的一部分在裡面」。","每天睡前看一次這些紀錄，累積對自己的好感。"]
        case .time_tracking:
            return ["用簡單方式記錄今天每半小時在做什麼，不需要太細。","一天結束後，看哪一段時間最容易分心，之後優先處理那一段。","先理解時間怎麼被用掉，再來談要如何調整。"]
        case .five_block_schedule:
            return ["把一天切成大約五個時段，例如早上、下午、晚上等。","為每一個時段設定「主題」，而不是一堆零散待辦。","每天只微調一點，不需要一次排到完美。"]
        case .fifteen_minute_timer:
            return ["把工作切成多個 15 分鐘的小段。","每 15 分鐘專注一件事，結束後休息 3～5 分鐘。","對很抗拒的任務，可以先承諾自己只做一個 15 分鐘。"]
        case .serious_thirty:
            return ["選一段 30 分鐘當成「認真時段」，關掉通知、遠離手機。","在這 30 分鐘內只處理一個主題，不再切換。","結束後給自己明確的獎勵或休息。"]
        case .mood_reset_methods:
            return ["列出 5 種對自己有用的情緒轉換方法，例如散步、洗澡、聽歌。","當壓力升高時先從其中一種開始，而不是硬把自己壓在桌前。","用紀錄方式觀察：哪一種對自己最有效。"]
        case .fantasy_goal:
            return ["寫下一個「看起來很不現實」但讓自己很心動的目標。","試著問：如果真的要靠近一點點，最小的一步會是什麼。","允許自己保留這個夢想，不一定要立刻變成具體計畫。"]
        case .desire_recognition:
            return ["列出自己最近真正想要的東西，不用管現實條件。","從中選一項，想一個安全的小實驗去靠近它。","練習承認慾望本身是存在的，而不是馬上評價好或壞。"]
        case .three_inner_voices:
            return ["寫下三種聲音：想做的我／害怕的我／別人眼中的期待。","分開看這三種聲音，而不是全部混在一起。","試著讓「想做的我」也有被聽見的空間。"]
        case .value_based_purpose:
            return ["列出自己最重視的三個價值，例如自由、成就、陪伴。","問自己：這件事和哪一個價值有關聯。","當與價值觀連在一起時，動力通常會比較穩定。"]
        case .three_milestones:
            return ["把大目標切成三個明顯的里程碑。","為每個里程碑寫下一句：「達到時代表什麼」。","先專心往第一個里程碑走，不用一次想到終點。"]
        case .action_breakdown:
            return ["把模糊的大任務寫成一條條具體動作，例如「搜尋關鍵字」、「列出大綱」。","確認每一步都可以在 10～30 分鐘內完成。","每完成一步就劃掉，讓自己看見進度。"]
        case .goal_update_rule:
            return ["當目標達成約八成時，允許自己調整或升級目標。","定期問自己：這個目標還適合現在的我嗎。","把「更新目標」當作成長的證據，而不是不穩定。"]
        case .self_identity_steps:
            return ["寫下現在哪些身份對自己很重要，例如學生、朋友、創作者。","想像三年後理想中的自己，會怎麼形容自己的身份。","從中挑一個身份，找一個最小行動去靠近它。"]
        case .weekly_review:
            return ["每週選一個固定時間，回顧這一週做了什麼。","寫下三件做得不錯的事，和一件想調整的事。","順便看看下週有什麼需要提前準備的。"]
        }
    }
}
