//
//  OpenAIService.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/27/25.
//



import Foundation


struct OpenAIConfig {
    static let apiKey = "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"
    static let baseURL = "https://api.openai.com/v1"
}

enum OpenAIEndpoint {
    case vision
    var path: String {
        switch self {
        case .vision:
            return "/chat/completions"
        }
    }
}

struct VisionRequest: Encodable {
    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
        case temperature
        case maxTokens = "max_tokens"
    }

    struct Message: Encodable {
        let role: String
        let content: [Content]
    }

    struct Content: Encodable {
        let type: String
        let text: String?
        let imageUrl: ImageURL?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
        }
    }

    struct ImageURL: Encodable {
        let url: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }
}

struct OpenAIVisionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

class OpenAIService {
    static let shared = OpenAIService()

    private init() {}

    func describeImage(_ imageData: Data, pastContext: String? = nil, language: String = "en") async throws -> String {
        let base64Image = imageData.base64EncodedString()

        let systemPrompt = """
        You are an AI assistant specialized in analyzing medical images for emergency health-related issues. Thoroughly examine the image to identify both clearly visible and subtle medical conditions, symptoms, or signs that might not be immediately noticeable, such as acne, rashes, swelling, discolorations, or any abnormalities. Begin your detailed analysis with 'This is what is going on...'

        IMPORTANT:
        1. Provide your detailed description strictly in \(language).
        2. Structure your response in JSON format, including a 'description' field containing your comprehensive medical analysis.
        3. If the background of the image contains relevant items or clues that might influence or help the medical assessment, explicitly mention their presence and potential relevance in \(language).
        """

        var messages: [VisionRequest.Message] = [
            .init(role: "system", content: [.init(type: "text", text: systemPrompt, imageUrl: nil)])
        ]

        if let context = pastContext {
            messages.append(.init(role: "system", content: [
                .init(type: "text", text: "Previous context: \(context)", imageUrl: nil)
            ]))
        }

        messages.append(.init(role: "user", content: [
            .init(type: "image_url", text: nil, imageUrl: .init(url: "data:image/jpeg;base64,\(base64Image)")),
            .init(type: "text", text: "Describe this image and return the response as JSON with a 'description' field.", imageUrl: nil)
        ]))

        let request = VisionRequest(
            model: "gpt-4o-mini",
            messages: messages,
            responseFormat: .init(type: "json_object"),
            temperature: 1,
            maxTokens: 2048
        )

        let response: OpenAIVisionResponse = try await performRequest(.vision, body: request)

        print("Raw response content: \(response.choices.first?.message.content ?? "no content")")

        if let content = response.choices.first?.message.content {
            do {
                if let jsonData = content.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    print("Parsed JSON: \(json)")

                    if let description = json["description"] as? String {
                        return description
                    } else {
                        return content
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
                return content
            }
        }

        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid response content"])
    }

    private func performRequest<T: Encodable, R>(_ endpoint: OpenAIEndpoint, body: T) async throws -> R where R: Decodable {
        guard let url = URL(string: OpenAIConfig.baseURL + endpoint.path) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("OpenAI API Error: \(message)")
                throw NSError(domain: "", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message])
            } else if let errorText = String(data: data, encoding: .utf8) {
                print("Response Error: \(errorText)")
                throw NSError(domain: "", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "Status \(httpResponse.statusCode): \(errorText)"])
            }
        }

        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "none")")
            throw error
        }
    }
}
