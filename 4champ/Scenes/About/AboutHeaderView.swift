//
//  AboutHeaderView.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
}


extension UIImage {
  func resizeImageWith(newSize: CGSize) -> UIImage {
    let horizontalRatio = newSize.width / size.width
    let verticalRatio = newSize.height / size.height
    let ratio = max(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
  }
}

class AboutHeaderView: UIButton {
  
  convenience init(frame: CGRect, titleKey: String, imageKey: String) {
    self.init(frame: frame)
    titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
    setTitleColor(UIColor.init(rgb: 0xc6c6c6), for: .normal)
    setTitle("  \(titleKey.l13n())", for: .normal)
    imageView?.contentMode = .scaleAspectFit
    backgroundColor = Appearance.ampLightBlueColor
    tintColor = UIColor.init(rgb: 0xc6c6c6);
    if let image = UIImage.init(named: imageKey) {
      
      if titleKey == "Twitter" {
        let scaledImage = image.resizeImageWith(newSize: CGSize.init(width: 30, height: 25))
        setImage(scaledImage.withRenderingMode(.alwaysTemplate), for: .normal)
      } else {
        setImage(image, for: .normal)
      }
    } else {
      if imageKey == "legal" {
        let lbl = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 30, height: 25))
        lbl.text = "©"
        lbl.font = UIFont.systemFont(ofSize: 29.0)
        lbl.textColor = UIColor.init(rgb: 0xc6c6c6)
        UIGraphicsBeginImageContext(lbl.bounds.size);
        lbl.layer.render(in: UIGraphicsGetCurrentContext()!)
        let renderedImg = UIGraphicsGetImageFromCurrentImageContext();
        setImage(renderedImg, for: .normal)
      }
    }
  }
}
