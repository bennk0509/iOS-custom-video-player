//
//  AudioManager.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-31.
//

internal import AVFoundation

enum AudioError: Error{
    case cantRenderAudio
}

class AudioManager{
    private var audioRenderer: AVSampleBufferAudioRenderer
    private var isRendererAttached = false
    
    init(audioRenderer: AVSampleBufferAudioRenderer) {
        self.audioRenderer = audioRenderer
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
            print("[AudioManager] Audio session configured")
        } catch {
            print("[AudioManager] Failed to setup audio session: \(error)")
        }
    }
    
    func enqueue(sampleBuffer: CMSampleBuffer) async throws {
        while !audioRenderer.isReadyForMoreMediaData {
            if audioRenderer.status == .failed{
                throw AudioError.cantRenderAudio
            }            
            try await Task.sleep(for: .milliseconds(5))
        }
        await MainActor.run {
            audioRenderer.enqueue(sampleBuffer)
        }
    }

    
    func addRenderer(synchronize: AVSampleBufferRenderSynchronizer) {
        guard !isRendererAttached else { return }
        synchronize.addRenderer(audioRenderer)
        isRendererAttached = true
    }
    
}
