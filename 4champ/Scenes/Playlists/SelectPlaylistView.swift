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

// from https://stackoverflow.com/questions/56505528/swiftui-update-navigation-bar-title-color
// would work if translucency was possible
struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
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
    @Binding var showModal: Bool
    @State private var listId = UUID()
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Playlist.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.plName, ascending: true)]) var playlists: FetchedResults<Playlist>
    @State private var editingName = false
    @State private var name = ""
    @State private var editedPlaylist: Playlist?

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
            log.error(error)
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
        let indices = Array(offsets)
        let pl = self.playlists[indices[0]]
        self.managedObjectContext.delete(pl)
        try? self.managedObjectContext.save()
    }

    var body: some View {
        NavigationView {
            VStack {
                if editingName {
                    HStack {
                        TextField("PlaylistView_PlaylistName".l13n(), text: $name)
                            .foregroundColor(Color(.white))
                            .background(RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(Color(Appearance.ampTextfieldBgColor))
                                .frame(minHeight: 48)
                                .padding(EdgeInsets(top: 0, leading: -10, bottom: 0, trailing: 8)))
                            .padding(EdgeInsets(top: 8, leading: 20, bottom: 2, trailing: 0)).frame(minHeight: 44)
                        Button(action: {
                                self.upsertPlaylist(name: self.name, playlist: self.editedPlaylist)
                        }, label: {
                            Image(uiImage: UIImage(named: "save_playlist")!)
                        }).accentColor(Color(Appearance.successColor))
                            .disabled(self.name.count == 0)
                        Button(action: {
                            self.name = ""
                            self.editedPlaylist = nil
                            self.endEditing()
                            withAnimation {
                                self.editingName = false
                            }
                        }, label: {
                            Image(uiImage: UIImage(named: "cancel_save")!)
                            }) .accentColor(Color(Appearance.errorColor)).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                        .contentShape(Rectangle())
                    }.background(Color(Appearance.darkBlueColor)).transition(.slide)
                }
                List {
                    ForEach(self.playlists) { pl in
                        if pl.plName != "radioList" {
                            PlaylistCell(pl: pl).contentShape(Rectangle()).onTapGesture {
                                moduleStorage.currentPlaylist = pl
                                self.showModal.toggle()
                            }
                            .onLongPressGesture {
                                self.edit(pl: pl)
                            }
                        }
                    }.onDelete(perform: delete).listRowBackground(Color.clear)
                }.listStyle(.plain).contentShape(Rectangle()).id(listId)
                .modifier(ListBackgroundModifier())

            }.navigationBarTitle("PlaylistView_Playlists", displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    self.showModal.toggle()
                }, label: {
                    Image(systemName: "xmark").imageScale(.large)
                    }),
                    trailing: Button(action: {
                withAnimation {
                    self.editedPlaylist = nil
                    self.name = ""
                    self.editingName.toggle()
                }
                }, label: {
                    Image(systemName: "plus").imageScale(.large)
                })).background(Color(Appearance.darkBlueColor))
        }.background(Color(Appearance.darkBlueColor)).navigationViewStyle(StackNavigationViewStyle())
    }
}
