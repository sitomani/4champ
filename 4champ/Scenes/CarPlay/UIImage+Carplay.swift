//
//  UIImage+Carplay.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 15.3.2026.
//

import UIKit

extension UIImage {
  private static let formatLabelAttrs: [NSAttributedString.Key: Any] = [
    .font: UIFont.boldSystemFont(ofSize: 11),
    .foregroundColor: UIColor.darkText
  ]
  
  private class func drawFormatLabel(_ format: String, in size: CGSize) {
    let text = format.uppercased() as NSString
    let textSize = text.size(withAttributes: Self.formatLabelAttrs)
    let origin = CGPoint(
      x: (size.width - textSize.width) / 2,
      y: size.height - textSize.height - 8
    )
    text.draw(at: origin, withAttributes: Self.formatLabelAttrs)
  }
  
  class func moduleIcon(for module: MMD) -> UIImage? {
    let base = UIImage(named: "modicon")?.withRenderingMode(.alwaysOriginal) ?? UIImage()
    return UIGraphicsImageRenderer(size: base.size).image { _ in
      base.draw(in: CGRect(origin: .zero, size: base.size))
      if let format = module.type, !format.isEmpty {
        drawFormatLabel(format, in: base.size)
      }
    }
  }
  
  func withBadge() -> UIImage {
    let badgeDiameter: CGFloat = min(size.width, size.height) * 0.4
    let badgePadding: CGFloat = max(2, badgeDiameter * 0.08)
    let badgeRect = CGRect(
      x: size.width - badgeDiameter,
      y: badgePadding,
      width: badgeDiameter,
      height: badgeDiameter
    )
    
    // UIGraphicsRenderer does not automatically pick interface traits from system
    // => render light/dark variants separately and register the variants with badge
    let imageAsset = UIImageAsset()
    
    // Light mode image
    let lightTraits = UITraitCollection(userInterfaceStyle: .light)
    let lightImage = UIGraphicsImageRenderer(size: size).image { context in
      let resolvedColor = UIColor.label.resolvedColor(with: lightTraits)
      resolvedColor.setFill()
      context.fill(CGRect(origin: .zero, size: size))
      self.draw(at: .zero, blendMode: .destinationIn, alpha: 0.70)
      
      UIColor.systemRed.setFill()
      UIBezierPath(ovalIn: badgeRect).fill(with: .normal, alpha: 0.8)
    }
    imageAsset.register(lightImage, with: lightTraits)
    
    // Dark mode image
    let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
    let darkImage = UIGraphicsImageRenderer(size: size).image { context in
      let resolvedColor = UIColor.label.resolvedColor(with: darkTraits)
      resolvedColor.setFill()
      context.fill(CGRect(origin: .zero, size: size))
      self.draw(at: .zero, blendMode: .destinationIn, alpha: 0.70)
      
      UIColor.systemRed.setFill()
      UIBezierPath(ovalIn: badgeRect).fill(with: .normal, alpha: 0.8)
    }
    imageAsset.register(darkImage, with: darkTraits)
    
    return imageAsset.image(with: UITraitCollection.current)
  }
}
