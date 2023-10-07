//
//  AmpVizScene.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SpriteKit

struct VizConstants {
    static let barWidth = 40
}

class AmpVolumeBar: SKShapeNode {
    var channel: Int = 0
    var rlTimer: Timer = Timer.init()
    
    deinit {
        rlTimer.invalidate()
    }
    
    func startDrawing() {
        // Drawing callback on timer rather than performselector, otherwise
        // the drawing stops while a scrollview scrolls
        rlTimer.invalidate()
        rlTimer = Timer.scheduledTimer(timeInterval: 0.017, target: self, selector: #selector(AmpVolumeBar.updateBar), userInfo: nil, repeats: true)
        RunLoop.current.add(rlTimer, forMode: RunLoop.Mode.common)
    }
    
    func stopDrawing() {
        rlTimer.invalidate()
    }
    
    @objc func updateBar() {
        let vol = modulePlayer.renderer.volume(onChannel: channel)
        yScale = CGFloat(vol) / 100
        if parent != nil {
            let frHeight = parent!.frame.size.height
            let pos = CGPoint(x: position.x, y: frHeight / 2.0 - frHeight * yScale / 2.0)
            position = pos
            let newColor = SKColor.init(red: 0.7, green: 0.7, blue: 0.7, alpha: CGFloat(yScale/2.0))
            fillColor = newColor
        }
    }
}

class AmpVizScene: SKScene {
    var sceneInited: Bool = false
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.backgroundColor = UIColor(red: 0.07, green: 0.20, blue: 0.34, alpha: 1.0)
        if !sceneInited {
            setupChannelBars()
            sceneInited = true
        }
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // must explicitly stop drawing in all child nodes since they're
        // using a timer for redraws
        for node in children {
            if let vbar: AmpVolumeBar = node as? AmpVolumeBar {
                vbar.stopDrawing()
            }
        }
        self.removeAllChildren()
    }
    
    func setupChannelBars() {
        let channelcount = modulePlayer.renderer.numberOfChannels()
        
        for i in 0..<channelcount {
            addChannelBar(i, numChannels: channelcount)
        }
    }

    func addChannelBar(_ channel: Int, numChannels: Int) {
        let w = Int((frame.size.width - 2.0)/CGFloat(numChannels))
        let ch = AmpVolumeBar.init(rect: CGRect(x: 0, y: 0, width: CGFloat(w) - 2.0, height: frame.size.height))
        ch.position = CGPoint(x: 2.0 + CGFloat(channel)*CGFloat(w), y: 0)
        ch.fillColor = UIColor.clear
        ch.lineWidth = 0
        ch.channel = channel
        addChild(ch)
        ch.startDrawing()
    }
}
