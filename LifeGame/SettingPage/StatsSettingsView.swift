import SwiftUI

struct StatsSettingsView: View {
    @ObservedObject var game: LifeGame
    
    var body: some View {
        Form {
            Section("能力值上限") {
                Stepper("HP 上限：\(game.hp.max)", value: Binding(
                    get: { game.hp.max },
                    set: { game.hp.max = $0; clampCurrent() }
                ), in: 0...999, step: 10)
                
                Stepper("FP 上限：\(game.fp.max)", value: Binding(
                    get: { game.fp.max },
                    set: { game.fp.max = $0; clampCurrent() }
                ), in: 0...999, step: 10)
                
                Stepper("MP 上限：\(game.mp.max)", value: Binding(
                    get: { game.mp.max },
                    set: { game.mp.max = $0; clampCurrent() }
                ), in: 0...999, step: 10)
            }
            
            Section("每日起始 MP") {
                Stepper("起始 MP：\(game.startMP)", value: Binding(
                    get: { game.startMP },
                    set: { game.startMP = $0; clampStartMP() }
                ), in: 0...999, step: 5)
                
                Text("「新的一天」會把 MP 設為起始 MP，但不會超過 MP 上限。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Button("套用到現在的 MP") {
                    game.mp.current = min(game.startMP, game.mp.max)
                }
            }
        }
        .navigationTitle("能力值設定")
    }
    
    private func clampCurrent() {
        game.hp.current = min(game.hp.current, game.hp.max)
        game.fp.current = min(game.fp.current, game.fp.max)
        game.mp.current = min(game.mp.current, game.mp.max)
        clampStartMP()
    }
    
    private func clampStartMP() {
        game.startMP = min(game.startMP, game.mp.max)
    }
}
