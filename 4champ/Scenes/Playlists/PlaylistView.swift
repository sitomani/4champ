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

struct ListBackgroundModifier: ViewModifier {

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
            .background(Color(Appearance.ampBgColor))
            .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

struct SUIModule: View {
    let module: MMD
    let faveCallback: ((MMD) -> Void)?
    var body: some View {
        VStack {
        HStack {
            ZStack {
                Image(uiImage: UIImage.init(named: "modicon")!).resizable().frame(width: 50, height: 50)
                Text(module.type?.uppercased() ?? "MOD")
                    .foregroundColor(Color.black)
                    .font(.system(size: 12))
                    .offset(y: 13)
                if module.supported() == false {
                    Image(uiImage: UIImage.init(named: "stopicon")!)
                        .resizable()
                        .frame(width: 30, height: 30).offset(x: -15)
                }
            }
            VStack(alignment: .leading) {
                Text("\(module.name)")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                if let composer = module.composer, composer.count > 0 {
                    Text(module.composer ?? "no name").font(.system(size: 12))
                    .foregroundColor(.white)
                }
                Text("\(module.size ?? 0) kb").font(.system(size: 12))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(module.favorite ? "favestar-yellow" : "favestar-grey").padding(8).onTapGesture {
                self.faveCallback?(self.module)
            }.padding(7)
        }.padding(.init(top: 2, leading: 0, bottom: 6, trailing: 0))
        Divider().background(Color(Appearance.separatorColor))
        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

struct PlaylistView: View {
  @Environment(\.managedObjectContext) var managedObjectContext
  @State private var showModal: Bool = false
  @State var showNowPlaying: Bool = false
  @State var isEditing: Bool = false
  @State var navigationButtonID = UUID()
  @State var selectedPlaylistId: String = "default" {
    didSet {
      store.interactor?.selectPlaylist(request: Playlists.Select.Request(playlistId: self.selectedPlaylistId))
    }
  }
  @ObservedObject var store: PlaylistStore

  func move(from source: IndexSet, to destination: Int) {
    guard let sourceIndex: Int = source.first else {
      return
    }

    let req = Playlists.Move.Request(modIndex: sourceIndex, newIndex: destination)
    store.interactor?.moveModule(request: req)
  }

  func deleteItems(at offsets: IndexSet) {
    guard let index: Int = offsets.first else {
      return
    }
    store.interactor?.removeModule(request: Playlists.Remove.Request(modIndex: index))
  }

  func toggleShuffle() {
    store.interactor?.toggleShuffle()
  }

  func startImport() {
    store.interactor?.importModules()
  }

  func favorite(module: MMD) {
    store.interactor?.toggleFavorite(request: Playlists.Favorite.Request(modId: module.id!))
  }

  var body: some View {
    VStack {
      Button(action: {
        self.showModal = true
      }, label: {
        Text(store.viewModel.playlistName).underline()
          .foregroundColor(Color(.white))
          .padding(EdgeInsets.init(top: 5, leading: 0, bottom: -5, trailing: 0))
      }) .sheet(isPresented: self.$showModal) {
        PlaylistSelectorSUI(showModal: self.$showModal).environment(\.managedObjectContext, self.managedObjectContext).onDisappear {
          self.navigationButtonID = UUID()
        }
      }
      ZStack {
        List {
          Group {
            ForEach(store.viewModel.modules) { mod in
              SUIModule(module: mod, faveCallback: self.favorite(module:))
                .contentShape(Rectangle())
                .onTapGesture {
                  self.store.interactor?.playModule(request: Playlists.Play.Request(mmd: mod))
                }.onLongPressGesture {
                  self.store.router?.toPlaylistSelector(module: mod)
                }
                .listRowBackground(Color(Appearance.ampBgColor))
                .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
            }.onMove(perform: move)
              .onDelete(perform: deleteItems)
            if store.viewModel.modules.count == 0 {
              Spacer().listRowBackground(Color(Appearance.ampBgColor))
            }
          }
        }
        .padding(.init(top: 8, leading: 0, bottom: 0, trailing: 0))
        .listStyle(.plain)
        .modifier(ListBackgroundModifier())
        .navigationBarTitle(Text("TabBar_Playlist".l13n().uppercased()), displayMode: .inline)
        .navigationBarItems(leading: HStack {
          Button(action: {self.toggleShuffle()}, label: {Image(store.viewModel.shuffle ? "shuffled" : "sequential")})
          Button(action: {self.store.interactor?.startPlaylist()}, label: {Image("play-small")})
        },
          trailing: HStack {
          Button(action: {self.startImport()},
                 label: {Image(systemName: "square.and.arrow.down")
              .padding(EdgeInsets(top: -3, leading: 0, bottom: 0, trailing: 0))
              .font(Font.system(size: 20, weight: .light))
          })
          EditButton()}).id(self.navigationButtonID)
        if store.viewModel.modules.count == 0 {
          Text("PlaylistView_NoModules".l13n()).foregroundColor(.white).font(.system(size: 20)).padding(20)
        }
      }
      if store.nowPlaying {
        VStack {
          Text("").frame(height: 50)
        }
      }
    }.background(Color(Appearance.darkBlueColor))
  }
}

class PlaylistHostingViewController: UIHostingController<AnyView> {

  let store: PlaylistStore
  required init?(coder: NSCoder) {
    store = PlaylistStore()
    let contentView = PlaylistView(store: store).environment(\.managedObjectContext, moduleStorage.managedObjectContext)
    store.setup()
    super.init(coder: coder, rootView: AnyView(contentView))
  }

  override func viewDidLoad() {
    store.router?.viewController = self
    super.viewDidLoad()
    self.view.backgroundColor = Appearance.darkBlueColor
  }
}

#if DEBUG

func randomMMD() -> MMD {
  var mmd = MMD()
  mmd.composer = "foo"
  mmd.name = "bar"
  mmd.type = "MOD"
  return mmd
}

var st = PlaylistStore(viewModel: Playlists.Select.ViewModel(playlistName: "foo", shuffle: false, modules: [randomMMD(), randomMMD(), randomMMD(), randomMMD()])
)

struct PlaylistPreview: PreviewProvider {
  static var previews: some View {
    Group {
      NavigationView {
        PlaylistView(store: st)
      }.preferredColorScheme(.light)
      NavigationView {
        PlaylistView(store: st)
      }.preferredColorScheme(.dark)
    }
  }
}
#endif
