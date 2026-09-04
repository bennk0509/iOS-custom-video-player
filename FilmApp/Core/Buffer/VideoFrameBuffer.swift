//
//  VideoFrameBuffer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-01.
//

actor VideoFrameBuffer{
    private var frames: [DecodedVideoFrame] = []
    private let maxSize: Int
    private var decodeContinuation: CheckedContinuation<Void, Never>?
     
    private var renderContinuation: CheckedContinuation<Void, Never>?
    
    private let yellowThreshold: Int
    private var isDecoderAllowedToRun = false

    //create buffer with size 30 (by default)
    init(maxSize: Int = 600, yellowThreshold: Int = 400) {
        self.maxSize = maxSize
        self.yellowThreshold = yellowThreshold
    }
    
    //full -> wait for render to resume
    func enqueueCustom(_ frame: DecodedVideoFrame) async {
        while frames.count >= maxSize {
            await withCheckedContinuation { continuation in
                renderContinuation = continuation
            }
        }
        frames.append(frame)
        if frames.count >= yellowThreshold{
            isDecoderAllowedToRun = true
            decodeContinuation?.resume()
            decodeContinuation = nil
        }
        
    }
    
    func dequeueCustom() async -> DecodedVideoFrame? {
        while frames.isEmpty || !isDecoderAllowedToRun {
            if frames.isEmpty {
                isDecoderAllowedToRun = false
            }
            await withCheckedContinuation{ continuation in
                decodeContinuation = continuation
            }
        }
        
        let frame = frames.removeFirst()
        
        renderContinuation?.resume()
        renderContinuation = nil
        return frame
    }
}
