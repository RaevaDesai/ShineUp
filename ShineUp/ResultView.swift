//
//  ResultView.swift
//  ShineUp
//
//  Created by Swarasai Mulagari on 9/7/24.
//

import SwiftUI

struct ResultView: View {
    var resultText: String
    var capturedImage: UIImage
    var onBack: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.784, green: 0.894, blue: 0.937) // Lighter sky blue


                .edgesIgnoringSafeArea(.all) // Ensure it covers the entire screen
            
            VStack {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)

                Text(resultText)
                    .font(.title)
                    .padding()
                
                Button(action: {
                    onBack()
                }) {
                    Text("Back to Home")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
}
