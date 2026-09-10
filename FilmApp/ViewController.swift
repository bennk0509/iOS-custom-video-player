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
    
    let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play Video", for: .normal)
        button.setTitle("Playing...", for: .selected)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let pauseResumeButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pause", for: .normal)
        button.setTitle("Resume", for: .selected)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        view.backgroundColor = .systemBackground
        
        guard let videoURL = Bundle.main.url(forResource: "highlight", withExtension: "mov") else {
            print("Couldnt find video. Please try again")
            return
        }
        
        // Setup video view
        let videoView = VideoViewFactory.create(videoURL: videoURL)
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup play button
        view.addSubview(playButton)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        view.addSubview(pauseResumeButton)
        pauseResumeButton.addTarget(self, action: #selector(pauseResumeButtonTapped), for: .touchUpInside)
        pauseResumeButton.isEnabled = false
        
        NSLayoutConstraint.activate([
            // Video view constraints
            videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            videoView.heightAnchor.constraint(equalToConstant: 300),
            
            // Play button constraints (left side, below video)
            playButton.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 32),
            playButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Pause/Resume button constraints (right side, below video)
            pauseResumeButton.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 32),
            pauseResumeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            pauseResumeButton.widthAnchor.constraint(equalToConstant: 150),
            pauseResumeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        self.videoView = videoView
    }
    
    @objc private func playButtonTapped() {
        guard let videoView = videoView else { return }
        
        playButton.isSelected = true
        playButton.isEnabled = false
        
        videoView.playBack()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.playButton.isEnabled = true
            self?.pauseResumeButton.isEnabled = true
        }
    }
    
    @objc private func pauseResumeButtonTapped() {
        guard let videoView = videoView else { return }
        
        if pauseResumeButton.isSelected {
            videoView.resume()
            pauseResumeButton.isSelected = false
        } else {
            videoView.pause()
            pauseResumeButton.isSelected = true
        }
    }
}

