//
//  PhotoViewController.swift
//  iLens
//
//  Created by Ostap Horbach on 11/15/17.
//  Copyright © 2017 Ostap Horbach. All rights reserved.
//

import UIKit
import TesseractOCR
import PhoneNumberKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
        
        DispatchQueue.global(qos: .background).async {
            if let image = self.image, let tesseract = G8Tesseract(language: "eng") {
                tesseract.engineMode = .tesseractCubeCombined
                tesseract.pageSegmentationMode = .auto
                tesseract.image = image.g8_blackAndWhite()
                tesseract.recognize()
                DispatchQueue.main.async {
                    let recognizedText = tesseract.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.textLabel.text = recognizedText
                    
                    var recognizedItem: RecognizedItem
                    if let email = email(from: recognizedText) {
                        recognizedItem = RecognizedEmailItem(text: recognizedText, emailURL: email)
                    } else if let phoneNumber = verifyPhoneNumber(recognizedText) {
                        recognizedItem = RecognizedPhoteNumberItem(text: recognizedText, phoneURL: phoneNumber)
                    } else {
                        recognizedItem = RecognizedTextItem(text: recognizedText)
                    }
                    self.showMenuFor(item: recognizedItem)
                }
            }
        }
    }
    
    func showMenuFor(item: RecognizedItem) {
        let alertActions = item.supportedActions.map { action -> UIAlertAction in
            let alertAction = UIAlertAction(title: action.title, style: .default, handler: { _ in
                action.performAction(item)
            })
            return alertAction
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertActions.forEach { alertController.addAction($0) }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

}



func verifyUrl(urlString: String) -> Bool {
    if let url = URL(string: urlString) {
        return UIApplication.shared.canOpenURL(url)
    }
    return false
}

func email(from text: String) -> URL? {
    let allMatches = matches(for: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", in: text)
    guard let match = allMatches.first else { return nil }
    
    return URL(string: "mailto://" + match)
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

func verifyPhoneNumber(_ number: String) -> URL? {
    var phoneNumber: String
    do {
        let phoneNumberKit = PhoneNumberKit()
        phoneNumber = try phoneNumberKit.parse(number).numberString
        return URL(string: "tel://" + phoneNumber)
    }
    catch {
        print("Generic parser error")
    }
    
    return nil
}
