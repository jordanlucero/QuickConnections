import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var textInput: String = ""
    @State private var showingAlert = false
    @State private var showingFeedbackSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingInfoSheet = false
    @State private var hasStartedPrewarm = false
    @StateObject private var viewModel = GenerationViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            // Main content area
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
                    .padding(.horizontal, 12)
                    .padding(.top, 130) // Space for header
                    .padding(.bottom, 100) // Space for floating input
                }
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            } else if viewModel.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating related words...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
                .onTapGesture {
                    hideKeyboard()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Enter a word to generate connections!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
                .onTapGesture {
                    hideKeyboard()
                }
            }
            
            // Header with menu button
            VStack {
                // Status bar blur area
                Color.clear
                    .frame(height: 0)
                    .background(.regularMaterial)
                    .ignoresSafeArea()
                
                HStack {
                    Spacer()
                    
                    // Menu Button
                    Menu {
                        Button(action: {
                            showingSettingsSheet = true
                        }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        
                        Button(action: {
                            showingInfoSheet = true
                        }) {
                            Label("About", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Floating Text Field
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Floating glass text field with embedded button
                        HStack(spacing: 8) {
                            TextField("Enter a word", text: $textInput)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .onChange(of: textInput) { oldValue, newValue in
                                    // Prewarm on first character typed (Not functional)
                                    if oldValue.isEmpty && !newValue.isEmpty && !hasStartedPrewarm {
                                        print("User started typing - triggering prewarm")
                                        hasStartedPrewarm = true
                                        Task {
                                            await viewModel.prewarmModel()
                                        }
                                    }
                                    
                                    // Reset prewarm flag when text is cleared
                                    if newValue.isEmpty {
                                        hasStartedPrewarm = false
                                    }
                                    
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
                                        .scaleEffect(0.7)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .disabled(textInput.isEmpty || viewModel.isGenerating || !viewModel.modelAvailable)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        //.background(.regularMaterial)
                        .clipShape(Capsule())
                        .glassEffect()
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.modelAvailable {
                        Text("The Foundation Model isn't available. Make sure your device and language is supported by Apple Intelligence and it's enabled.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .alert("Word Limit Exceeded", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only enter up to two words.")
        }
        .alert("Generation Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "This usually happens due to something trigerring the safety guardrails. Check the console for any erratic behavior, or try again with less generation turns.")
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
        }
        .sheet(isPresented: $showingInfoSheet) {
            InfoView()
        }
    }
    
    private func generateWords() {
        guard !textInput.isEmpty && viewModel.modelAvailable else { return }

        Task {
            await viewModel.generateRelatedWords(for: textInput)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
}
