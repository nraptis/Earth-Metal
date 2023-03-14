//
//  CameraTestMenuView.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//

import SwiftUI

struct CameraTestMenuView: View {
    
    @State var rotationPrimary: Float = 180.0
    @State var rotationSecondary: Float = 90.0
    @State var zoom: Float = 4.0
    
    
    var body: some View {
        VStack {
            HStack {
                slidersView()
                buttonView()
            }
        }
        .onChange(of: rotationPrimary) { _ in
            broadcast()
        }
        .onChange(of: rotationSecondary) { _ in
            broadcast()
        }
        .onChange(of: zoom) { _ in
            broadcast()
        }
    }
    
    func broadcast() {
        let info = ["rp": rotationPrimary,
                    "rs": rotationSecondary,
                    "zo": zoom]
        NotificationCenter.default.post(name: NSNotification.Name("camera.twiddle"), object: info)
    }
    
    func buttonView() -> some View {
        Button {
            rotationPrimary = 180.0
            rotationSecondary = 90.0
        } label: {
            Text("Reset")
                .frame(width: 60.0)
                .font(.system(size: 16.0).bold())
        }
        .buttonStyle(.borderedProminent)
        .padding(.trailing, 16.0)
    }
    
    func slidersView() -> some View {
        VStack {
            HStack {
                Text("Rot 1:")
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
                Slider(value: $rotationPrimary, in: 0.0...360.0)
                Text(String(format: "%.1f", rotationPrimary))
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
            }
            
            HStack {
                Text("Rot 2:")
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
                Slider(value: $rotationSecondary, in: 10.0...170.0)
                Text(String(format: "%.1f", rotationSecondary))
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
            }
            
            HStack {
                Text("Zoom:")
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
                Slider(value: $zoom, in: ZoomTable.minZoomHard...ZoomTable.maxZoomHard)
                Text(String(format: "%.1f", zoom))
                    .frame(width: 60.0)
                    .font(.system(size: 16.0).bold())
            }
        }
        .padding(.horizontal, 16.0)
    }
}

struct CameraTestMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CameraTestMenuView()
    }
}
