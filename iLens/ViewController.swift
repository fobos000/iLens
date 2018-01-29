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
    var currentTextFrames: [CGRect]?
    
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
        
        let result = observations.flatMap({$0 as? VNTextObservation})
        
        currentTextFrames = result.map{ $0.boundingBox }
        DispatchQueue.main.async() {
            self.cameraView.clearTextBoxes()
            for region in result {
                self.cameraView.drawRegionBox(box: region)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func captureTapped(_ sender: Any) {
        guard
            let currentBuffer = currentBuffer,
//            let image = UIImage(pixelBuffer: currentBuffer),
            let textFrames = currentTextFrames
            else {return}
        
        let imageSlicer = ImageSlicer(pixelBuffer: currentBuffer, rects: textFrames)
        imageSlicer.getSlices { (images) in
            let photoVC = PhotoViewController(nibName: nil, bundle: nil)
            photoVC.image = images.first
            self.navigationController?.pushViewController(photoVC, animated: true)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        currentBuffer = pixelBuffer
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 0)!, options: requestOptions)
        
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
            self.init(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        } else {
            return nil
        }
    }
}

extension VNTextObservation {
//    var textBoxInFrame {
//        guard let boxes = self.characterBoxes else { return nil }
//        var xMin: CGFloat = boxes.map{$0.bottomLeft.x}.min()
//        var xMax: CGFloat = boxes.map{$0.bottomRight.x}.max()
//        var yMin: CGFloat = boxes.map{$0.bottomRight.y}.min()
//        var yMax: CGFloat = boxes.map{$0.topRight.y}.max()
//    
//        for char in boxes {
//            if char.bottomLeft.x < xMin {xMin = char.bottomLeft.x}
//            if char.bottomRight.x > xMax {xMax = char.bottomRight.x}
//            if char.bottomRight.y < yMin {yMin = char.bottomRight.y}
//            if char.topRight.y > yMax {yMax = char.topRight.y}
//        }
//        
//        let xCoord = xMin * frame.size.width
//        let yCoord = (1 - yMax) * frame.size.height
//        let width = (xMax - xMin) * frame.size.width
//        let height = (yMax - yMin) * frame.size.height
//    }
}

