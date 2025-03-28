//
//  SettingsView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/28/25.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            Form {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                }
                .toggleStyle(SwitchToggleStyle(tint: .red))
            }
            .navigationTitle("Settings")
        }
    }
}