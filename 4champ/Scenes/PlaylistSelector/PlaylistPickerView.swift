//
//  PlaylistPickerView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 14.3.2020.
//  Copyright © 2020 boogie. All rights reserved.
//

import Foundation
import SwiftUI

extension Spacer {
    /// https://stackoverflow.com/a/57416760/3393964
    public func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.001).onTapGesture(count: count, perform: action)
            self
        }
    }
}

struct PlaylistPickerView: View {
    var dismissAction: (() -> Void)
    var addToPlaylistAction: ((Int) -> Void)?
    @ObservedObject var store: PlaylistSelectorStore
    @Environment(\.presentationMode) var presentationMode
    
    func addModuleToPlaylist() {
        addToPlaylistAction?(store.viewModel.currentPlaylistIndex)
    }
    
    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Color.clear
                Spacer().onTapGesture {
                    self.dismissAction()
                }
                VStack {
                    Spacer()
                    Color.white
                    Text(self.store.viewModel.module)
                    Text("PlaylistSelector_Title")
                    Picker(selection: $store.viewModel.currentPlaylistIndex, label: Text("")) {
                        ForEach(0..<self.store.viewModel.playlistOptions.count) {
                            Text(self.store.viewModel.playlistOptions[$0])
                        }
                    }.labelsHidden().background(Color.white)
                    HStack {
                        Spacer()
                        Button(action: addModuleToPlaylist) {
                            Text("PlaylistSelector_Add")
                        }.padding(25)
                        Spacer()
                        Button(action: { self.dismissAction() }) {
                            Text("G_Cancel")
                        }.padding(25)
                        Spacer()
                    }.background(Color.black.opacity(0.1))
                }.background(Color.white)
            }
            
            if self.store.viewModel.status == .downloading(progress: 0) {
                withAnimation {
            ZStack {
                Text("Search_Downloading".l13n())
            }.frame(maxWidth:.infinity, minHeight: 80).background(Color(.white))
                }.transition(.opacity)
            }
        }
    }
}

#if DEBUG
struct PlaylistPickerView_Previews : PreviewProvider {
    static var store = PlaylistSelectorStore()
    static var previews: some View {
        PlaylistPickerView(dismissAction: {}, store: store)
    }
}
#endif
