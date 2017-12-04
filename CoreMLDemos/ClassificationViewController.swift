//
//  ClassificationViewController.swift
//  CoreMLDemos
//
//  Created by Arthur Emídio Teixeira Ferreira on 11/25/17.
//  Copyright © 2017 Arthur Emídio Teixeira Ferreira. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ClassificationViewController: UIViewController, CameraCaptureDelegate
{
    @IBOutlet var predictionLabel: UILabel!

    private var _cameraCapture: CameraCapture?

    private var _model: VNCoreMLModel?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        do {
            self._cameraCapture = try CameraCapture(cameraPosition: .back, delegate: self)
            let previewCameraLayer = self._cameraCapture!.createCapturePreviewLayer(rect: self.view.frame)
            self.view.layer.addSublayer(previewCameraLayer)
        } catch let error {
            print("Could not capture image from camera: \(error.localizedDescription)")
        }

        do {
            self._model = try VNCoreMLModel(for: SqueezeNet().model)
        } catch let error {
            print("Could not create ML model: \(error.localizedDescription)")
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        self.view.bringSubview(toFront: self.predictionLabel)
        self._cameraCapture?.start()
    }

    override func viewDidDisappear(_ animated: Bool)
    {
        self._cameraCapture?.suspend()
    }

    func gotFrame(imageBuffer: CVImageBuffer)
    {
        guard let model = _model else {
            print("The ML model has not been initialized.")
            return;
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            DispatchQueue.main.async {
                guard let results = request.results else {
                    print("Could not classify image. \(error?.localizedDescription ?? "")")
                    return
                }

                let classifications = results as! [VNClassificationObservation]
                if let classification = classifications.first {
                    self.predictionLabel.text = classification.identifier
                    print("\(classification.identifier): \(classification.confidence)")
                }
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        do {
            try handler.perform([request])
        } catch let error {
            print("Request error: \(error.localizedDescription)")
        }
    }

    @IBAction func didLongPress(_ sender: Any)
    {
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true)
    }
}
