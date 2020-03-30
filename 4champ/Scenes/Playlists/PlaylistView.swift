//
//  PlaylistView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 29.2.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SUIModule: View {
    let module: MMD
    var body: some View {
        HStack {
            ZStack {
                Image(uiImage: UIImage.init(named: "modicon")!)
                Text("MOD")
                    .foregroundColor(Color.black)
                    .font(.system(size:12))
                    .offset(y:12)
                Image(uiImage: UIImage.init(named:"stopicon")!)
                    .resizable()
                    .frame(width:30, height:30).offset(x:-15)
            }.padding(8)
            VStack(alignment: .leading) {
                Text("\(module.name ?? "no name")")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("Artist").font(.system(size: 12))
                    .foregroundColor(.white)
                Text("Size").font(.system(size: 12))
                    .foregroundColor(.white)
            }
            Spacer()
            Image("favestar-yellow").padding(8).onTapGesture {
                print("faved")
            }
        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}



struct PlaylistView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var show_modal: Bool = false
    @State var showNowPlaying: Bool = false
    @State var isEditing: Bool = false
    @State private var navigationButtonID = UUID()
    @State var selectedPlaylistId: String = "default" {
        didSet {
            store.interactor?.selectPlaylist(request: Playlists.Select.Request(playlistId: self.selectedPlaylistId))
        }
    }
    @ObservedObject var store: PlaylistStore
    
    func move(from source: IndexSet, to destination: Int) {
        guard let sourceIndex:Int = source.first else {
            return
        }
        
        let req = Playlists.Move.Request(modIndex: sourceIndex, newIndex: destination)
        store.interactor?.moveModule(request: req)
        
    }
    
    func deleteItems(at offsets: IndexSet) {
        guard let index:Int = offsets.first else {
            return
        }
        store.interactor?.removeModule(request: Playlists.Remove.Request(modIndex: index))
    }
    
    func toggleShuffle() {
        store.interactor?.toggleShuffle()
    }
    
    var body: some View {
            VStack {
                Button(action: {
                    self.show_modal = true
                }) {
                Text(store.viewModel.playlistName).underline()
                    .foregroundColor(Color(.white))
                    .padding(EdgeInsets.init(top: 5, leading: 0, bottom: -5, trailing: 0))
                }.sheet(isPresented: self.$show_modal) {
                    PlaylistSelectorSUI(show_modal: self.$show_modal).environment(\.managedObjectContext,self.managedObjectContext).onDisappear {
                        self.navigationButtonID = UUID()
                    }
                }
                List {
                    ForEach(store.viewModel.modules) { mod in
                        SUIModule(module: mod)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                modulePlayer.play(mmd: mod)
                        }
                    }.onMove(perform: move)
                    .onDelete(perform: deleteItems)
                }.navigationBarTitle(Text("TabBar_Playlist".l13n().uppercased()), displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {self.toggleShuffle()}) {Image(store.viewModel.shuffle ? "shuffled" : "sequential")}, trailing: EditButton()).id(self.navigationButtonID)
                
                if store.nowPlaying {
                    VStack {
                        Text("").frame(height:50)
                    }
                }
            }.background(Color(Appearance.darkBlueColor))
    }
}

class PlaylistHostingViewController: UIHostingController<AnyView> {
    required init?(coder: NSCoder) {
        let store = PlaylistStore()
        let contentView = PlaylistView(store: store).environment(\.managedObjectContext, moduleStorage.managedObjectContext)
        store.setup()
        super.init(coder: coder, rootView:AnyView(contentView))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

#if DEBUG

func randomMMD() -> MMD {
    var mmd = MMD()
    mmd.composer = "foo"
    mmd.name = "bar"
    return mmd
}

var st = PlaylistStore(viewModel:         Playlists.Select.ViewModel(playlistName: "foo", shuffle: false, modules: [randomMMD(), randomMMD(), randomMMD()])
)

struct Playlist_Preview : PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaylistView(store: st)
        }
    }
}
#endif
