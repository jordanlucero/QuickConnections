//
//  GenerationViewModel.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/10/25.
//

import SwiftUI
import Combine
import Foundation
import FoundationModels

@MainActor
class GenerationViewModel: ObservableObject {
    @Published var generatedWords: [String] = []
    @Published var isGenerating = false
    @Published var modelAvailable = false
    
    private var model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    
    init() {
        checkModelAvailability()
    }
    
    func checkModelAvailability() {
        switch model.availability {
        case .available:
            modelAvailable = true
            setupSession()
        default:
            modelAvailable = false
        }
    }
    
    private func setupSession() {
        let instructions = """
            You are a helpful assistant that generates related words to a word or phrase provided to you.
            When given a word, generate as many related synonyms or associated words as you can. Aim to generate at least 25 related words. It's ok if you can't think of many words, but please try your best.
            Return only the words, separated by commas. Do not include explanations or additional text.
            """
        
        session = LanguageModelSession(instructions: instructions)
    }
    
    func generateRelatedWords(for input: String) async {
        guard let session = session, !input.isEmpty else { return }
        
        isGenerating = true
        generatedWords = []
        
        do {
            let prompt = "Generate related words for: \(input)"
            
            // Create generation options with higher temperature for more creative responses
            let options = GenerationOptions(
                sampling: nil,
                temperature: 1.5,
            )
            
            let response = try await session.respond(to: prompt, options: options)
            
            // Parse the response - extract content from the response description
            let responseText = String(describing: response)
            
            // Extract the quoted content from the response
            var extractedContent = ""
            if let contentRange = responseText.range(of: "content: \"") {
                let startIndex = contentRange.upperBound
                if let endRange = responseText[startIndex...].range(of: "\"") {
                    extractedContent = String(responseText[startIndex..<endRange.lowerBound])
                }
            } else {
                // Fallback to using the whole response if parsing fails
                extractedContent = responseText
            }
            
            // Parse the extracted content into individual words
            let words = extractedContent.split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            // Animate the appearance of words
            for (index, word) in words.enumerated() {
                try await Task.sleep(nanoseconds: UInt64(50_000_000)) // 50ms delay
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.generatedWords.append(word)
                    }
                }
            }
        } catch {
            print("Error generating words: \(error)")
        }
        
        isGenerating = false
    }
    
    func clearWords() {
        withAnimation {
            generatedWords = []
        }
    }
}
