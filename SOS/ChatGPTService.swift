//
//  ChatGPTService.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/25/25.
//

import Foundation
import UIKit



struct ChatGPTMessage {
    let role: String
    let content: String
}

class ChatGPTService: ObservableObject {
    private let openAIApiKey = "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"
    
    func analyzeImageWithVision(image: UIImage, prompt: String = "Analyze for medical diagnosis", completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data."])))
            return
        }

        Task {
            do {
                let backend = VisionBackend()
                let description = try await backend.processImage(imageData, pastContext: prompt)
                DispatchQueue.main.async {
                    completion(.success(description))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    
    func sendMessageToChatGPT(messages: [ChatGPTMessage],
                              useGPT4: Bool,
                              completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "Bad URL", code: -1)))
            return
        }
        
        let systemMessage = ChatGPTMessage(
            role: "system",
            content: """
            You are a helpful health assistant. Do whatever it takes to make sure that you give accurate diagnosis if not directly stated by the user. you can request an image of the ailment.
            """
        )
        
        var newMessages = [systemMessage]
        newMessages.append(contentsOf: messages)
        let messageDictionaries = newMessages.map { ["role": $0.role, "content": $0.content] }
        
        // Decide which model to use
        let modelName = useGPT4 ? "gpt-4" : "gpt-3.5-turbo"
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": messageDictionaries
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -2)))
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Received JSON: \(json)")
                        
                        // Check if there's an error object
                        if let errorInfo = json["error"] as? [String: Any],
                           let errorMessage = errorInfo["message"] as? String {
                            completion(.failure(NSError(domain: "API Error", code: -3, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                            return
                        }
                        
                        
                        // Parse normal response
                        if let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let messageDict = firstChoice["message"] as? [String: Any],
                           let content = messageDict["content"] as? String {
                            
                            completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                        } else {
                            print("Invalid response error")
                            completion(.failure(NSError(domain: "Invalid response", code: -3)))
                        }
                    } else {
                        completion(.failure(NSError(domain: "Invalid response", code: -3)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
}
