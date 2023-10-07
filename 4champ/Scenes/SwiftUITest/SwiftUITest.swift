//
//  SwiftUITest.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 15.3.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import SwiftUI

struct ContentView: View {
    // 1.
    @State private var numbers = ["One", "Two", "Three", "Four", "Five"]

    var body: some View {
        NavigationView {
            List {
                // 2.
                ForEach(numbers, id: \.self) { number in
                    Text(number)
                }
                // 3.
                .onMove { (indexSet, index) in
                    self.numbers.move(fromOffsets: indexSet,
                                    toOffset: index)
                }

            .navigationBarTitle(Text("Numbers"))
            }
            // 4.
            .navigationBarItems(trailing: EditButton())
        }
    }
}
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
