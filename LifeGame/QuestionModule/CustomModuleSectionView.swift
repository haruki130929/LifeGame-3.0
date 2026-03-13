import SwiftUI

/// 渲染使用者自訂模組的 Section
struct CustomModuleSectionView: View {
    let module: DailyLogModule
    @Binding var answers: [CustomAnswer]
    var header: String? = nil

    var body: some View {
        Section(header ?? module.displayTitle) {
            if let questions = module.questions, !questions.isEmpty {
                ForEach(questions) { question in
                    if shouldShow(question) {
                        QuestionFieldView(question: question, answers: $answers)
                    }
                }
            } else {
                Text("尚未設定問題")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// 檢查條件觸發：若有 conditionalTrigger，需父問題的答案符合才顯示
    private func shouldShow(_ question: QuestionDefinition) -> Bool {
        guard let trigger = question.conditionalTrigger else { return true }

        guard let parentAnswer = answers.first(where: { $0.questionId == trigger.parentQuestionId }) else {
            return false
        }

        // 檢查 stringValue（單選）
        if let sv = parentAnswer.stringValue, trigger.triggerValues.contains(sv) {
            return true
        }

        // 檢查 stringArrayValue（多選）
        if let arr = parentAnswer.stringArrayValue {
            let intersection = Set(arr).intersection(Set(trigger.triggerValues))
            if !intersection.isEmpty { return true }
        }

        return false
    }
}
