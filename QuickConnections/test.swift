//
//  test.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/10/25.
//

import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: "How many letter r's are in the word strawberry?"
    )
}
