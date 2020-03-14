//
//  PlaylistPicker.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 8.3.2020.
//  Copyright © 2020 boogie. All rights reserved.
//

import Foundation
import SwiftUI

struct PlaylistPickerView2: View {
    var dismissAction: (() -> Void)
    var module: ModuleInfo?
    @State var selectedPlaylist = 0
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Playlist.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.plName, ascending: true)]) var playlists: FetchedResults<Playlist>
    
    func addModuleToPlaylist() {
        if let module = module {
            playlists[selectedPlaylist].addToModules(module)
            try? managedObjectContext.save()
        }
        dismissAction()
    }
    
    func buildPlaylistString(_ pl: Playlist) -> String {
        var name = pl.plName ?? ""
        if pl.plId == "default" {
            name = "PlaylistView_DefaultPlaylist".l13n()
        }
        let modCount = "(\(pl.modules?.count ?? 0))"
        let modTick = (module?.playlists?.contains(pl) ?? false) ? "✓" : ""
        let modPlay = (pl == modulePlayer.currentPlaylist) ? "▶️" : ""
        return "\(modTick)\(modPlay) \(name) \(modCount)"
    }
    
    var body: some View {
        VStack {
            Color.clear
            Spacer()
            VStack {
                Spacer()
                Color.white
                Text(module?.modName ?? "<no module selected>")
                Text("PlaylistSelector_Title").foregroundColor(.black)
                Picker(selection: $selectedPlaylist, label: Text("")) {
                    ForEach(0..<self.playlists.count) {
                            Text(self.buildPlaylistString(self.playlists[$0]))
                    }
                }.labelsHidden().background(Color.white)
                HStack {
                    Button(action: addModuleToPlaylist) {
                        Text("PlaylistSelector_Add")
                    }.padding(5)
                    Spacer()
                    Button(action: dismissAction) {
                        Text("G_Cancel")
                    }.padding(5)

                }.padding()
            }.background(Color.white)
        }
    }
}


