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
    
    var session: AVCaptureSession?
    let stillImageOutput = AVCapturePhotoOutput()
    
    private(set) weak var photoOutputDelegate: AVCapturePhotoCaptureDelegate?
    lazy var photoOutput: AVCapturePhotoOutput = {
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        
        return photoOutput
    }()
    
    func startCamera() {
        let session = AVCaptureSession()
        self.session = session
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.addInput(input)
        let prevLayer = AVCaptureVideoPreviewLayer(session: session)
        prevLayer.frame.size = frame.size
        prevLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        prevLayer.connection?.videoOrientation = .portrait
        
//        delegate.map{ self.setVideoOutputDelegate($0) }
        
        layer.addSublayer(prevLayer)
        
        session.startRunning()
    }
    
    func makePhoto() {
        guard let photoOutputDelegate = photoOutputDelegate else { return }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: photoOutputDelegate)
    }
    
    func setVideoOutputDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if let session = session, session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
    
    func setPhotoOutputDelegate(_ delegate: AVCapturePhotoCaptureDelegate) {
        photoOutputDelegate = delegate
        if let session = session, session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }
    
    func clearTextBoxes() {
        layer.sublayers?.removeSubrange(1...)
    }
    
    func drawRegionBox(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {return}
        var xMin: CGFloat = 9999.0
        var xMax: CGFloat = 0.0
        var yMin: CGFloat = 9999.0
        var yMax: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < xMin {xMin = char.bottomLeft.x}
            if char.bottomRight.x > xMax {xMax = char.bottomRight.x}
            if char.bottomRight.y < yMin {yMin = char.bottomRight.y}
            if char.topRight.y > yMax {yMax = char.topRight.y}
        }
        
        let xCoord = xMin * frame.size.width
        let yCoord = (1 - yMax) * frame.size.height
        let width = (xMax - xMin) * frame.size.width
        let height = (yMax - yMin) * frame.size.height
        
        let layer = CALayer()
        layer.frame = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.green.cgColor
        
        self.layer.addSublayer(layer)
    }

}
