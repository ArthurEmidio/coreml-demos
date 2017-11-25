//
//  CameraCapture.swift
//  ObjectDetector
//
//  Created by Arthur Emídio Teixeira Ferreira on 11/26/17.
//  Copyright © 2017 Arthur Emídio Teixeira Ferreira. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraCaptureDelegate
{
    func gotFrame(imageBuffer: CVImageBuffer)
}

enum CameraPosition
{
    case front
    case back
}

enum CameraCaptureError: Error
{
    case noDevice
    case captureInitializationFailed
}

class CameraCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate
{
    private let _delegate: CameraCaptureDelegate

    private lazy var _cameraSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        return session
    }()

    init(cameraPosition: CameraPosition, delegate: CameraCaptureDelegate) throws
    {
        _delegate = delegate

        super.init()
        let captureDevice = try _obtainDevice(cameraPosition: cameraPosition)
        try _configureSession(device: captureDevice)
    }

    func start()
    {
        _cameraSession.startRunning()
    }

    func suspend()
    {
        _cameraSession.stopRunning()
    }

    func createCapturePreviewLayer(rect: CGRect) -> CALayer
    {
        let layer = AVCaptureVideoPreviewLayer(session: _cameraSession)
        layer.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: rect.size)
        layer.position = CGPoint(x: rect.midX, y: rect.midY)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            DispatchQueue.global(qos: .userInitiated).async {
                self._delegate.gotFrame(imageBuffer: imageBuffer)
            }
        }
    }

    private func _obtainDevice(cameraPosition: CameraPosition) throws -> AVCaptureDevice
    {
        var cameraDevicePosition = AVCaptureDevice.Position.unspecified
        switch cameraPosition {
        case .front:
            cameraDevicePosition = .front
        case .back:
            cameraDevicePosition = .back
        }

        let captureDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                              mediaType: .video,
                                                              position: cameraDevicePosition).devices

        guard let captureDevice = captureDevices.first else {
            throw CameraCaptureError.noDevice
        }

        return captureDevice
    }

    private func _configureSession(device: AVCaptureDevice) throws
    {
        _cameraSession.beginConfiguration()

        // Creating the input and adding it to the session.
        let videoInput = try AVCaptureDeviceInput(device: device)
        if _cameraSession.canAddInput(videoInput) {
            _cameraSession.addInput(videoInput)
        } else {
            throw CameraCaptureError.captureInitializationFailed
        }

        // Creating the output and adding it to the session.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if _cameraSession.canAddOutput(videoOutput) {
            _cameraSession.addOutput(videoOutput)
        } else {
            throw CameraCaptureError.captureInitializationFailed
        }

        // Obtaining the output connection to set the video orientation to portrait.
        guard let connection = videoOutput.connection(with: .video) else {
            throw CameraCaptureError.captureInitializationFailed
        }
        connection.videoOrientation = .portrait

        _cameraSession.commitConfiguration()

        // Creating the dispatch queue to receive frame updates.
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.cameraCapture.videoQueue"))
    }
}

extension CameraCaptureError: LocalizedError
{
    public var localizedDescription: String? {
        switch self {
        case .noDevice:
            return NSLocalizedString("The camera device was not found.", comment: "noDeviceError")
        case .captureInitializationFailed:
            return NSLocalizedString("The video capture initialization has failed.", comment: "captureInitError")
        }
    }
}
