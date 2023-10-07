//
//  AmpSlider.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

class AmpSlider: UISlider {
    override init (frame: CGRect) {
        super.init(frame: frame)
        addBehavior()
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addBehavior()
    }
    
    func addBehavior () {
        UIGraphicsBeginImageContext(CGSize(width: 20, height: 10))
        UIColor.white.set()
        UIRectFill(CGRect(x: 0, y: 5, width: 20, height: 1))
        UIColor.white.set()
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        var minImage: UIImage = image
        var maxImage: UIImage = image
        
        minImage = minImage.stretchableImage(withLeftCapWidth: 10, topCapHeight: 0)
        maxImage = maxImage.stretchableImage(withLeftCapWidth: 10, topCapHeight: 0)
        
        // Setup the FX slider
        self.setMinimumTrackImage(minImage, for: UIControl.State())
        self.setMaximumTrackImage(maxImage, for: UIControl.State())
        self.updatePlayhead("0.00")
        
        let gr: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(sliderTapped))
        self.addGestureRecognizer(gr)

    }
    
    func updatePlayhead(_ txt: String) {
        let myString: NSString = txt as NSString
        let txtSize: CGSize = myString.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)])
        let headSize: CGSize = CGSize(width: txtSize.width+5, height: txtSize.height)
        UIGraphicsBeginImageContextWithOptions(headSize, true, UIScreen.main.scale)
        UIColor(red: 0.06, green: 0.19, blue: 0.25, alpha: 1.0).set()
        UIRectFill(CGRect(x: 0, y: 0, width: headSize.width, height: headSize.height))
        UIColor.white.set()
        UIRectFill(CGRect(x: 0, y: 4, width: 1, height: headSize.height - 6))
        UIRectFill(CGRect(x: headSize.width-1, y: 4, width: 1, height: headSize.height-6))
        
        let font: UIFont = UIFont.systemFont(ofSize: 11.5)
        let dict: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: UIColor.white]
        
        myString.draw(at: CGPoint(x: 3, y: 1), withAttributes: dict)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        self.setThumbImage(image, for: UIControl.State())
        self.setThumbImage(image, for: .highlighted)
    }
    
    @objc func sliderTapped(_ gRec: UITapGestureRecognizer) {
        if self.isHighlighted {
            return
        }
        let pt: CGPoint = gRec.location(in: self)
        let percentage: Float = Float.init(pt.x) / Float.init(self.bounds.size.width)
        let delta: Float = percentage * (self.maximumValue - self.minimumValue)
        let value: Float = self.minimumValue + delta
        self.setValue(value, animated: false)
        modulePlayer.renderer.setCurrentPosition(Int32(self.value))
    }
}
