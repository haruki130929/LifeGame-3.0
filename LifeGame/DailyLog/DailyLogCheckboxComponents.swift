import SwiftUI

// MARK: - 單一勾選列（像 ⬜︎ / ✅）
// ✅ 目標：checkbox + 文字永遠在同一行組合裡；文字太長就「文字自己換行」，但 icon 不會跟文字分家
struct CheckboxRow: View {
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .frame(width: 24, height: 24, alignment: .topLeading)
                
                Text(title)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true) // ✅ 允許文字換行，但不把 icon 和文字拆成兩列
                    .foregroundStyle(.primary)
                
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 多選清單（Set）
struct CheckboxMultiSelectList<Option: Identifiable & Hashable & RawRepresentable>: View where Option.RawValue == String {
    let title: String
    let options: [Option]
    @Binding var selected: Set<Option>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            ForEach(options) { opt in
                CheckboxRow(
                    title: opt.rawValue,
                    isChecked: Binding(
                        get: { selected.contains(opt) },
                        set: { isOn in
                            if isOn { selected.insert(opt) } else { selected.remove(opt) }
                        }
                    )
                )
            }
        }
    }
}

// MARK: - 單選清單（一次只能選一個）
struct CheckboxSingleSelectList<Option: Identifiable & Hashable & RawRepresentable>: View where Option.RawValue == String {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            ForEach(options) { opt in
                CheckboxRow(
                    title: opt.rawValue,
                    isChecked: Binding(
                        get: { selection == opt },
                        set: { isOn in if isOn { selection = opt } }
                    )
                )
            }
        }
    }
}
