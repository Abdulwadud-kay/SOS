//
//  VisionBackend.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/27/25.
//

import Foundation
import UIKit

class VisionBackend {
    private let openAIService = OpenAIService.shared
    
    func processImage(_ imageData: Data, pastContext: String? = nil, language: String = "en") async throws -> String {
        return try await openAIService.describeImage(imageData, pastContext: pastContext, language: language)
    }
}
