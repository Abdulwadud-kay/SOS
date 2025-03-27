//
//  CameraView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/21/25.
//


// CameraView.swift
import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    
    let onImageAnalyzed: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var capturePhotoTrigger = false
    private let chatGPTService = ChatGPTService() // <-- Corrected

    func analyzeImage(_ image: UIImage) {
        chatGPTService.analyzeImageWithVision(image: image, prompt: "Analyze for medical diagnosis") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let description):
                    onImageAnalyzed(description)
                case .failure(let error):
                    onImageAnalyzed("Error: \(error.localizedDescription)")
                }
                dismiss()
            }
        }
    }

    var body: some View {
        ZStack {
            CameraCaptureView(onPhotoTaken: analyzeImage, capturePhotoTrigger: $capturePhotoTrigger)

            VStack {
                HStack {
                    Button("Close") { dismiss() }
                        .padding()
                    Spacer()
                }

                Spacer()

                Button("Take Photo") {
                    capturePhotoTrigger = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.bottom, 30)
            }
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    let onPhotoTaken: (UIImage) -> Void
    @Binding var capturePhotoTrigger: Bool

    func makeUIViewController(context: Context) -> CameraCaptureVC {
        let vc = CameraCaptureVC()
        vc.onPhotoTaken = onPhotoTaken
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraCaptureVC, context: Context) {
        if capturePhotoTrigger {
            uiViewController.takePhoto()
            DispatchQueue.main.async {
                self.capturePhotoTrigger = false
            }
        }
    }
}

class CameraCaptureVC: UIViewController, AVCapturePhotoCaptureDelegate {
    var onPhotoTaken: ((UIImage) -> Void)?
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        } catch {
            print("Error setting up camera input: \(error)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else { return }
        onPhotoTaken?(uiImage)
    }
}
