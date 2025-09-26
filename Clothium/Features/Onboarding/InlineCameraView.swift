import SwiftUI
import AVFoundation
import Combine

// UIView с AVCaptureVideoPreviewLayer
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct InlineCameraView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let layer = view.videoPreviewLayer
        layer.session = session
        layer.videoGravity = .resizeAspectFill

        // Зеркалим превью для фронтальной камеры (привычнее для селфи)
        if let connection = layer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Поддерживаем зеркалирование при возможных изменениях соединения
        if let connection = uiView.videoPreviewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}

// Контроллер камеры: фронтальная камера + фото
final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var captureCompletion: ((UIImage?) -> Void)?

    func configureForFrontCamera() {
        guard !isConfigured else { return }
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // Input: фронтальная широкоугольная камера
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            // Output: фото
            guard self.session.canAddOutput(self.photoOutput) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addOutput(self.photoOutput)
            self.photoOutput.isHighResolutionCaptureEnabled = true

            self.session.commitConfiguration()
            self.isConfigured = true
        }
    }

    func startSession() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capture(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async {
            guard self.isConfigured else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.captureCompletion = completion
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var image: UIImage? = nil
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        }
        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}
