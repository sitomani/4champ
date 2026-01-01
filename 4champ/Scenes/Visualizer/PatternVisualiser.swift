//
//  PatternVisualiser.swift
//  ampplayer
//
//  Copyright © 2025 Aleksi Sitomaniemi. All Rights Reserved.
//

import SwiftUI
import UIKit

class PatternVisualiser: UIView {
  private var channelLayers: [CAScrollLayer] = []
  private var textLayers: [[CATextLayer]] = []
  private var channelData: [ChannelData] = []
  private var currentRow: Int = 0
  private var currentPatternIndex: Int = -1
  private let rowHeight: CGFloat = 20
  private var highlightTopLayer: CALayer?
  private var highlightBottomLayer: CALayer?
  var smallDisplay: Bool = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    layer.isOpaque = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
  func updateData(channelData: [ChannelData], currentRow: Int, patternIndex: Int, forceUpdate: Bool = false) {
    guard bounds.width > 0 && bounds.height > 0 else {
      self.channelData = channelData
      self.currentRow = currentRow
      self.currentPatternIndex = patternIndex
      return
    }
    
    let needsRecreate = forceUpdate ||
                        channelLayers.isEmpty ||
                        patternIndex != currentPatternIndex
    let oldRow = self.currentRow
    
    self.channelData = channelData
    self.currentRow = currentRow
    self.currentPatternIndex = patternIndex
    
    if needsRecreate {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      recreateLayers()
      CATransaction.commit()
    }
    
    if oldRow != currentRow {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      updateScroll()
      updateOpacities()
      CATransaction.commit()
    }
  }
  
  private func createHighlightLayers() {
    let centerY = bounds.height / 2
    let highlightTop = CALayer()
    highlightTop.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
    highlightTop.frame = CGRect(x: 0, y: centerY - rowHeight / 2, width: bounds.width, height: 1)
    layer.addSublayer(highlightTop)
    highlightTopLayer = highlightTop
    
    let highlightBottom = CALayer()
    highlightBottom.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
    highlightBottom.frame = CGRect(x: 0, y: centerY + rowHeight / 2, width: bounds.width, height: 1)
    layer.addSublayer(highlightBottom)
    highlightBottomLayer = highlightBottom
  }
  
  private func getColor(forType type: RowElementType, text: String) -> UIColor {
    if text.isEmpty {
      return .white
    }
    return (elementTypeColors[type] ?? .white)
  }
  
  private func initTextLayer(for rowIndex: Int, channelWidth: CGFloat) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.frame = CGRect(
      x: 0,
      y: CGFloat(rowIndex) * rowHeight,
      width: channelWidth,
      height: rowHeight
    )
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.alignmentMode = .center
    textLayer.isWrapped = false
    textLayer.truncationMode = .none
    return textLayer
  }
  
  private func createRowLayer(row: PatternRow, font: UIFont, rowIndex: Int, channelWidth: CGFloat) -> CATextLayer {
    let textLayer = initTextLayer(for: rowIndex, channelWidth: channelWidth)
    let nsAttrString = NSMutableAttributedString(string: "")
    var elementIndex = 0
    row.rowElements.forEach { element in
      var text = ""
      var color = UIColor.white
      
      switch element {
      case .note:
        text = row.note
        color = getColor(forType: element, text: text)
      case .instrument:
        text = row.instrument
        color = getColor(forType: element, text: text)
      case .effect1:
        text = row.effect1
        color = getColor(forType: element, text: text)
      case .effect2:
        text = row.effect2
        color = getColor(forType: element, text: text)
      }
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        text = emptyElementStrings[element] ?? ""
        color = getColor(forType: .note, text: text)
      }
      
      let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
      ]
      
      // prepend with space when needed
      let lastShortColumn = smallDisplay ? 2 : 3
      if elementIndex > 0 {
        if elementIndex < lastShortColumn {
          if text.count < 3 {
            nsAttrString.append(NSAttributedString(string: " ", attributes: attributes))
          }
        } else {
          nsAttrString.append(NSAttributedString(string: " ", attributes: attributes))
        }
      }
      
      let attributedText = NSAttributedString(string: text, attributes: attributes)
      nsAttrString.append(attributedText)
      elementIndex += 1
    }
    
    textLayer.string = nsAttrString

    return textLayer
  }
  
  private func addChannelBorders(to layer: CALayer, channelIndex: Int, channelWidth: CGFloat, totalHeight: CGFloat) {
    // Add borders between channels, except at edges
    let isFirstChannel = channelIndex == 0
    let isLastChannel = channelIndex == channelData.count - 1
    
    if !isFirstChannel {
      let leftBorder = CALayer()
      leftBorder.frame = CGRect(x: 0, y: 0, width: 1, height: totalHeight)
      leftBorder.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
      layer.addSublayer(leftBorder)
    }
    
    if !isLastChannel {
      let rightBorder = CALayer()
      rightBorder.frame = CGRect(x: channelWidth - 1, y: 0, width: 1, height: totalHeight)
      rightBorder.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
      layer.addSublayer(rightBorder)
    }
  }
  
  private func recreateLayers() {
    channelLayers.forEach { $0.removeFromSuperlayer() }
    channelLayers.removeAll()
    textLayers.removeAll()
    highlightTopLayer?.removeFromSuperlayer()
    highlightBottomLayer?.removeFromSuperlayer()
    
    guard !channelData.isEmpty && currentPatternIndex >= 0 else { return }
    
    let channelWidth = bounds.width / CGFloat(channelData.count)
    let fontSize = smallDisplay ? 11.0 : 13.0
    let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    
    createHighlightLayers()
    
    // Create layers for each channel
    for (channelIndex, channel) in channelData.enumerated() {
      let scrollLayer = CAScrollLayer()
      scrollLayer.frame = CGRect(
        x: CGFloat(channelIndex) * channelWidth,
        y: 0,
        width: channelWidth,
        height: bounds.height
      )
      scrollLayer.masksToBounds = true
      layer.addSublayer(scrollLayer)
      channelLayers.append(scrollLayer)
      
      var channelTextLayers: [CATextLayer] = []
      
      // Create text layers for each row
      let totalHeight = CGFloat(channel.rows.count) * rowHeight
      for (rowIndex, row) in channel.rows.enumerated() {
        let textLayer = createRowLayer(row: row, font: font, rowIndex: rowIndex, channelWidth: channelWidth)
        scrollLayer.addSublayer(textLayer)
        channelTextLayers.append(textLayer)
      }
      textLayers.append(channelTextLayers)
      addChannelBorders(to: scrollLayer, channelIndex: channelIndex, channelWidth: channelWidth, totalHeight: totalHeight)
    }
    
    updateScroll()
    updateOpacities()
  }
  
  private func updateScroll() {
    let centerOffset = bounds.height / 2
    let targetY = CGFloat(currentRow) * rowHeight - centerOffset + rowHeight / 2
    
    for scrollLayer in channelLayers {
      scrollLayer.scroll(to: CGPoint(x: 0, y: targetY))
    }
  }
  
  private func updateOpacities() {
    let maxVisibleRows = Int(bounds.height / rowHeight)
    let maxDistance = CGFloat(maxVisibleRows / 2)
    
    for layers in textLayers {
      for (rowIndex, textLayer) in layers.enumerated() {
        let distance = abs(rowIndex - currentRow)
        let normalizedDistance = min(CGFloat(distance) / maxDistance, 1.0)
        let opacity = 1.0 - (normalizedDistance * 0.8)
        textLayer.opacity = Float(opacity)
      }
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if !channelData.isEmpty && channelLayers.isEmpty {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      recreateLayers()
      CATransaction.commit()
    } else if !channelLayers.isEmpty {
      // Update layer frames
      let channelWidth = bounds.width / CGFloat(channelLayers.count)
      for (index, scrollLayer) in channelLayers.enumerated() {
        scrollLayer.frame = CGRect(
          x: CGFloat(index) * channelWidth,
          y: 0,
          width: channelWidth,
          height: bounds.height
        )
      }
      let centerY = bounds.height / 2 - (smallDisplay ? 3.0 : 2.0)
      highlightTopLayer?.frame = CGRect(x: 0, y: centerY - rowHeight / 2, width: bounds.width, height: 1)
      highlightBottomLayer?.frame = CGRect(x: 0, y: centerY + rowHeight / 2, width: bounds.width, height: 1)
    }
  }
  
  deinit {
    log.debug("")
  }
}
