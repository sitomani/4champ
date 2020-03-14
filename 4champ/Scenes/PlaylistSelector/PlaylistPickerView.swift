//
//  PlaylistPickerView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 14.3.2020.
//  Copyright © 2020 boogie. All rights reserved.
//

import Foundation
import SwiftUI

struct PlaylistPickerView: View {
    var dismissAction: (() -> Void)
    var addToPlaylistAction: ((Int) -> Void)?
    @ObservedObject var store: PlaylistSelectorStore
    @State var selectedPlaylist = 0
    @Environment(\.presentationMode) var presentationMode
    
    func addModuleToPlaylist() {
        addToPlaylistAction?(selectedPlaylist)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Color.clear
                Spacer()
                VStack {
                    Spacer()
                    Color.white
                    Text(self.store.viewModel.module)
                    Text("PlaylistSelector_Title")
                    Picker(selection: $selectedPlaylist, label: Text("")) {
                        ForEach(0..<self.store.viewModel.playlistOptions.count) {
                            Text(self.store.viewModel.playlistOptions[$0])
                        }
                    }.labelsHidden().background(Color.white)
                    HStack {
                        Button(action: addModuleToPlaylist) {
                            Text("PlaylistSelector_Add")
                        }.padding(5)
                        Spacer()
                        Button(action: { self.dismissAction() }) {
                            Text("G_Cancel")
                        }.padding(5)
                        
                    }.padding()
                }.background(Color.white)
            }
            if self.store.viewModel.progress != 1.0 {
                Text("\(Int(self.store.viewModel.progress*100))")
                    .background(Color.red)
                    .padding(.all, 10)
                    .frame(width:200, height: 42)
            }
        }
    }
}
