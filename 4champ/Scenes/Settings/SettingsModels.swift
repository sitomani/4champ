//
//  SettingsModels.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

enum Settings {
  enum Update {
    struct ValueBag {
      var stereoSeparation: Int
      var interpolation: SampleInterpolation
      var amigaResampler: Bool
    }
  }
}
