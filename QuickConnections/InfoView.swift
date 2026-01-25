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
                Image(systemName:"sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("QuickConnections")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("QuickConnections uses the Foundation Models framework to generate related words to a given word. Find synonyms, related concepts, and get a feel of how the on-device LLM makes connctions between concepts!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    InfoView()
}
