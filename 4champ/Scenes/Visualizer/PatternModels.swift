//
//  PatternModels.swift
//  ampplayer
//
//  Copyright © 2025 Aleksi Sitomaniem. All rights reserved.
//

import UIKit

enum RowElementType {
    case note
    case instrument
    case effect1
    case effect2
}

let elementTypeColors: [RowElementType: UIColor] = [
  .note: .white,
  .instrument: .green.withAlphaComponent(0.8),
  .effect1: .red.withAlphaComponent(0.8),
  .effect2: .yellow.withAlphaComponent(0.8)
]

let emptyElementStrings: [RowElementType: String] = [
  .note: "···",
  .instrument: "··",
  .effect1: "··",
  .effect2: "···"
]

struct PatternRow: Equatable {
  let note: String
  let instrument: String
  let effect1: String
  let effect2: String
  
  let rowElements: [RowElementType]
      
  init(note: String,
       instrument: String,
       effect1: String,
       effect2: String,
       channels: Int = 4,
       modType: String = "",
       smallDisplay: Bool = false) {
    self.note = note
    self.instrument = instrument
    self.effect1 = effect1
    self.effect2 = effect2
    
    var elements: [RowElementType] = []
    // For > 8 channels: show effect2 if note is only dots, otherwise show note
    if channels > 8 {
      if note.count == 0 && effect2.count > 0 {
        elements.append(.effect2)
      } else {
        elements.append(.note)
      }
      self.rowElements = elements
      return
    }
    
    // Note - white or light grey if dots only
    elements.append(.note)
        
    // For 5-8 channels: show effect2 if instrument is only dots, otherwise show instrument
    if channels > 4 {
      if instrument.count == 0 && effect2.count > 0 {
        elements.append(.effect2)
      } else {
        elements.append(.instrument)
      }
      self.rowElements = elements
      return
    }
    
    elements.append(.instrument)
    
    if modType == "MOD" || modType == "STK" || smallDisplay {
      elements.append(.effect2)
      self.rowElements = elements
      return
    }
    
    elements.append(.effect1)
    elements.append(.effect2)
    self.rowElements = elements
  }
}

struct ChannelData: Equatable {
  let channelIndex: Int
  let rows: [PatternRow]
}

struct PatternData: Equatable {
  var rowIndex: Int
  var patternIndex: Int
  var channelData: [ChannelData]
}

// rowdata pattern groups
let pattern = #"^(.{3})(.{3})(.{3})(.{4})"#

protocol PtnModelObserver: AnyObject {
  func patternChanged()
  func rowChanged()
}

class PtnModel {
  var patternData: PatternData = PatternData(rowIndex: 0, patternIndex: 0, channelData: [])
  var channelCount = 4
  var modType: String = ""
  var forceUpdate: Bool = false
  weak var modelObserver: PtnModelObserver?
  private var updateTimer: Timer?
  private var lastRowIndex: Int = -1
  private var lastPatternIndex: Int = -1
  private var cachedPatternData: [ChannelData] = []
  private lazy var regex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: pattern, options: [])
  }()
  private var smallDisplay = false
    
  func loadPatternData() {
    var channelDataArray: [ChannelData] = []
    channelCount = modulePlayer.renderer.numberOfChannels()
    modType = modulePlayer.currentModule?.type ?? ""
    let renderChannels = min(channelCount, 16)
    let currentPattern = modulePlayer.renderer.getCurrentPattern()
    
    for channelIndex in 0..<renderChannels {
      if let rows = modulePlayer.renderer.getPatternData(channelIndex) {
        
        let processedRows: [PatternRow] = rows.map { row -> PatternRow in
          let nsString = row as NSString
           if let match = regex?.firstMatch(in: row, options: [], range: NSRange(location: 0, length: nsString.length)) {
             let note = nsString.substring(with: match.range(at: 1)).replacingOccurrences(of: ".", with: "")
             let instrument = nsString.substring(with: match.range(at: 2)).replacingOccurrences(of: ".", with: "")
             let effect1 = nsString.substring(with: match.range(at: 3)).replacingOccurrences(of: ".", with: "")
             let effect2 = nsString.substring(with: match.range(at: 4)).replacingOccurrences(of: ".", with: "")
             let patternRow = PatternRow(note: note.trimmingCharacters(in: .whitespaces),
                                         instrument: instrument.trimmingCharacters(in: .whitespaces),
                                         effect1: effect1.trimmingCharacters(in: .whitespaces),
                                         effect2: effect2.trimmingCharacters(in: .whitespaces),
                                         channels: renderChannels,
                                         modType: modType,
                                         smallDisplay: smallDisplay)
             return patternRow
           }
          return PatternRow(note: "", instrument: "", effect1: "", effect2: "", channels: renderChannels, modType: modType)
        }
        
        channelDataArray.append(ChannelData(channelIndex: channelIndex, rows: processedRows))
      }
    }
    lastPatternIndex = currentPattern
    cachedPatternData = channelDataArray
    patternData.patternIndex = currentPattern
    patternData.channelData = channelDataArray
  }
  
  func updatePattern() {
    let currentRow = modulePlayer.renderer.getCurrentRow()
    let currentPattern = modulePlayer.renderer.getCurrentPattern()
        
    let needsReload = forceUpdate || currentPattern != lastPatternIndex

    if needsReload {
      loadPatternData()
      lastRowIndex = currentRow
      patternData.rowIndex = currentRow
      modelObserver?.patternChanged()
    } else if currentRow != lastRowIndex {
      lastRowIndex = currentRow
      patternData.rowIndex = currentRow
      modelObserver?.rowChanged()
    }
  }
  
  init(patternData: PatternData, smallDisplay: Bool) {
    self.patternData = patternData
    self.smallDisplay = smallDisplay
    loadPatternData()
  }
  
  func startTimer() {
    updateTimer?.invalidate()
    updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/50, repeats: true, block: { [weak self] _ in
      self?.updatePattern()
    })
  }
  
  func stopTimer() {
    log.debug("")
    updateTimer?.invalidate()
  }
  
  deinit {
    updateTimer?.invalidate()
  }
}
