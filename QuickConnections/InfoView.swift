//
//  InfoView.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/11/25.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "brain.filled.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                Text("QuickConnections")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Generate related words from any input")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Placeholder content
                Text("More information coming soon...")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}