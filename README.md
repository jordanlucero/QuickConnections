QuickConnections is a sample app that utilizes the Foundation Models framework in iOS 26 aligned releases. Give the model a word and it will spit a handful of synonyms, related concepts, and anything else it sees fit.  
  
  
  
## **Compile in Xcode 26**  
QuickConnections is an Xcode 26 project that targets iOS and iPadOS, with “Designed for iPad” support for macOS Tahoe and visionOS 26. Keep in mind that compiling the app and running it in a simulator will likely require macOS Tahoe.  
  
## **Claude Code usage**  
The majority of the code in the project has been generated with Claude Code, using Claude 4 Sonnet and Claude 4 Opus. The app does not have network access.  
  
## **Troubleshooting**  
* QuickConnections does not use delta responses due to the relative simplicity of the prompt that is passed to the Foundation Model. Instead, a transcript runs the prompt from 3-10 times (default of 5) and includes any words that haven’t been seen yet.  
* QuickConnections does not follow best practices for error-handling, as it’s just a sample app. Requests may fail due to device rate limits, unavailability of Apple Intelligence, or device pressure. If requests are taking too long, I’ve found that it’s beneficial to quit and reopen the app.  
* Pre-warming is not yet functional.  
* Output quality is highly inconsistent as of the first developer betas. Generations you make in one app session may be focused and on-topic, while generations in another may be erratic and formatted incorrectly. Apple has noted that this is a known issue for (at least for longer transcripts) in the release notes for all developer betas that include the Foundation Models framework.  
