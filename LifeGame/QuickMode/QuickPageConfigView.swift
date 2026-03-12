import SwiftUI

/// 設定子頁面：編輯簡略模式的頁面（選擇 + 排序）
struct QuickPageConfigView: View {
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        List {
            // 已選用的頁面（可拖曳排序）
            Section {
                ForEach(phoneModeStore.quickPages) { page in
                    HStack(spacing: 12) {
                        Image(systemName: page.featureType.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(theme.accentColor)
                            .frame(width: 32, height: 32)
                            .background(theme.accentColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text(page.featureType.title)
                            .font(.body)

                        Spacer()
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        phoneModeStore.removePage(id: phoneModeStore.quickPages[index].id)
                    }
                }
                .onMove { source, destination in
                    phoneModeStore.movePage(from: source, to: destination)
                }
            } header: {
                Text("已選用（拖曳排序）")
            } footer: {
                if phoneModeStore.quickPages.isEmpty {
                    Text("請至少選擇一個功能頁面")
                }
            }

            // 可新增的功能
            let unused = QuickFeatureType.allCases.filter { type in
                !phoneModeStore.contains(type)
            }

            if !unused.isEmpty {
                Section("可新增") {
                    ForEach(unused) { type in
                        Button {
                            withAnimation {
                                phoneModeStore.addPage(type)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(type.title)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.green)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("編輯快速頁面")
        .environment(\.editMode, .constant(.active))
    }
}
