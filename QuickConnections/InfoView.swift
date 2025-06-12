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
            VStack(alignment: .leading, spacing: 20) {
                
                Text("QuickConnections")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("QuickConnections uses the Foundation Models framework to generate related words to a given word. Find synonyms, related concepts, and get a feel of how the LLM living on your device makes connctions between concepts!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text("Please keep in mind that this is a sample app. It lacks the necessary safeguards that you would expect from other AI products. As this framework evolves, you may encounter some growing pains. If you come across harmful content, you can report it to Apple by exporting a file that you can take to Feedback Assistant using the context menu while the content is still visible.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("About")
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

#Preview {
    InfoView()
}
