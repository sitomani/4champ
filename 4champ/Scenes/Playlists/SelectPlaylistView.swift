//
//  SelectPlaylistView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 8.3.2020.
//
import Foundation
import UIKit
import SwiftUI

struct PlaylistCell: View {
    let pl: Playlist
    var body: some View {
        HStack {
            Image(uiImage: UIImage.init(named: (self.pl.plName ?? "") == "default" ? "playlist_default" : "playlist")!)
            Text("\(pl.plName ?? "") (\(pl.modules?.count ?? 0))").foregroundColor(.white)
        }
    }
}

struct PlaylistSelectorSUI: View {
    @Binding var show_modal:Bool
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Playlist.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.plName, ascending: true)]) var playlists: FetchedResults<Playlist>
    @State private var editingName = false
    @State private var name = ""
    @State private var editedPlaylist:Playlist?
    
    func upsertPlaylist(name: String, playlist: Playlist?) {
        self.editingName = false
        if let pl = playlist {
            pl.plName = name
        } else {
            let pl = Playlist(context: managedObjectContext)
            pl.plId = UUID().uuidString
            pl.plName = name
        }
        do {
            try managedObjectContext.save()
        } catch {
            print(error)
        }
        self.editedPlaylist = nil
    }
    
    
    
    func edit(pl: Playlist) {
        editedPlaylist = pl
        name = pl.plName ?? ""
        editingName = true
    }
    
    func delete(at offsets: IndexSet) {
        print(offsets.endIndex)
        let indices = Array(offsets)
        let pl = self.playlists[indices[0]]
        self.managedObjectContext.delete(pl)
        
//        Playlist* pl = [self.fetchedResultCtrl objectAtIndexPath:indexPath];
//        if (pl == [[ModulePlayer sharedInstance] currentPlaylist]) {
//            self.selectedIP = nil;
//            [[ModulePlayer sharedInstance] stop];
//            [[ModulePlayer sharedInstance] loadPlaylist:nil];
//        }
//        [self.managedObjectContext deleteObject:pl];
//        moduleStorage.createPlaylist(name: <#T##String#>)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.editingName.toggle()
                }) {
                    Image(uiImage: UIImage(systemName: "plus.app")!).padding(5)
                }
                Spacer()
                Text("Playlists")
                Spacer()
                Button(action: {
                    self.show_modal = false
                    self.editedPlaylist = nil
                }) {
                    Text("Dismiss")
                }
            }
            if editingName {
                HStack {
                    TextField("Playlist name", text:$name)
                    Button(action: {
                        self.upsertPlaylist(name: self.name, playlist: self.editedPlaylist)
                    }) {
                        Image(uiImage: UIImage(named: "save_playlist")!)
                    }
                    Button(action: {
                        self.editingName = false
                        self.editedPlaylist = nil
                    }) {
                        Image(uiImage: UIImage(named: "cancel_save")!)
                    }
                }
            }
            List {
                ForEach(self.playlists) { pl in
                    if pl.plName != "radioList" {
                        PlaylistCell(pl: pl).onTapGesture {
                            modulePlayer.currentPlaylist = pl
                            self.show_modal.toggle()
                        }
                        //onLongPressGesture {
                        //    self.edit(pl: pl)
                        //}.
                    }
                }.onDelete(perform: delete)
            }
        }
    }
}
