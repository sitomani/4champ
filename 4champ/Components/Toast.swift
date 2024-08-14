//
//  Toast.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 12.8.2024.
//  Copyright © 2024 boogie. All rights reserved.
//

import SwiftUI

struct Toast: View {
    var text: String = "no text given, this is not quite right"
    @State private var offsetY: CGFloat = -200
    let gradientColorTop: Color = .init(UIColor(rgb: 0x154d81))
    let gradientColorBottom: Color = .init(UIColor(rgb: 0x14416c))
    var body: some View {
        VStack {
            HStack {
                Text(text)
                    .padding(.horizontal, 32.0)
                    .padding(.vertical, 15.0)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient:
                            Gradient(colors: [gradientColorTop, gradientColorBottom]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .cornerRadius(8.0)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                        .stroke(.white, lineWidth: 1.0)
                    )
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 12)
            .offset(y: offsetY)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.offsetY = 60
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation(.easeIn(duration: 0.3)) {
                            self.offsetY = -200
                        }}
                    }.shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        } .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
    }

}

#Preview {
    Toast()
}
