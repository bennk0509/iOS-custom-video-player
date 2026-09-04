//
//  VideoView.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-20.
//
internal import UIKit
internal import AVFoundation

enum VideoViewFactory{
    static func create(videoURL: URL) -> VideoView{
        let assetReader = AssetReaderImpl(videoURL: videoURL)
        let videoViewModel = VideoViewModel(assetReader: assetReader)
        return VideoView(videoViewModel: videoViewModel)
    }
}

class VideoView: UIView{
    override class var layerClass: AnyClass{
        return AVSampleBufferDisplayLayer.self
    }
    
    private var videoViewModel: VideoViewModel
    
    var displayLayer: AVSampleBufferDisplayLayer {
        return self.layer as! AVSampleBufferDisplayLayer
    }
    
    init(videoViewModel: VideoViewModel){
        self.videoViewModel = videoViewModel
        super.init(frame: .zero)
        setupLayer()
        self.videoViewModel.sampleBufferVideoRenderer = displayLayer.sampleBufferRenderer
    }

        
    @available(*, unavailable, message: "VideoView must be created via VideoViewFactory.create(videoURL:)")
        override init(frame: CGRect) {
            fatalError("VideoView must be created via VideoViewFactory.create(videoURL:)")
        }

    @available(*, unavailable, message: "VideoView must be created via VideoViewFactory.create(videoURL:)")
    required init?(coder: NSCoder) {
        fatalError("VideoView must be created via VideoViewFactory.create(videoURL:)")
    }
    
    private func setupLayer() {
        displayLayer.videoGravity = .resizeAspectFill
    }
    
    func playBack() {
        videoViewModel.playBack()
    }
        
}
