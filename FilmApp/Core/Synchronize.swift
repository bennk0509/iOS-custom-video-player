//
//  Synchronize.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-02.
//

internal import AVFoundation

class Synchronize {
    private let synchronize: AVSampleBufferRenderSynchronizer = AVSampleBufferRenderSynchronizer()
    private let videoFrameBuffer: VideoFrameBuffer
    private let audioFrameBuffer: AudioBuffer
    
    init(videoFrameBuffer: VideoFrameBuffer, audioFrameBuffer: AudioBuffer) {
        self.videoFrameBuffer = videoFrameBuffer
        self.audioFrameBuffer = audioFrameBuffer
    }
    
    
    
}
