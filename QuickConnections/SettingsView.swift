//
//  SettingsView.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("generationCount") private var generationCount = 5
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Number of Generations")
                            .font(.headline)
                        
                        Text("\(generationCount) generation\(generationCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Slider with tick marks
                        Slider(value: Binding(
                            get: { Double(generationCount) },
                            set: { generationCount = Int($0) }
                        ), in: 3...10, step: 1) {
                            EmptyView()
                        } minimumValueLabel: {
                            Text("3").font(.caption)
                        } maximumValueLabel: {
                            Text("10").font(.caption)
                        }
                        .tint(.blue)
                        
                        Text("Controls how many rounds of word generation occur for each input. The Foundation Model may begin to behave erratically with more generation turns as of Beta 1.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}
