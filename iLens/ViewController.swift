//
//  ViewController.swift
//  iLens
//
//  Created by Ostap Horbach on 10/14/17.
//  Copyright © 2017 Ostap Horbach. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import VideoToolbox

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: CameraView!
    
    private var requests = [VNRequest]()
    var capturedImage: CGImage?
    
    var currentBuffer: CVPixelBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.startCamera()
        cameraView.setVideoOutputDelegate(self)
        cameraView.setPhotoOutputDelegate(self)
        setupVision()
    }
    
    // MARK: - Vision Setup
    
    func setupVision() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler)
        textRequest.reportCharacterBoxes = true
        
        self.requests = [textRequest]
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no result"); return}
        
        let result = observations.map({$0 as? VNTextObservation})
        
        DispatchQueue.main.async() {
            self.cameraView.clearTextBoxes()
            for region in result {
                guard let rg = region else {continue}
                self.cameraView.drawRegionBox(box: rg)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func captureTapped(_ sender: Any) {
//        cameraView.makePhoto()
        performSegue(withIdentifier: "ShowPhoto", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoViewController {
            guard let currentBuffer = currentBuffer else {return}
            let image = UIImage(pixelBuffer: currentBuffer)
            vc.image = image
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        currentBuffer = pixelBuffer
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        capturedImage = photo.cgImageRepresentation()?.takeRetainedValue()
        
        performSegue(withIdentifier: "ShowPhoto", sender: self)
    }
}

extension UIImage {
    /**
     Creates a new UIImage from a CVPixelBuffer.
     NOTE: This only works for RGB pixel buffers, not for grayscale.
     */
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &cgImage)
        
        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

