//
//  FeedbackView.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/10/25.
//

import SwiftUI
import FoundationModels
import UniformTypeIdentifiers

struct FeedbackView: View {
    @ObservedObject var viewModel: GenerationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var sentiment: LanguageModelFeedbackAttachment.Sentiment?
    @State private var selectedIssues: Set<FeedbackIssueType> = []
    @State private var desiredOutput: String = ""
    @State private var showingShareSheet = false
    @State private var feedbackData: Data?
    
    enum FeedbackIssueType: String, CaseIterable {
        case factuallyIncorrect = "Factually Incorrect"
        case offensive = "Offensive Content"
        case unhelpful = "Unhelpful Response"
        // Claude may just be making these up.
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("How was your experience?") {
                    HStack(spacing: 40) {
                        Button(action: {
                            sentiment = .positive
                        }) {
                            VStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(sentiment == .positive ? .green : .secondary)
                                Text("Good")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            sentiment = .negative
                        }) {
                            VStack {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(sentiment == .negative ? .red : .secondary)
                                Text("Bad")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                if sentiment == .negative {
                    Section("Additional Comments") {
                        TextEditor(text: $desiredOutput)
                            .frame(minHeight: 100)
                    }
                }
                
                Section {
                    Button(action: prepareFeedback) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Prepare Feedback for Feedback Assistant")
                        }
                    }
                    .disabled(sentiment == nil)
                }
            }
            .navigationTitle("Provide Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let feedbackData = feedbackData {
                ShareSheet(data: feedbackData, onDismiss: {
                    dismiss()
                })
            }
        }
    }
    
    private func prepareFeedback() {
        guard let session = viewModel.getSession(),
              let sentiment = sentiment else { return }
        
        let transcript = session.transcript
        let entries = transcript.entries
        
        // Get the last user input and model output
        guard entries.count >= 2 else { return }
        
        let inputEntries = Array(entries.dropLast())
        let outputEntry = entries.last!
        
        // Create feedback attachment without issues for now
        // Since we don't know the exact Issue.Category enum cases
        let feedback = LanguageModelFeedbackAttachment(
            input: inputEntries,
            output: [outputEntry],
            sentiment: sentiment,
            issues: [],  // Empty for now
            desiredOutputExamples: []
        )
        
        // Encode to JSON
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            feedbackData = try encoder.encode(feedback)
            showingShareSheet = true
        } catch {
            print("Failed to encode feedback: \(error)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("language_model_feedback.json")
        try? data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        activityVC.completionWithItemsHandler = { activityType, completed, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
            
            // Dismiss the feedback view after sharing
            if completed {
                DispatchQueue.main.async {
                    onDismiss()
                }
            }
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
