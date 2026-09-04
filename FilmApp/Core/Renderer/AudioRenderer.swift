//
//  AudioRenderer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-04.
//

internal import AVFoundation

enum AudioRenderError: Error {
    case noRenderer
}

class AudioRenderer{
    private let renderer = AVSampleBufferAudioRenderer()
    private let audioBuffer: AudioSampleBuffer

    var underlyingRenderer: AVSampleBufferAudioRenderer { renderer }

    init(audioBuffer: AudioSampleBuffer) {
        self.audioBuffer = audioBuffer
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
    
    func enqueue(_ sample: CMSampleBuffer) async {
        await audioBuffer.enqueue(sample)
    }
    
    func renderNextSample() async throws{
        if renderer.isReadyForMoreMediaData{
            let audioBuffer = await audioBuffer.dequeue()
            renderer.enqueue(audioBuffer)
        }
    }
    
}
