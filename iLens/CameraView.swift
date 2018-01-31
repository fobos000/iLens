//
//  CameraView.swift
//  iLens
//
//  Created by Ostap Horbach on 10/14/17.
//  Copyright © 2017 Ostap Horbach. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraView: UIView {
    
    func startCamera() {
        self.session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session?.addInput(input)
        videoPreviewLayer.videoGravity = .resize
        session?.startRunning()
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func setVideoOutputDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if let session = session, session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            let connection = videoOutput.connection(with: .video)
            if let connection = connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
    
    func clearTextBoxes() {
        layer.sublayers?.removeSubrange(1...)
    }
    
    func drawRegionBox(box: CGRect) {
        let regionFrame = CGRect(x: box.minX * frame.size.width,
                                 y: (1 - box.maxY) * frame.size.height,
                                 width: box.width * frame.width,
                                 height: box.height * frame.height)

        let layer = CALayer()
        layer.frame = regionFrame
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.green.cgColor

        self.layer.addSublayer(layer)
    }

}
