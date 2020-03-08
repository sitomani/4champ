//
//  PlaylistViewController.swift
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
            Image("favestar-yellow").padding(8)
        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}



struct PlaylistView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var show_modal: Bool = false

    var mods: [MMD] = [MMD()]
    var body: some View {
        VStack {
            Button(action: {
                self.show_modal = true
            }) {
                Text("Playlist Name")
            }.sheet(isPresented: self.$show_modal) {
                PlaylistSelector(show_modal: self.$show_modal).environment(\.managedObjectContext,self.managedObjectContext)
            }
            List {
                ForEach(mods) { mod in
                    SUIModule(module: mod)
                }
            }
        }
    }
    
    mutating func updateMods() {
        mods[0].name = "FOO"
    }
}

class PlaylistHostingViewController: UIHostingController<AnyView> {
    required init?(coder: NSCoder) {
        
        let contentView = PlaylistView().environment(\.managedObjectContext, moduleStorage.managedObjectContext)
        super.init(coder: coder, rootView:AnyView(contentView))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var lbi:[UIBarButtonItem] = [UIBarButtonItem.init(barButtonSystemItem: .organize, target: self, action: nil)]
        lbi.append(UIBarButtonItem.init(barButtonSystemItem: .rewind, target: self, action: nil))
        lbi.append(UIBarButtonItem.init(barButtonSystemItem: .play, target: self, action: nil))
        lbi.append(UIBarButtonItem.init(barButtonSystemItem: .fastForward, target: self, action: nil))
        lbi.append(UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: nil))
        lbi.append(UIBarButtonItem.init(barButtonSystemItem: .stop, target: self, action: nil))
        navigationItem.leftBarButtonItems = lbi
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
#endif
