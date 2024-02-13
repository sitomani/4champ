//
//  DownloadView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13.4.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var value: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(.lightGray))

                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.systemBlue))
                    .animation(value > 0.01 ? .linear : nil, value: value)
            }.cornerRadius(2)
        }
    }
}

struct DownloadView: View {
    var dismissAction: (() -> Void)?
    var playAction: (() -> Void)?
    @ObservedObject var store: DownloadController
    @State var progressValue: Float = 0.0
    var body: some View {
        ZStack {
            VStack {
                Text(store.model.status)
                    .padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 0))
                    .foregroundColor(.black)

                ProgressBar(value: $store.model.progress)
                    .frame(height: 4)
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))

                Text(store.model.summary)
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 0, trailing: 15))
                    .foregroundColor(.black)

                HStack {
                    if store.model.error == nil &&
                        (store.model.importType == .universalLink ||
                         (store.model.importType == .documentLink && store.model.importIds.count > 0)) {
                        Button(action: {
                            self.store.play()
                        }, label: {
                            Text("DownloadView_Play")
                        }).frame(maxWidth: .infinity, minHeight: 50).padding(5).contentShape(Rectangle())
                            .disabled(self.store.model.progress < 1.0)
                    }
                    if store.model.error == nil && store.model.importType == .universalLink {
                        Button(action: {
                            self.store.keep()
                        }, label: {
                            Text("Dialog_Keep") // Image("preview-save")
                        }).frame(maxWidth: .infinity, minHeight: 50).padding(5).contentShape(Rectangle())
                    }
                    if store.model.error == nil && store.model.importType == .documentLink && store.model.importIds.count > 0 {
                        Button(action: {
                            self.store.assignComposer()
                        }, label: {
                            Text("Local_Import_Assign")
                        }).frame(maxWidth: .infinity, minHeight: 50).padding(5).contentShape(Rectangle())
                    }
                    Button(action: {
                        self.store.dismiss()
                    }, label: {
                        Text("DownloadView_Dismiss")
                    }).frame(maxWidth: .infinity, minHeight: 50).padding(5).contentShape(Rectangle())
                }.padding(5)
            }.background(Color(Appearance.veryLightGray)).cornerRadius(10.0)
        }.padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)).onDisappear(perform: {
            self.store.swipeDismissed()
        })
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var dummyC = DownloadController()
    static var previews: some View {
        DownloadView(store: dummyC)
    }
}
