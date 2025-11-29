//
//  FeedbackView.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/10/25.
//

// The original purpose of this module was to interact with APIs that Apple has since removed from all OS SDKs.

import SwiftUI
import FoundationModels
import UniformTypeIdentifiers

struct FeedbackView: View {
    @ObservedObject var viewModel: GenerationViewModel
    @Environment(\.dismiss) private var dismiss

    // Custom sentiment enum to replace removed LanguageModelFeedbackAttachment.Sentiment
    enum FeedbackSentiment: String, Codable {
        case positive
        case negative
    }

    @State private var sentiment: FeedbackSentiment?
    @State private var selectedIssues: Set<FeedbackIssueType> = []
    @State private var desiredOutput: String = ""
    @State private var showingShareSheet = false
    @State private var feedbackData: Data?

    enum FeedbackIssueType: String, CaseIterable {
        case factuallyIncorrect = "Factually Incorrect"
        case offensive = "Offensive Content"
        case unhelpful = "Unhelpful Response"

        var displayName: String {
            return self.rawValue
        }
    }

    // Custom feedback structure to replace removed LanguageModelFeedbackAttachment
    struct FeedbackData: Codable {
        let sentiment: FeedbackSentiment
        let issues: [String]
        let desiredOutput: String
        let timestamp: Date
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
        guard let sentiment = sentiment else { return }

        // Create custom feedback data since LanguageModelFeedbackAttachment was removed from public API
        let feedback = FeedbackData(
            sentiment: sentiment,
            issues: selectedIssues.map { $0.rawValue },
            desiredOutput: desiredOutput,
            timestamp: Date()
        )

        // Encode to JSON
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
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
