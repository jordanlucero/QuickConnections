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
    private var currentInput: String = ""
    private var generationCount = 0
    
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
            Return only the words, separated by commas with no spaces after commas. Do not include explanations or additional text.
            Important: Each word should be a single word without spaces (compound words with hyphens are acceptable).
            """
        
        session = LanguageModelSession(instructions: instructions)
    }
    
    func generateRelatedWords(for input: String) async {
        guard !input.isEmpty else { return }
        
        // Reset if it's a new input
        if input != currentInput {
            currentInput = input
            generationCount = 0
            generatedWords = []
            setupSession() // Reset session for new input
        }
        
        isGenerating = true
        
        await performGeneration(isFirstGeneration: true)
        
        // Automatically generate more words up to 9 additional times (10 total)
        for i in 1...9 {
            // Check if the user has changed the input
            if currentInput != input {
                break
            }
            
            // Small delay between generations
            try? await Task.sleep(nanoseconds: UInt64(500_000_000)) // 500ms
            
            await performGeneration(isFirstGeneration: false)
            generationCount = i
        }
        
        isGenerating = false
    }
    
    private func performGeneration(isFirstGeneration: Bool) async {
        guard let session = session else { return }
        
        do {
            let prompt: String
            if isFirstGeneration {
                prompt = "Generate related words for: \(currentInput)"
            } else {
                prompt = "Generate more related words for: \(currentInput)"
            }
            
            // Debug logging - Input
            print("\n=== Generation \(generationCount + 1) ===")
            print("Input prompt: \(prompt)")
            
            // Create generation options with higher temperature for more creative responses
            let options = GenerationOptions(
                sampling: nil,
                temperature: 1.5
            )
            
            let response = try await session.respond(to: prompt, options: options)
            
            // Parse the response - extract content from the response description
            let responseText = String(describing: response)
            
            // Debug logging - Raw output
            print("Raw response: \(responseText)")
            
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
            
            // Debug logging - Extracted content
            print("Extracted content: \(extractedContent)")
            print("=== End Generation \(generationCount + 1) ===")
            
            // Parse the extracted content into individual words
            // Handle both comma-separated and space-separated formats
            let separatedWords: [String]
            if extractedContent.contains(",") {
                // If commas are present, split by comma
                separatedWords = extractedContent.split(separator: ",")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            } else {
                // Otherwise, split by spaces
                separatedWords = extractedContent.split(separator: " ")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            
            let words = separatedWords
                .filter { word in
                    // Check: not empty, max 100 chars, not duplicate (case-insensitive)
                    !word.isEmpty 
                    && word.count <= 100
                    && !generatedWords.contains { 
                        $0.lowercased() == word.lowercased() 
                    }
                }
            
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
    }
    
    func clearWords() {
        withAnimation {
            generatedWords = []
        }
    }
}
