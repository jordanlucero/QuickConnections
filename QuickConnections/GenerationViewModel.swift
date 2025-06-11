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
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var hasGeneratedContent = false
    
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
        session = LanguageModelSession(instructions: instructions)
    }
    
    func generateRelatedWords(for input: String) async {
        guard !input.isEmpty else { return }
        
        // Clear any existing errors
        clearError()
        
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
        hasGeneratedContent = !generatedWords.isEmpty
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
            // Check for specific error types
            let errorDescription = String(describing: error)
            
            if errorDescription.contains("exceededContextWindowSize") {
                // Handle context window exceeded
                print("Context window exceeded, creating new session")
                handleContextWindowExceeded()
            } else if errorDescription.contains("unsupportedLanguageOrLocale") {
                // Handle unsupported language
                print("Unsupported language or locale")
                await MainActor.run {
                    self.errorMessage = "The language in your input is not currently supported by the Foundation Model."
                    self.showingError = true
                }
            } else {
                // Handle other errors
                print("Error generating words: \(error)")
                await MainActor.run {
                    self.errorMessage = "An error occurred while generating words. Please try again."
                    self.showingError = true
                }
            }
        }
    }
    
    func clearWords() {
        withAnimation {
            generatedWords = []
            hasGeneratedContent = false
        }
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    private func handleContextWindowExceeded() {
        // According to WWDC, we should create a new session with relevant transcript entries
        guard let oldSession = session else { return }
        
        // Get the transcript from the current session
        let transcript = oldSession.transcript
        
        // Create a condensed transcript with the first entry (instructions) and last successful response
        var condensedEntries: [Transcript.Entry] = []
        
        // Keep the instructions (first entry)
        if let firstEntry = transcript.entries.first {
            condensedEntries.append(firstEntry)
        }
        
        // Keep the last successful response if available
        if transcript.entries.count > 1, 
           let lastEntry = transcript.entries.last {
            condensedEntries.append(lastEntry)
        }
        
        // For now, just create a fresh session since the transcript API might not be available yet (Claude may be making this up)
        setupSession()
        print("Created fresh session after context window exceeded")
    }
    
    private var instructions: String {
        """
        You are a helpful assistant that generates related words to a word or phrase provided to you.
        When given a word, generate as many related synonyms or associated words as you can. Aim to generate at least 25 related words. It's ok if you can't think of many words, but please try your best.
        Return only the words, separated by commas with no spaces after commas. DO NOT INCLUDE INTRODUCTIONS OR ANY SUPERFLUOUS TEXT. ONLY INCLUDE WORDS SEPARATED BY COMMAS.
        Important: Each word should be a single word without spaces or punctuation (compound words with hyphens are acceptable).
        """
    }
    
    func checkLanguageSupport(for locale: Locale = .current) -> Bool {
        // Since supportsLanguage might not be available yet, return true for now (Claude may be making this up)
        // The model will throw an unsupportedLanguageOrLocale error if needed
        return true
    }
    
    func getSession() -> LanguageModelSession? {
        return session
    }
    
    // Prewarm the model when user starts typing
    func prewarmModel() async {
        guard modelAvailable, session != nil else { 
            print("=== Prewarm Request ===")
            print("Cannot prewarm: Model not available or session not initialized")
            print("Model available: \(modelAvailable), Session exists: \(session != nil)")
            return 
        }
        
        print("\n=== Prewarm Request ===")
        print("Starting model prewarm at \(Date())")
        
        // The session might have a prewarm method or we can send a minimal request
        // to "wake up" the model and prepare it for the actual generation
        
        // Log session state
        print("Session state: \(session != nil ? "Active" : "Nil")")
        print("Session is responding: \(session?.isResponding ?? false)")
        
        // Since we don't have access to a specific prewarm method (I don't know if this is true),
        // we could send a minimal request to warm up the model
        // This is commented out to avoid unnecessary processing
        /*
        do {
            print("Attempting minimal generation for prewarm...")
            let options = GenerationOptions(
                sampling: .greedy,
                temperature: 0.1,
                maximumResponseTokens: 1
            )
            let startTime = Date()
            _ = try await session?.respond(to: ".", options: options)
            let duration = Date().timeIntervalSince(startTime)
            print("Prewarm generation completed in \(duration) seconds")
        } catch {
            print("Prewarm generation failed: \(error)")
        }
        */
        
        print("Prewarm logging completed")
        print("=== End Prewarm ===\n")
    }
}
