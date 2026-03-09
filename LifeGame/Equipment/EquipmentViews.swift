// File: Equipment/EquipmentViews.swift
import SwiftUI

struct EquipPanel: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var store: EquipmentStore
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("裝備（每天每類只能帶一個）")
                .font(.headline)
            
            Text("重量：\(game.totalEquipWeight) / \(game.maxEquipWeight)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            ForEach(EquipSlot.allCases) { slot in
                NavigationLink {
                    EquipmentPickerView(game: game, store: store, slot: slot)
                } label: {
                    HStack {
                        Text(slot.rawValue).frame(width: 80, alignment: .leading)
                        Spacer()
                        Text(game.equipped[slot]?.name ?? "未裝備")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EquipmentPickerView: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var store: EquipmentStore
    let slot: EquipSlot
    
    var body: some View {
        List {
            Section {
                Button {
                    game.equipped[slot] = nil
                    game.resetForNewDay()
                } label: {
                    HStack {
                        Text("不裝備")
                        Spacer()
                        if game.equipped[slot] == nil {
                            Image(systemName: "checkmark").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section(slot.rawValue) {
                ForEach(allItemsForThisSlot) { item in
                    let allowed = game.canEquip(item, to: slot)
                    
                    Button {
                        guard allowed else { return }
                        game.equipped[slot] = item
                        game.resetForNewDay()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.name).font(.headline)
                                Spacer()
                                if game.equipped[slot]?.id == item.id {
                                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                                }
                            }
                            
                            if !item.note.isEmpty {
                                Text(item.note).font(.footnote).foregroundStyle(.secondary)
                            }
                            
                            Text("重量 \(game.weight(of: item)) 點")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            if !allowed {
                                Text("超過重量上限（\(game.maxEquipWeight)）")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            
                            ForEach(item.effects, id: \.self) { e in
                                if case .weight = e { } else {
                                    Text(e.displayText).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!allowed)
                }
            }
        }
        .navigationTitle(slot.rawValue)
    }
    
    private var allItemsForThisSlot: [EquipItem] {
        (store.items + sampleItems).filter { $0.slot == slot }
    }
}
