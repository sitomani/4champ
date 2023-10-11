//
//  PlaylistPickerView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 14.3.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
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
    var shareAction: (() -> Void)
    var deleteAction: (() -> Void)
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
                    if store.viewModel.status == DownloadStatus.complete {
                        Button(action: {
                            self.deleteAction()
                        }, label: {
                            HStack {
                                Image("trashcan").renderingMode(.template).foregroundColor(.red)
                                Text("ModulesView_Delete")
                            }.frame(maxWidth: .infinity, minHeight: 50)
                        }).background(Color(Appearance.veryLightGray))
                            .cornerRadius(5)
                            .padding(EdgeInsets(top: 8, leading: 5, bottom: -12, trailing: 5))
                            .foregroundColor(.red)
                    }
                    if store.viewModel.service == .amp {
                    Button(action: {
                        self.shareAction()
                    }, label: {
                        HStack {
                            Image("shareicon").renderingMode(.template).foregroundColor(.blue)
                            Text("NP_Share")
                        }.frame(maxWidth: .infinity, minHeight: 50)
                    }).background(Color(Appearance.veryLightGray)).cornerRadius(5).padding(EdgeInsets(top: 8, leading: 5, bottom: 4, trailing: 5))
                    }
                }.background(Color.black.opacity(0.25))
                VStack {
                    VStack {
                        Text(self.store.viewModel.module).foregroundColor(Color(.black)).padding(.init(top: 16, leading: 0, bottom: 0, trailing: 0))
                        Text("PlaylistSelector_Title").foregroundColor(Color(.black))
                        Picker(selection: $store.viewModel.currentPlaylistIndex, label: Text("")) {
                            ForEach(0..<self.store.viewModel.playlistOptions.count, id: \.self) { index in
                                Text(self.store.viewModel.playlistOptions[index])
                                    .foregroundColor(Color(.black))
                            }
                        }.labelsHidden().background(Color(Appearance.veryLightGray))
                    }.frame(maxWidth: .infinity)
                        .background(Color(Appearance.veryLightGray)).cornerRadius(5)
                        .padding(EdgeInsets(top: 5, leading: 5, bottom: -5, trailing: 5))
                    HStack {
                        Button(action: addModuleToPlaylist, label: {
                            Text("PlaylistSelector_Add").frame(maxWidth: .infinity, minHeight: 50).background(Color(Appearance.veryLightGray))
                        }).cornerRadius(5).padding(EdgeInsets(top: 5, leading: 5, bottom: 8, trailing: 0))
                        Button(action: { self.dismissAction() }, label: {
                            Text("G_Cancel").frame(maxWidth: .infinity, minHeight: 50).background(Color(Appearance.veryLightGray))
                        }).cornerRadius(5).padding(EdgeInsets(top: 5, leading: 0, bottom: 8, trailing: 5))
                    }.background(Color.black.opacity(0.0))
                }.background(Color(.black).opacity(0.25))
            }

            if self.store.viewModel.status == .downloading(progress: 0) {
                withAnimation {
                    ZStack {
                        Text("Search_Downloading".l13n()).foregroundColor(Color(.black))
                    }.frame(maxWidth: .infinity, minHeight: 100).background(Color.white).cornerRadius(20).padding(20).shadow(radius: 5)
                }.transition(.opacity)
            }
        }
    }
}

#if DEBUG
struct PlaylistPickerView_Previews: PreviewProvider {
    static var store = PlaylistSelectorStore()
    static var previews: some View {
        PlaylistPickerView(dismissAction: {}, shareAction: {}, deleteAction: {}, store: store)
    }
}
#endif
