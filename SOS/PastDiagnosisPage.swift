//
//  PastDiagnosisPage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/24/25.
//

import Foundation
import SwiftUI

struct PastDiagnosisPage: View {
    var body: some View {
        List {
            Section(header: Text("February 2025")) {
                Text("Flu symptoms - 02/10/2025")
                Text("Headache & Fever - 02/05/2025")
            }
            Section(header: Text("January 2025")) {
                Text("Cough & Cold - 01/15/2025")
            }
        }
        .navigationTitle("Past Diagnosis")
    }
}

struct PastDiagnosisPage_Previews: PreviewProvider {
    static var previews: some View {
        PastDiagnosisPage()
    }
}
