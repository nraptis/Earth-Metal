//
//  ContentView.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/9/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                EarthSceneView(width: round(geometry.size.width),
                              height: round(geometry.size.height))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
