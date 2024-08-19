//
//  Toast.swift
//  4champ
//
//  Copyright © 2024 Aleksi Sitomaniemi. All rights reserved.
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

struct ToastPreviewWrapper: View {
    @State private var toggle = false
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        Toast(text: "Channel 'something' started with 130 modules")
            .id(toggle)  // Changes the identity of the view to trigger onAppear
            .onReceive(timer) { _ in
                self.toggle.toggle()  // Toggling the state to reset the view
            }
    }
}

struct Toast_Previews: PreviewProvider {
    static var previews: some View {
        ToastPreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}