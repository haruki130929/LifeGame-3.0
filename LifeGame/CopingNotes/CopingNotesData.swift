import Foundation

struct CopingNote: Identifiable {
    let id = UUID()
    let method: String
    let situations: [String]
    let suggestions: [String]
}

enum CopingNotesData {

    /// CopingNote 的 id 是 `let id = UUID()`，每次重建都會產生新的 id，
    /// 直接用 computed var 會讓 SwiftUI 的 ForEach 每次都認為整份清單換了一批項目
    /// （畫面閃爍、捲動位置與展開狀態流失）。所以這裡以「語言」為 key 快取：
    /// 語言沒變就回傳同一批物件，語言變了才重建一次。
    nonisolated(unsafe) private static var cache: (language: String, notes: [CopingNote])?

    static var all: [CopingNote] {
        if let cached = cache, cached.language == AppLocalization.languageID {
            return cached.notes
        }
        let notes = build
        cache = (AppLocalization.languageID, notes)
        return notes
    }

    private static var build: [CopingNote] {
        [
        CopingNote(
            method: String(localized: "初步決定、初步行動"),
            situations: [String(localized: "完美主義"), String(localized: "訂定計劃後就結束的人")],
            suggestions: [
            String(localized: "就算只是初步想法，也在決定「現在要做這個」之後實際嘗試"),
            String(localized: "重「質」在重「量」：重點在於要先增加「行動量」，接著再提升「行動品質」"),
            String(localized: "不順利不代表失敗，而是「採取行動後得到的成果」")
            ]
        ),
        CopingNote(
            method: String(localized: "怎樣都無法踏出第一步時，試著就先行動10秒看看"),
            situations: [String(localized: "獲得指示就能立刻行動的人"), String(localized: "訂定計畫後就結束的人")],
            suggestions: [
            String(localized: "把第一步拆分到「10秒就能辦到的行動」"),
            String(localized: "把最初的第一步門檻調到最低"),
            String(localized: "10秒行動：試著從10秒就能做到的事情開始動起")
            ]
        ),
        CopingNote(
            method: String(localized: "麻煩的事情在前一天就先做一點"),
            situations: [String(localized: "工作需要大量動腦的人"), String(localized: "需要花時間才能著手做事的人")],
            suggestions: [
            String(localized: "只要事前稍微做點準備，就能讓怕麻煩的大腦將「未知」判斷為「已知」，讓大腦與想維持現狀的防衛本能對抗")
            ]
        ),
        CopingNote(
            method: String(localized: "在相同地點做相同的事"),
            situations: [String(localized: "煩惱多工處理的人"), String(localized: "公司或家裡太吵沒辦法工作的人")],
            suggestions: [
            String(localized: "首先，在公司或家裡附近找到讓你容易工作的地點"),
            String(localized: "在相同地點做相同的事，就能逐漸讓大腦形成既定印象，接著只要不停重複相同動作，就能更近一步強化這個印象"),
            String(localized: "定錨效應，可以應用在場所、時間上")
            ]
        ),
        CopingNote(
            method: String(localized: "當想要培養新習慣時，就把它和既有習慣綁在一起"),
            situations: [String(localized: "不擅長持續做一件事的人"), String(localized: "想挑戰新事物的人")],
            suggestions: [
            String(localized: "把「刷牙」這類每天都會做的事情列成清單"),
            String(localized: "不是從零養出一個新習慣，而是借助舊習慣的力量開始行動"),
            String(localized: "重點在明確定出舊習慣的行動結尾，以及想養成新習慣的行動開頭")
            ]
        ),
        CopingNote(
            method: String(localized: "感覺提不起勁時，就先試著活動身體"),
            situations: [String(localized: "容易意志消沉的人"), String(localized: "常坐辦公室的人")],
            suggestions: [
            String(localized: "一開始就要決定好「感覺提不起勁時，要怎樣活動身體」")
            ]
        ),
        CopingNote(
            method: String(localized: "情緒一致性效應：當心情很好時容易看見事物樂觀的一面，當心情很差時就容易看見事物悲觀的一面"),
            situations: [],
            suggestions: [
            String(localized: "早上怎麼過，是決定一天行動的重要元素"),
            String(localized: "起床後到開始工作之間的時間，把自己很期待的事情，或是能讓自己感到心情愉悅的事情，編排進每日固定行程中")
            ]
        ),
        CopingNote(
            method: String(localized: "行動煞車器"),
            situations: [],
            suggestions: [
            String(localized: "①找出原因，排除阻礙因素②聚焦在目的上，將阻礙因素的影響降到最低")
            ]
        ),
        CopingNote(
            method: String(localized: "明確決定好桌上物品的位置"),
            situations: [String(localized: "常常在找東西的人"), String(localized: "會把現在不用的東西擺桌上的人")],
            suggestions: [
            String(localized: "決定好最常使用的五項物品的固定位置"),
            String(localized: "決定好文具、文件中最常用到的幾項東西，在桌上或是抽屜裡的固定位置")
            ]
        ),
        CopingNote(
            method: String(localized: "每個月整理一次電腦桌面"),
            situations: [String(localized: "電腦桌面塞滿圖示的人"), String(localized: "花很多時間找資料的人")],
            suggestions: [
            String(localized: "先試著刪除幾個已經不用的檔案"),
            String(localized: "先設定好每個月一次固定整理電腦桌面的日子"),
            String(localized: "接著刪除不需要的檔案或資料夾，刪除後新建下列五個資料夾 ①保存、參照用 ②已結束（今後再使用的可能性很低，但沒辦法立刻丟棄的檔案） ③本週所需的檔案 ④本週用不到，但與現在工作有關的檔案 ⑤ ①～④以外的其他檔案"),
            String(localized: "只將③「本週所需的檔案」擺在電腦桌面上，其他四個放在桌面以外的地方"),
            String(localized: "在⑤的資料夾裡，以「年月份」命名檔案")
            ]
        ),
        CopingNote(
            method: String(localized: "當工作被中斷時，先把重新開始時要做的第一件事寫下來"),
            situations: [String(localized: "訪客或電話很多的人"), String(localized: "想立刻專注在工作上的人")],
            suggestions: [
            String(localized: "準備專用的便利貼"),
            String(localized: "十秒指令筆記：要以「現在立刻〇〇」的句型書寫，建議貼在滑鼠或電腦螢幕上，回到座位時會立刻看見的地方")
            ]
        ),
        CopingNote(
            method: String(localized: "每天工作結束時，先想好明天要做哪些工作並寫下來"),
            situations: [String(localized: "花很多時間才有辦法正式著手的人"), String(localized: "只要早上一挫折"), String(localized: "整天都會受影響的人")],
            suggestions: [
            String(localized: "在下班時初步決定好「明天一大早要做的事情」"),
            String(localized: "早上首要指令筆記： 步驟①工作結束時，確認「明天的行程」：確認明天該做的事情、想做的事情等 步驟②決定好「明天的工作目標」：詢問自己「明天的事情的目的是？」、「為了讓明天變成完美的一天，我實際上要怎麼做？」 步驟③初步決定實現目標的三個「關鍵工作」：訂出三個為了實現步驟二目標的關鍵工作，並寫下來 步驟④隔天開始工作時，就從三個關鍵工作中選擇一個著手")
            ]
        ),
        CopingNote(
            method: String(localized: "當三心二意無法專注時，把在意的事情全寫下來"),
            situations: [String(localized: "該做的事情太多的人"), String(localized: "會在意其他事情而無法專注的人")],
            suggestions: [
            String(localized: "養成出現什麼在意的事情時，立刻寫下來的習慣"),
            String(localized: "步驟①想到什麼「在意的事情」就全部寫在紙上 步驟②看著寫下來的事項，逐一寫上應對方法"),
            String(localized: "「後設認知」：客觀地認知自己對事物的認知")
            ]
        ),
        CopingNote(
            method: String(localized: "感覺快要挫折時，就將事情視為個案、特例"),
            situations: [String(localized: "要花時間才有辦法從失敗中振作的人"), String(localized: "只要沒做出成果就會立刻沮喪的人")],
            suggestions: [
            String(localized: "聚焦在「行動」而非「結果」上"),
            String(localized: "把順遂的事情視為正常，把不順遂的事情當作特例")
            ]
        ),
        CopingNote(
            method: String(localized: "感到壓力時，閉眼一分鐘斷絕所有資訊"),
            situations: [String(localized: "不擅長應付正式上場的人"), String(localized: "容易精神緊繃的人")],
            suggestions: [
            String(localized: "試著意識自己現在的心理狀態"),
            String(localized: "舒緩緊張的方法：閉眼一分鐘"),
            String(localized: "阻斷視覺獲得的資訊，能大幅減少帶給大腦的負擔，得以緩解緊張感")
            ]
        ),
        CopingNote(
            method: String(localized: "太放鬆時要適度給自己壓力"),
            situations: [String(localized: "因為遠距工作而變得懶散的人"), String(localized: "不小心就會太放縱自己的人")],
            suggestions: [
            String(localized: "要是太放鬆，就請回想「對自己有所期待的人」的臉"),
            String(localized: "創造適度緊張感最有效的，就是「他人對自己有所期待」的感覺"),
            String(localized: "「比馬龍效應」：當人受到稱讚時或備受矚目時，就有做出眾所期待成果的傾向"),
            String(localized: "就算只是自己想像出來的「期待」與「矚目」，也有同等效果")
            ]
        ),
        CopingNote(
            method: String(localized: "和自己的約定也要設定「期限」"),
            situations: [String(localized: "不到最後一刻不肯動手的人"), String(localized: "不小心就把自己擺最後的人")],
            suggestions: [
            String(localized: "把「自己決定的期限」當作「和VIP之間的約定」"),
            String(localized: "把自己設下的期限，以寫進行事曆等方式具體化")
            ]
        ),
        CopingNote(
            method: String(localized: "準備多個計劃消滅「意外」"),
            situations: [String(localized: "遇到突發狀況會驚惶失措的人"), String(localized: "常遇到「計劃挫敗」的人")],
            suggestions: [
            String(localized: "預想無法照計劃進行的狀況，並建立對策"),
            String(localized: "一開始就要預期意料之外的狀況，並準備好數個方案"),
            String(localized: "事先準備好數個方案，就算發生意外狀況，還是能「照計劃」完成事情")
            ]
        ),
        CopingNote(
            method: String(localized: "當怎麼樣都無法行動時，就將最糟的狀況具體化"),
            situations: [String(localized: "總是拖到最後一刻才行動的人"), String(localized: "太樂觀預估狀況的人")],
            suggestions: [
            String(localized: "把不立刻行動會增加的「風險」寫出來"),
            String(localized: "行動的理由：「迴避痛苦」（為了迴避討厭的事情而採取行動）、「追求快感」（「想要」的慾望）"),
            String(localized: "迴避痛苦：試著明確將對你來說更強烈的「如果不立刻做，未來可能會出現的痛苦」寫下來")
            ]
        ),
        CopingNote(
            method: String(localized: "設定獎勵提供自己動力"),
            situations: [String(localized: "常常「心不甘情不願做事的人」"), String(localized: "靠義務感和責任感行動的人")],
            suggestions: [
            String(localized: "製作想送給自己的「獎勵清單」"),
            String(localized: "試著從想像「最棒的成果」開始做起"),
            String(localized: "「心理演練」")
            ]
        ),
        CopingNote(
            method: String(localized: "聲音是種波動，會直接影響我們的身心狀態。即使是自己發出的聲音，只要是擾亂步調的聲音，就會增加焦躁與不耐"),
            situations: [],
            suggestions: []
        ),
        CopingNote(
            method: String(localized: "當姿勢端正時，脊髓的神經迴路傳導會變得更流暢，脊髓集結了人體的重要神經，也被稱為第二個大腦，姿勢端正時，就能讓神經傳導更流暢。第二是讓氣管暢通，可以加強呼吸的深度，這樣會讓血液循環變好，大腦的供氧量變多，專注力自然提升"),
            situations: [],
            suggestions: []
        ),
        CopingNote(
            method: String(localized: "當感覺快要被結果牽著鼻子走時，利用「打擊率」來思考"),
            situations: [String(localized: "情緒容易因結果潮起潮落的人"), String(localized: "會不停思考眼前事物的人")],
            suggestions: [
            String(localized: "試著回顧過去三個月的成果"),
            String(localized: "不管是工作還是生活都請試著擁有只要五次打中一次，剩下的全部三振或滾地球都無所謂的心態"),
            String(localized: "訣竅就是要用一週、一個月、半年等時間來思考事情"),
            String(localized: "用寬廣的視野檢視自己整體表現稱為「俯瞰」，只要培養出這種俯瞰的視角，情緒就不會因眼前的結果或成果過度起伏，而能逐步累積自己的行動")
            ]
        ),
        CopingNote(
            method: String(localized: "當事事不順時，就縮小尺規的標準"),
            situations: [String(localized: "容易沮喪的人"), String(localized: "近期狀況一直很不好的人")],
            suggestions: [
            String(localized: "從自己的行動中抽出「單一部分」來"),
            String(localized: "如果尺規的標準級距太大，就沒辦法看到單一部分"),
            String(localized: "可以盡量把尺規的標準級距細分，養成發現微小變化、成果、結果的習慣")
            ]
        ),
        CopingNote(
            method: String(localized: "關注「做到哪些」而非「沒做到哪些」"),
            situations: [String(localized: "自我肯定感低落的人"), String(localized: "完美主義的人")],
            suggestions: [
            String(localized: "試著把「做到的事情」寫下來"),
            String(localized: "不管多細微都沒關係，請試著把所有「做到的事情」寫在紙上"),
            String(localized: "別用「沒做到濾鏡」看事情，而要用「做到了濾鏡」看事情"),
            String(localized: "重點在於，就算沒辦法做到完美，也要把部分做到的事情寫下來"),
            String(localized: "當自我肯定感低落時，有「低估自己理所當然能做到的事情」的傾向"),
            String(localized: "之所以會批判自己，或許是因為拿現狀與理想的完美狀態相比較，這種時候，把可以想像出的最糟狀況與現在相比較，肯定能找到已經做到的部分"),
            String(localized: "不要只用腦袋思考，藉由書寫可以更容易找到「做到了」的事情")
            ]
        ),
        CopingNote(
            method: String(localized: "關注「行動目標」而非「結果目標」，就能脫離惡性循環"),
            situations: [String(localized: "沒辦法順心做出結果來的人"), String(localized: "一下子就想要放棄的人")],
            suggestions: [
            String(localized: "把明天的工作分解成許多小行動"),
            String(localized: "「結果目標」：重視結果的目標，例如：考取證照、營業額"),
            String(localized: "「行動目標」：把焦點擺在為了做出成果所需的具體行動，例如：以業務工作為例，「本月簽成十個案子」為結果目標，「每天打三十通電話」、「一天訪問一間現有客戶」等為行動目標"),
            String(localized: "行動目標與成果、結果無關，只要做好自己決定的事情即可，失敗可能性也大幅降低"),
            String(localized: "當設定好行動目標後仍無法展開行動時，就可以活用「十秒行動」，讓自己能確實逐步加以執行"),
            String(localized: "聚焦在行動目標上，進而開始做出結果後，請再次把焦點放回結果目標")
            ]
        ),
        CopingNote(
            method: String(localized: "具體例子：完成企劃書→把企劃書上能寫的項目填滿、每天更新部落格→先寫出三個部落格文章標題"),
            situations: [],
            suggestions: []
        ),
        CopingNote(
            method: String(localized: "發現下意識脫口說出的「藉口」"),
            situations: [String(localized: "很會找藉口的人"), String(localized: "習慣逃避的人")],
            suggestions: [
            String(localized: "首先從察覺自己的口頭禪開始做起"),
            String(localized: "想要改變自己的行動、思考模式，「發現」自己的口頭禪，是有效方法之一"),
            String(localized: "養成習慣在一天結束時，回顧一整天是否曾脫口說出「沒有錢」、「沒有自信」、「沒有時間」等正當化不行動的藉口"),
            String(localized: "如果不小心說出藉口，不要說出口後就放任不管，每次都要重新換句話說，例如：說出「沒有時間所以辦不到」，可以換成「因為時間不夠，那就試著利用早晨的時間吧」，事前決定好說出藉口時替換的另一句話")
            ]
        ),
        CopingNote(
            method: String(localized: "養成與過去的自己比較的習慣，而非與他人比較"),
            situations: [String(localized: "看社群網站容易沮喪的人"), String(localized: "不小心就會嫉妒他人的人")],
            suggestions: [
            String(localized: "和他人比較前，請先想像自己想成為什麼樣的人"),
            String(localized: "和他人比較後會湧上嫉妒、焦躁、自卑、喪失自信、驕傲自滿、優越感等情緒，結果反而常讓人無法進一步展開行動"),
            String(localized: "問題並不在於「和他人比較」，而是在因此產生負面情緒而「停止行動」這點"),
            String(localized: "不需要和他人比，而是換成和過去的自己比就好"),
            String(localized: "可以拿半年前、一年前、三年前的自己，和現在的自己相比，現在的自己多會了哪些事？"),
            String(localized: "和過去的自己相比後，也有可能出現退步的遺憾狀況，這時候要思考接下來怎麼辦，具體來說就是思考「和現在的自己相比，希望半年後、一年後、三年後的自己是什麼模樣？」"),
            String(localized: "只要和過去的自己比較，就可以掌握自己成長多少，也容易找到「未來成長的空間」")
            ]
        ),
        CopingNote(
            method: String(localized: "十秒提升自我肯定感的行動："),
            situations: [],
            suggestions: [
            String(localized: "不小心批評自己做不好的時候→附和「我懂、我懂」"),
            String(localized: "想要得到他人認同時→一邊拍自己的肩膀一邊說「你很努力呢」"),
            String(localized: "面對冥頑不靈的自己→回想吃美食的瞬間"),
            String(localized: "想忘記討厭的事時→嘴角往上揚一公厘"),
            String(localized: "面對疲憊的自己→抬頭看天空用力伸懶腰")
            ]
        ),
        CopingNote(
            method: String(localized: "掌握自己花最多時間在什麼事情上"),
            situations: [String(localized: "回過神時時間已經過去的人"), String(localized: "光「維持現狀」就費盡心力的人")],
            suggestions: [
            String(localized: "把時間當成「自己生命剩餘的時間」"),
            String(localized: "為了可以展開行動，寫下時間記帳簿讓自己回顧「自己使用時間的方法」"),
            String(localized: "把最近一週使用時間的方法分為「①投資」、「②消費」、「③浪費」 ①投資：想像自己的未來，並將其逐步實現的時間 ②消費：用來維持生活的時間 ③浪費：不能算是投資也不能算消費的時間"),
            String(localized: "重點在於，不需要把「浪費」的時間歸零"),
            String(localized: "如果沒有「投資」時間，最多只能「維持現狀」，想變成「行動派」，但只把時間花在消費與浪費上，這樣永遠只是個「雖然想要立刻行動，但就是做不到的人」"),
            String(localized: "壓縮浪費時間，增加投資時間")
            ]
        ),
        CopingNote(
            method: String(localized: "製作時間表後並遵守原則"),
            situations: [String(localized: "被待辦清單追著跑的人"), String(localized: "忙到毫無從容的人")],
            suggestions: [
            String(localized: "要確保做「想做的事」的時間"),
            String(localized: "將一天分成五大時段①上班前②上午③下午三點前④下班前⑤睡前"),
            String(localized: "時間表的重點並非「決定時段內所有該做之事的細項」，而是「決定最起碼想做什麼」，剩餘的時間就拿來處理待辦清單，或完成預定行程 ①上班前（上課前）：最不容易受外在因素左右的時段，可以盡可能把對自己很重要的事情安排在這個時段 ②上午：相對容易專注的時段，盡可能把需要動腦或創造性的工作安排在這個時段 ③下午三點前：最容易專注力不集中的時段，不要安排獨立作業的工作 ④下班前（下課前）：因為期限效應而讓專注力再度提升，可以安排雖然麻煩卻很必要的工作，另外也可以確認明天行程、想像最棒的成果、以及決定三個關鍵行動 ⑤睡前：確保一段可以放鬆、想瘦、補充心靈營養的時間，也可以回想三件「今天發生的好事」")
            ]
        ),
        CopingNote(
            method: String(localized: "工作中把時間以15分鐘為單位切分"),
            situations: [String(localized: "想要更加專注的人"), String(localized: "想讓工作張弛有度的人")],
            suggestions: [
            String(localized: "準備一個計時器擺在桌上，開始倒數15分鐘"),
            String(localized: "視度設定時間限制，比沒有設定時間限制更能活化大腦"),
            String(localized: "「帕金森定律」：工作會在時限內不停增加到填滿時間為止，例如：有30分鐘可用，即便是15分鐘就能完成的工作，最後都會花上30分鐘才完成"),
            String(localized: "不管怎樣的工作只要設定時限，就能增加專注力，在最短的時間內完成"),
            String(localized: "重點在於決定好「15分鐘內要完成這個部分」之後開始工作，或也可以用「我15分鐘可以做到哪呢？」這種玩遊戲的感覺挑戰看看")
            ]
        ),
        CopingNote(
            method: String(localized: "一天確保兩次「認真的30分鐘」"),
            situations: [String(localized: "遲遲無法著手想做之事的人"), String(localized: "工作一成不變的人")],
            suggestions: [
            String(localized: "只要30分鐘就好，發揮出自己現在所有的能力吧"),
            String(localized: "最好可以用來做平常容易拖延，但對自己來說很重要或真正想要做的事情"),
            String(localized: "「非緊急的要事」，請在一天實踐兩次"),
            String(localized: "創造不同於平常的氛圍，營造特別感")
            ]
        ),
        CopingNote(
            method: String(localized: "依照所需的時間，先決定好轉換心情的方法"),
            situations: [String(localized: "容易沮喪的人"), String(localized: "容易累積壓力的人")],
            suggestions: [
            String(localized: "準備好當身心疲憊時，可以立刻轉換心情的方法"),
            String(localized: "「重設自己」，恢復體力與專注力的放鬆方法，以及調整沮喪情緒的方法，而且能「隨時、隨地、立刻」執行"),
            String(localized: "決定好「幾分鐘就能做到的事」，例如：深呼吸、伸展身體、散步、吃甜食；「30分鐘可以做到的事」，例如：小睡、打掃、慢跑、泡澡；「需要一段時間的事」，例如：旅行、看電影")
            ]
        ),
        CopingNote(
            method: String(localized: "提升時間品質"),
            situations: [],
            suggestions: [
            String(localized: "是否有做出成果？"),
            String(localized: "身心是否處於良好狀態？")
            ]
        ),
        CopingNote(
            method: String(localized: "「處於怎樣的狀態？」比起「做什麼？」會帶給表現更大的影響"),
            situations: [],
            suggestions: []
        ),
        CopingNote(
            method: String(localized: "試著每個月問自己以下四個問題："),
            situations: [],
            suggestions: [
            String(localized: "①本月做出成果的事情 ②本月沒做出成果的事情 ③身心狀態變好的原因 ④身心狀態變差的原因")
            ]
        ),
        CopingNote(
            method: String(localized: "人類的行動可大致分為兩類："),
            situations: [],
            suggestions: [
            String(localized: "將負面狀態回復原點基準的行動（復原行動）"),
            String(localized: "產出附加價值的行動（增值行動）")
            ]
        ),
        CopingNote(
            method: String(localized: "構成人類動力的因素："),
            situations: [],
            suggestions: [
            String(localized: "「保健因素」：與不滿意、不滿足相關的因素"),
            String(localized: "「激勵因素」：與滿足感、成就感和幸福感相關的因素")
            ]
        ),
        CopingNote(
            method: String(localized: "消除不滿意或不滿足等課題的行動是「復原行動」，為了得到滿足感、成就感和幸福感的行動是「增值行動」"),
            situations: [],
            suggestions: []
        ),
        CopingNote(
            method: String(localized: "做到「增值行動」的三個步驟："),
            situations: [],
            suggestions: [
            String(localized: "①訂定目標 ②找出明確目的 ③決定好實際執行的內容")
            ]
        ),
        CopingNote(
            method: String(localized: "想改變人生就需要「異想天開的目標」"),
            situations: [String(localized: "有夢想或目標的人"), String(localized: "光眼前的事情就耗盡力氣無法多思考的人")],
            suggestions: [
            String(localized: "試著徜徉在「夢想未來」的想像中"),
            String(localized: "遲遲無法推進是因為試圖在過去的延長線上，建立「現在的自己能力所及範圍內」的夢想與目標"),
            String(localized: "想改變人生所需的是「異想天開的目標」，「異想天開的目標」是不會被實現可能性及感情煞車器局限的「心中真正想實現的目標」"),
            String(localized: "沒有「異想天開的目標」，就沒有辦法累積好不容易做出的行動、努力與付出的辛勞"),
            String(localized: "面對相同的事，只是有無「異想天開的目標」的差異，就讓看待事物的方法天差地別，而這個差別，也會大幅影響每個思考、選擇、決策與行動")
            ]
        ),
        CopingNote(
            method: String(localized: "【訂定目標１】 聚焦「慾望」後，就能找到真正想做的事"),
            situations: [String(localized: "面對自己慾望的人"), String(localized: "壓抑自己慾望的人")],
            suggestions: [
            String(localized: "請理解慾望不是壞東西"),
            String(localized: "沒有慾望的目標，不能說是真正的目標"),
            String(localized: "夢想與目標，多半深藏在心中，很少會外顯出來，所以為了找出「異想天開的目標」，第一個步驟就是「理解自己的慾望」"),
            String(localized: "舊大腦為了維持生命而工作，掌管情緒與行動；新大腦為了可以因應狀況做出適當的行動，擁有高度的學習能力，掌管語言"),
            String(localized: "不管擬訂出多明確的目標，只要目標還停留在語言階段，就沒辦法進一步展開行動，形成「明明理智知道該行動比較好卻無法行動」的狀態"),
            String(localized: "人類是靠感情而非理智行動，如果想展開行動，就必須從掌管感情與行動的舊大腦下手才行"),
            String(localized: "意識到「用大腦思考的事情」，與「用心感受的事情」之間的不同")
            ]
        ),
        CopingNote(
            method: String(localized: "【訂定目標２】 分別傾聽「大腦的聲音」、「身體的聲音」、「心裡的聲音」"),
            situations: [String(localized: "重視「自己心情」的人"), String(localized: "重視「常識及社會觀感」更甚「自己心情」的人")],
            suggestions: [
            String(localized: "不停反覆確認，現在心中所想的事情是「真心話」嗎？"),
            String(localized: "「大腦的聲音」：平常思考的事情。「非做不可」、「得這樣做」等義務感"),
            String(localized: "「身體的聲音」：身體的狀態。「肩膀僵硬」、「喉嚨很痛」等感覺"),
            String(localized: "「心裡的聲音」：感受、心情。「想這樣做」、「想要」等欲求"),
            String(localized: "建立「異想天開的目標」最大的訣竅就是，應該要重視「想不想實現？」而非「能不能實現？」"),
            String(localized: "為了讓「心裡的聲音」外顯出來，就需要與自己對話，具體來說，就是問自己「其實想要怎麼做？」")
            ]
        ),
        CopingNote(
            method: String(localized: "明確訂出「目的」與「實際執行的內容」"),
            situations: [String(localized: "明確知道自己的目的與步驟"), String(localized: "只有一個模糊不清的目的")],
            suggestions: [
            String(localized: "意識到目標不是「設定好就結束」，而是「需要培養的東西」"),
            String(localized: "「實際執行內容」就是決定「何時、在哪、做些什麼」")
            ]
        ),
        CopingNote(
            method: String(localized: "【設定目的】 理解自己的價值觀後就能看見真正的目的"),
            situations: [String(localized: "知道自己最重視的價值觀"), String(localized: "沒有思考目的的習慣")],
            suggestions: [
            String(localized: "試著探索自己「對什麼事情感到喜悅」吧"),
            String(localized: "價值觀可大致分為三類「①與他人的連結」、「②成就」、「③追求技術」 ①與他人的連結：珍惜得到感謝、加深彼此關係、重視充實人際關係的價值觀 ②成就：重視達成目標、完成困難課題的價值觀 ③追求技術：重視加深專業程度，希望自我意識與個性受到尊重的價值觀")
            ]
        ),
        CopingNote(
            method: String(localized: "【明確訂出實際執行的內容１】 設置三個里程碑"),
            situations: [String(localized: "規劃路線朝目標前進的人"), String(localized: "對該做哪些事只有模糊想法的人")],
            suggestions: [
            String(localized: "要明確找出「終點想像」與「過程想像」"),
            String(localized: "①在現狀與目標之間擺三個「里程碑」②把里程碑「細分」"),
            String(localized: "里程碑就是個「路標」，也就是在朝實現目標前進時，路途中掌握大致進度的小目標"),
            String(localized: "這些里程碑只是初步暫定，當實際行動後，如果感到不適合自己，隨時都可以變更")
            ]
        ),
        CopingNote(
            method: String(localized: "【明確訂出實際執行的內容２】 細分里程碑"),
            situations: [String(localized: "將行動「分解」思考"), String(localized: "將行動「大範圍」思考")],
            suggestions: [
            String(localized: "除了「結果目標」之外，也訂出「行動目標」吧"),
            String(localized: "當實際執行的內容範圍太大時，會讓人難以行動，所以分割成小塊比較容易處理"),
            String(localized: "為了可以確實展開行動，請具體決定好「何時、在哪裡、做什麼」")
            ]
        ),
        CopingNote(
            method: String(localized: "在達成目標之前，設定另一個更高的目標"),
            situations: [String(localized: "隨時都會考慮未來"), String(localized: "只思考眼前的事情")],
            suggestions: [
            String(localized: "請擁有「人生就是一連串的目標設定」的想法"),
            String(localized: "養成當達到目標八成時，就訂定下一個目標的習慣"),
            String(localized: "更新目標後，現在的目標就會成為成長過程的一個階段")
            ]
        ),
        CopingNote(
            method: String(localized: "提升自我認知的方法："),
            situations: [],
            suggestions: [
            String(localized: "①理解現在的自我認知：試著把「現在的自我認知」寫下來 ②寫出理想中的未來自我認知：寫下半年後、一年後、三年後的自我認知 ③從未來的自我認知中選擇覺得最適合自己的一個：從半年後、一年後、三年後中選一個最適合自己的自我認知，並從現在此刻開始，用這個自我認知生活")
            ]
        ),
        CopingNote(
            method: String(localized: "回顧筆記："),
            situations: [],
            suggestions: [
            String(localized: "①回顧的頻率：以「一週」為單位回顧，並試著訂定固定的回顧時間 ②回顧的順序、做法：絕對要依「順利的事情（做到的事）→不順利的事情（沒做到的事）」的順序，接著把結果寫入行動計劃中，並反映在之後的預定行程上 ③活用回顧的方法：問自己以下三個問題，慢慢地讓自己能加以活用吧"),
            String(localized: "該怎麼做才能更加接近自己的夢想與目標？"),
            String(localized: "如果還能再加以改善，是哪一點可以改善？"),
            String(localized: "如果想把這個經驗活用在下次行動，該怎麼做才好？")
            ]
        ),
        CopingNote(
            method: String(localized: "在回顧筆記畫出四大方格，左上為「實際執行內容」、右上「辦到的事情、沒辦到的事情」、左下為「煩惱、課題」、右下為「修正路線的行動計劃」"),
            situations: [],
            suggestions: [
            String(localized: "①寫下為了實現目標的「實際執行內容」 ②寫下「辦到的事情」、「沒辦到的事情」，並從「辦到的事情」開始回顧 ③寫下「煩惱、課題」，用「該怎麼做才能執行呢？」的角度來思考剛剛寫下的「沒辦到的事情」，把從中找到的「課題」寫下來，以及與目標沒有直接相關連的「煩惱」、「在意的事情」 ④寫下修正路線後的行動計劃，首先分析步驟二中「辦到的事情」的原因，把順利的事情反映在行動計劃上，接著以步驟三的「課題與煩惱」為基礎，修正行動計劃的路線")
            ]
        ),
    ]
    }
}