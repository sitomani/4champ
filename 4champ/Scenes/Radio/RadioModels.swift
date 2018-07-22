//
//  RadioModels.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

enum RadioChannel: Int {
  case all
  case new
  case local
}

enum RadioStatus {
  case off
  case fetching(progress:Float)
  case failure
  case on
}

enum Radio
{
  // MARK: Use cases
  enum Control {
    struct Request {
      var powerOn: Bool
      var channel: RadioChannel
    }
    
    struct Response {
      var status: RadioStatus
    }
    
    struct ViewModel {
      var status: RadioStatus
    }
  }
  
  enum Playback
  {
    struct Response {
      var length: Int
      var elapsed: Int
    }
    
    struct ViewModel
    {
      var timeLeft: String
    }
  }
  
  enum ChannelBuffer {
    struct Response {
      var buffer: [MMD]
    }
    
    struct ViewModel {
      var nowPlaying: MMD?
      var nextUp: String?
    }
  }
}
