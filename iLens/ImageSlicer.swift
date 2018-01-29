//
//  ImageSlicer.swift
//  iLens
//
//  Created by Ostap Horbach on 11/15/17.
//  Copyright © 2017 Ostap Horbach. All rights reserved.
//

import UIKit
import VideoToolbox

class ImageSlicer {
    let pixelBuffer: CVPixelBuffer
    let rects: [CGRect]
    
    init(pixelBuffer: CVPixelBuffer, rects: [CGRect]) {
        self.pixelBuffer = pixelBuffer
        self.rects = rects
    }
    
    func getSlices(callback: @escaping ([UIImage]) -> Void) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &cgImage)
        guard let image = cgImage else { return }
        
        let transform = CGAffineTransform(rotationAngle: .pi / 2).translatedBy(x: 0, y: CGFloat(-image.height))
        
        DispatchQueue.global(qos: .background).async {
            let newRects = self.rects.map {
                CGRect(x: $0.minX * CGFloat(image.width),
                       y: (1 - $0.maxY) * CGFloat(image.height),
                       width: $0.width * CGFloat(image.width),
                       height: $0.height * CGFloat(image.height))
            }
            let images = newRects.flatMap { cgImage?.cropping(to: $0) }.flatMap { UIImage(cgImage: $0, scale: 1.0, orientation: .up) }
            DispatchQueue.main.async {
                callback(images)
            }
        }
    }
}
