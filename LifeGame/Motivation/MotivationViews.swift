// File: Motivation/MotivationViews.swift
import SwiftUI

struct MotivationHelpView: View {
    var body: some View {
        NavigationStack {
            List(MotivationScenario.allCases) { scenario in
                NavigationLink(value: scenario) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scenario.title)
                        Text(scenario.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("動力支援")
            .navigationDestination(for: MotivationScenario.self) { scenario in
                MotivationDetailView(scenario: scenario)
            }
        }
    }
}

struct MotivationDetailView: View {
    let scenario: MotivationScenario
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(scenario.title)
                    .font(.title2).bold()
                
                Text(scenario.subtitle)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("可以試試看這些方法：")
                        .font(.headline)
                    
                    ForEach(scenario.suggestions, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(item)
                        }
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding()
        }
    }
}
