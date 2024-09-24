//
//  VisualisationMenu.swift
//  ampplayer
//
//  Copyright © 2024 Aleksi Sitomaniemi. All rights reserved.
//

import SwiftUI

struct VisualisationMenu: View {
    var onButtonPress: ((ViewElement) -> Void)?

    var body: some View {
        ZStack {
            Color.blue
                .edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: { onButtonPress?(.none)}, label: { Image("vizbars_disabled") })
                Button(action: { onButtonPress?(.channelBars)}, label: { Image("vizbars") })
                Button(action: { onButtonPress?(.amplitude)}, label: { Image("vizgraph") })
            }
        }
    }
}

#Preview {
    VisualisationMenu()
}
