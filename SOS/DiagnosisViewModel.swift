//
//  DiagnosisViewModel.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import Foundation
import SwiftUI

class DiagnosisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var diagnosis: String? = nil
    @Published var nextSteps: String = ""
    
    func analyzeImage(image: UIImage?) {
        guard image != nil else { return }
        
        // Start loading
        isLoading = true
        diagnosis = nil
        nextSteps = ""
        
        // Simulate a network/API delay (replace with your real AI service call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.diagnosis = "Snake Bite Detected"
            self.nextSteps = """
            1. Remain calm.
            2. Call emergency services.
            3. Do not apply a tourniquet.
            4. Immobilize the bitten area.
            """
            self.isLoading = false
        }
    }
}

