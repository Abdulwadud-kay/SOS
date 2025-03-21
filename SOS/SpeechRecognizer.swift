//
//  SpeechRecognizer.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/17/25.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    func requestAuthorization(_ onUpdate: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    onUpdate("Microphone ready for speech recognition.")
                case .denied:
                    onUpdate("Speech recognition access denied.")
                case .restricted:
                    onUpdate("Speech recognition restricted.")
                case .notDetermined:
                    onUpdate("Speech recognition not determined.")
                @unknown default:
                    onUpdate("Unknown speech recognition error.")
                }
            }
        }
    }

    func startTranscribing(_ onUpdate: @escaping (String) -> Void) {
        // If audio engine is running, stop the old session first.
        if audioEngine.isRunning {
            stopTranscribing()
        }

        // Ensure we have microphone permission
        requestAuthorization { message in
            print(message)
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true

        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            onUpdate("Error: Unable to start audio engine.")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    onUpdate(result.bestTranscription.formattedString)
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    onUpdate("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopTranscribing() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
