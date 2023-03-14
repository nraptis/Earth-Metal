//
//  MetalViewControllerRepresentable.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/10/23.
//

import SwiftUI

struct EarthSceneView: UIViewControllerRepresentable {
    
    let width: CGFloat
    let height: CGFloat
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<EarthSceneView>) -> MetalViewController {
        
        let width = Float(Int(width + 0.5))
        let height = Float(Int(height + 0.5))
        
        let scene = EarthScene()
        let graphics = Graphics(delegate: scene,
                                width: width,
                                height: height)
        
        let metalViewController = graphics.metalViewController
        metalViewController.loadViewIfNeeded()
        metalViewController.load()
        
        let gestureView = GestureView(frame: .zero)
        metalViewController.view.addSubview(gestureView)
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: metalViewController.view.topAnchor),
            gestureView.bottomAnchor.constraint(equalTo: metalViewController.view.bottomAnchor),
            gestureView.leftAnchor.constraint(equalTo: metalViewController.view.leftAnchor),
            gestureView.rightAnchor.constraint(equalTo: metalViewController.view.rightAnchor),
        ])
        gestureView.load(graphics: graphics)
        gestureView.delegate = scene.gestureProcessor
        scene.gestureView = gestureView
        
        return metalViewController
    }
    
    func updateUIViewController(_ uiViewController: MetalViewController,
                                context: UIViewControllerRepresentableContext<EarthSceneView>) {
        let width = Float(Int(width + 0.5))
        let height = Float(Int(height + 0.5))
        uiViewController.graphics.update(width: width,
                                         height: height)
    }
}
