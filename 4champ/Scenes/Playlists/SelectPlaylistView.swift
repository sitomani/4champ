//
//  SelectPlaylistView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 8.3.2020.
//
import Foundation
import UIKit
import SwiftUI

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PlaylistCell: View {
    let pl: Playlist
    var body: some View {
        HStack {
            Image(uiImage: UIImage.init(named: (self.pl.plName ?? "") == "default" ? "playlist_default" : "playlist")!)
            Text("\(pl.getDisplayName()) (\(pl.modules?.count ?? 0))").foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
        }.deleteDisabled(pl.plId == "default")
    }
}

struct PlaylistSelectorSUI: View {
    @Binding var show_modal:Bool
    @State private var listId = UUID()
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Playlist.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.plName, ascending: true)]) var playlists: FetchedResults<Playlist>
    @State private var editingName = false
    @State private var name = ""
    @State private var editedPlaylist:Playlist?
    
    func upsertPlaylist(name: String, playlist: Playlist?) {
        self.endEditing()

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
        self.listId = UUID()
        withAnimation {
            self.editingName = false
        }
    }
    
    func edit(pl: Playlist) {
        if pl.plId == "default" {
            return
        }
        editedPlaylist = pl
        name = pl.plName ?? ""
        withAnimation {
            editingName = true
        }
    }
    
    func delete(at offsets: IndexSet) {
        print(offsets.endIndex)
        let indices = Array(offsets)
        let pl = self.playlists[indices[0]]
        self.managedObjectContext.delete(pl)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if editingName {
                    HStack {
                        TextField("Playlist name", text:$name).textFieldStyle(RoundedBorderTextFieldStyle()).padding(EdgeInsets(top: 8, leading: 4, bottom: 2, trailing: 0))
                        Button(action: {
                                self.upsertPlaylist(name: self.name, playlist: self.editedPlaylist)
                        }) {
                            Image(uiImage: UIImage(named: "save_playlist")!)
                        }.accentColor(Color(Appearance.successColor))
                        Button(action: {
                            withAnimation {
                                self.editingName = false
                                self.editedPlaylist = nil
                            }
                        }) {
                            Image(uiImage: UIImage(named: "cancel_save")!)
                            }.accentColor(Color(Appearance.errorColor)).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }.background(Color(Appearance.darkBlueColor)).transition(.slide)
                }
                List {
                    ForEach(self.playlists) { pl in
                        if pl.plName != "radioList" {
                            PlaylistCell(pl: pl).contentShape(Rectangle()).onTapGesture {
                                moduleStorage.currentPlaylist = pl
                                self.show_modal.toggle()
                            }
                            .onLongPressGesture {
                                self.edit(pl: pl)
                            }
                        }
                    }.onDelete(perform: delete)
                }.contentShape(Rectangle()).id(listId)
            }.navigationBarTitle("Select playlist", displayMode: .inline).navigationBarItems(trailing: Button(action: {
                print("User icon pressed...")
                withAnimation {
                    self.editedPlaylist = nil
                    self.name = ""
                    self.editingName.toggle()
                }
            }) {
                Image(systemName: "plus").imageScale(.large)
            }).background(Color(Appearance.darkBlueColor))
        }.background(Color(Appearance.darkBlueColor))
    }
}
