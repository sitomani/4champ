//
//  VisualisationMenu.swift
//  ampplayer
//
//  Copyright © 2024 Aleksi Sitomaniemi. All rights reserved.
//

import SwiftUI

let element2Image: [ViewElement: String] = [
    .none: "vizbars_disabled",
    .channelBars: "vizbars",
    .amplitude: "vizgraph",
    .text: "modtext",
    .pattern: "trkbars"
]

enum MenuType {
    case visualization
    case text
}

struct VisualisationMenu: View {
    var type: MenuType = .visualization
    var onButtonPress: ((ViewElement) -> Void)?

    func getElements() -> [ViewElement] {
        switch type {
        case .visualization:
            return [.none, .channelBars, .amplitude]
        case .text:
            return [.none, .text, .pattern]
        }
    }
    func getImage(_ element: ViewElement) -> Image {
        var img: String = ""
        if let image = element2Image[element] {
            img = image
        }
        if type == .text && element == .none {
            img = "modtext_disabled"
        }
        return Image(img)
    }

    var body: some View {
        ZStack {
            Color.blue
                .edgesIgnoringSafeArea(.all)
            HStack {
                ForEach(getElements(), id: \.self) { element in
                    Button(action: { onButtonPress?(element)}, label: { getImage(element) })
                }
            }
        }
    }
}

#Preview {
    VisualisationMenu(type: .visualization)
}
