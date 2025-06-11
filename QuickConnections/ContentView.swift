import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var textInput: String = ""
    @State private var showingAlert = false
    @StateObject private var viewModel = GenerationViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Section
            VStack(spacing: 16) {
                Text("QuickConnections")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                // Text Field with Two-Word Limit
                HStack(spacing: 12) {
                    TextField("Enter a word or phrase", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: textInput) { oldValue, newValue in
                            // Check if more than two words
                            let words = newValue.split(separator: " ").filter { !$0.isEmpty }
                            if words.count > 2 {
                                // Revert to the old value
                                textInput = oldValue
                                showingAlert = true
                            }
                        }
                        .onSubmit {
                            generateWords()
                        }
                        .disabled(viewModel.isGenerating)
                    
                    Button(action: generateWords) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "sparkles")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(textInput.isEmpty || viewModel.isGenerating || !viewModel.modelAvailable)
                }
                .frame(maxWidth: 400)
                
                if !viewModel.modelAvailable {
                    Text("The Foundation Model isn't available. Make sure your device suports Apple Intelligence and that it is enabled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Generated Words Section
            if !viewModel.generatedWords.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.generatedWords.enumerated()), id: \.offset) { index, word in
                            WordBubble(word: word)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal)
                }
            } else if viewModel.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating related words...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Enter a word to generate connections")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
            
            Spacer(minLength: 0)
        }
        .alert("Word Limit Exceeded", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only enter up to two words.")
        }
    }
    
    private func generateWords() {
        guard !textInput.isEmpty && viewModel.modelAvailable else { return }
        
        Task {
            await viewModel.generateRelatedWords(for: textInput)
            // Store the query in SwiftData
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }
}

struct WordBubble: View {
    let word: String
    @State private var isPressed = false
    
    var body: some View {
        Text(word)
            .font(.callout)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
