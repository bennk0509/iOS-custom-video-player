//
//  ViewController.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-04.
//
internal import UIKit
internal import AVFoundation
class ViewController: UIViewController {
    
    private var videoView: VideoView?

    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }()
    private let ciContext = CIContext(options: nil)
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let videoURL = Bundle.main.url(forResource: "highlight", withExtension: "mov") else {
            print("Couldnt find video. Please try again")
            return
        }
        let videoView = VideoViewFactory.create(videoURL: videoURL)
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            videoView.heightAnchor.constraint(equalToConstant: 300)
        ])
        self.videoView = videoView
        
        videoView.playBack()

    }
}

