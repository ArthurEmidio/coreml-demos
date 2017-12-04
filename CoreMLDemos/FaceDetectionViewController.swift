//
//  FaceDetectionViewController.swift
//  CoreMLDemos
//
//  Created by Arthur Emídio Teixeira Ferreira on 11/26/17.
//  Copyright © 2017 Arthur Emídio Teixeira Ferreira. All rights reserved.
//

import UIKit
import Vision

class FaceDetectionViewController: UIViewController, CameraCaptureDelegate
{
    private var _cameraCapture: CameraCapture?

    private var _faceLayers = [CAShapeLayer]()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        do {
            _cameraCapture = try CameraCapture(cameraPosition: .front, delegate: self)
            let layer = _cameraCapture!.createCapturePreviewLayer(rect: self.view.frame)
            self.view.layer.addSublayer(layer)
        } catch let error {
            print("Error initializing the camera capture: \(error.localizedDescription)")
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        _cameraCapture?.start()
    }

    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        _cameraCapture?.suspend()
    }

    func gotFrame(imageBuffer: CVImageBuffer)
    {
        let request = VNDetectFaceRectanglesRequest { request, error in
            DispatchQueue.main.async {
                guard let results = request.results else {
                    print("Could not process image. \(error?.localizedDescription ?? "")")
                    return
                }

                self.clearRectangles()

                let faceObservations = results as! [VNFaceObservation]
                for faceObservation in faceObservations {
                    self.drawRectangle(faceObservation.boundingBox)
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        do {
            try handler.perform([request])
        } catch let error {
            print("Request error: \(error.localizedDescription)")
        }
    }

    func drawRectangle(_ rect: CGRect)
    {
        let frameSize = self.view.frame.size

        let width = rect.width * frameSize.width
        let height = rect.height * frameSize.height
        let x = (1.0 - rect.origin.x) * frameSize.width - width
        let y = (1.0 - rect.origin.y) * frameSize.height - height
        let rectTransformed = CGRect(x: x, y: y, width: width, height: height)

        let faceLayer = CAShapeLayer()
        faceLayer.path = UIBezierPath(roundedRect: rectTransformed, cornerRadius: 10).cgPath
        faceLayer.fillColor = UIColor.cyan.cgColor
        faceLayer.opacity = 0.4
        self.view.layer.addSublayer(faceLayer)

        _faceLayers.append(faceLayer)
    }

    func clearRectangles()
    {
        for faceLayer in _faceLayers {
            faceLayer.removeFromSuperlayer()
        }
        _faceLayers.removeAll()
    }

    @IBAction func didLongPress(_ sender: Any)
    {
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true)
    }
}
