//
//  ChatGPTService.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/25/25.
//

import Foundation

struct ChatGPTMessage {
    let role: String
    let content: String
}

class ChatGPTService {
    
    // Replace with your real API key once you obtain it
    private let openAIApiKey = "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"
    
    func sendMessageToChatGPT(messages: [ChatGPTMessage], completion: @escaping (Result<String, Error>) -> Void) {
        
        // 1) Validate the endpoint URL.
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "Bad URL", code: -1)))
            return
        }


        
        // 2) Create a system message that instructs ChatGPT to always ask for clarification
        // for health-related queries with exactly four multiple-choice options in JSON format.
        let systemMessage = ChatGPTMessage(role: "system", content: """
        You are a helpful health assistant. For every health-related query, before giving a final diagnosis, always ask a clarifying question with exactly four multiple-choice options. Return the clarification in JSON format with keys "question" and "options". For example: { "question": "What best describes your symptom?", "options": ["Mild", "Moderate", "Severe", "Other"] }. If the query is not health-related, answer normally.
        """)
        
        // 3) Prepend the system message to the conversation.
        var newMessages = [systemMessage]
        newMessages.append(contentsOf: messages)
        
        // 4) Convert each ChatGPTMessage to a dictionary.
        let messageDictionaries = newMessages.map { msg in
            [
                "role": msg.role,
                "content": msg.content
            ]
        }
        
        // 5) Build the request body.
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messageDictionaries
        ]
        
        do {
            // 6) Convert requestBody to JSON data.
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            // 7) Construct the URLRequest.
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            
            // 8) Send the request with URLSession.
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -2)))
                    return
                }
                
                // 9) Parse the JSON response.
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        // 10) Check for the normal ChatGPT response structure.
                        if let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let messageDict = firstChoice["message"] as? [String: Any],
                           let content = messageDict["content"] as? String {
                            
                            let trimmed = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            completion(.success(trimmed))
                            
                        } else {
                            // The response did not match the expected structure.
                            print("OpenAI JSON: \(json)")
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
