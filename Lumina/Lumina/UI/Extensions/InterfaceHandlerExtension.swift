//
//  InterfaceHandlerExtension.swift
//  Lumina
//
//  Created by David Okun IBM on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaViewController {
    @objc func handlePinchGestureRecognizer(recognizer: UIPinchGestureRecognizer) {
        guard self.position == .back else {
            return
        }
        currentZoomScale = min(maxZoomScale, max(1.0, beginZoomScale * Float(recognizer.scale)))
    }
    
    @objc func handleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        if self.position == .back {
            focusCamera(at: recognizer.location(in: self.view))
        }
    }
    
    func createUI() {
        self.view.layer.addSublayer(self.previewLayer)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
        self.view.addSubview(self.switchButton)
        self.view.addSubview(self.torchButton)
        self.view.addSubview(self.textPromptView)
        self.view.addGestureRecognizer(self.zoomRecognizer)
        self.view.addGestureRecognizer(self.focusRecognizer)
        enableUI(valid: false)
    }
    
    func enableUI(valid: Bool) {
        DispatchQueue.main.async {
            self.shutterButton.isEnabled = valid
            self.switchButton.isEnabled = valid
            self.torchButton.isEnabled = valid
        }
    }
    
    func updateUI(orientation: UIInterfaceOrientation) {
        guard let connection = self.previewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }
        self.previewLayer.frame = self.view.bounds
        connection.videoOrientation = necessaryVideoOrientation(for: orientation)
        if let camera = self.camera {
            camera.updateOutputVideoOrientation(connection.videoOrientation)
        }
    }
    
    func updateButtonFrames() {
        self.cancelButton.center = CGPoint(x: self.view.frame.minX + 55, y: self.view.frame.maxY - 45)
        if self.view.frame.width > self.view.frame.height {
            self.shutterButton.center = CGPoint(x: self.view.frame.maxX - 45, y: self.view.frame.midY)
        } else {
            self.shutterButton.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.maxY - 45)
        }
        self.switchButton.center = CGPoint(x: self.view.frame.maxX - 25, y: self.view.frame.minY + 25)
        self.torchButton.center = CGPoint(x: self.view.frame.minX + 25, y: self.view.frame.minY + 25)
        self.textPromptView.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + 45)
        self.textPromptView.layoutSubviews()
    }
    
    func handleCameraSetupResult(_ result: CameraSetupResult) {
        DispatchQueue.main.async {
            switch result {
            case .videoSuccess:
                guard let camera = self.camera else {
                    return
                }
                self.enableUI(valid: true)
                camera.start()
            case .audioSuccess:
                break
            case .requiresUpdate:
                guard let camera = self.camera else {
                    return
                }
                camera.updateVideo({ result in
                    self.handleCameraSetupResult(result)
                })
            case .videoPermissionDenied:
                self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
            case .videoPermissionRestricted:
                self.textPrompt = "Camera permissions for Lumina have been restricted - please access your privacy settings to change this."
            case .videoRequiresAuthorization:
                guard let camera = self.camera else {
                    break
                }
                camera.requestVideoPermissions()
            case .audioPermissionRestricted:
                self.textPrompt = "Audio permissions for Lumina have been restricted - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .audioRequiresAuthorization:
                guard let camera = self.camera else {
                    break
                }
                camera.requestAudioPermissions()
            case .audioPermissionDenied:
                self.textPrompt = "Audio permissions for Lumina have been previously denied - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .invalidVideoDataOutput,
                 .invalidVideoInput,
                 .invalidPhotoOutput,
                 .invalidVideoMetadataOutput,
                 .invalidVideoFileOutput,
                 .invalidAudioInput,
                 .invalidDepthDataOutput:
                self.textPrompt = "\(result.rawValue) - please try again"
            case .unknownError:
                self.textPrompt = "Unknown error occurred while loading Lumina - please try again"
            }
        }
    }
    
    private func necessaryVideoOrientation(for statusBarOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}
