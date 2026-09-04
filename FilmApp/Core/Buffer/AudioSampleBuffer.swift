//
//  AudioBuffer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-02.
//

import CoreMedia


actor AudioSampleBuffer{
    private var audioQueue: [CMSampleBuffer] = []
  
    private var decodeContinuation: CheckedContinuation<Void, Never>?
    private var renderContinuation: CheckedContinuation<Void, Never>?
    
    private let yellowThreshold: Int
    private let maxSize: Int
    
    private var isDecoderAllowedToRun = false
    init(maxSize: Int = 600, yellowThreshold: Int = 400){
        self.maxSize = maxSize
        self.yellowThreshold = yellowThreshold
    }
    
    func enqueue(_ buffer: CMSampleBuffer) async{
        while audioQueue.count >= maxSize {
            await withCheckedContinuation{continuation in
                renderContinuation = continuation
            }
        }
        audioQueue.append(buffer)
        if audioQueue.count >= yellowThreshold {
            isDecoderAllowedToRun = true
            decodeContinuation?.resume()
            decodeContinuation = nil
        }
    }
    
    func dequeue() async -> CMSampleBuffer? {
        while audioQueue.isEmpty || !isDecoderAllowedToRun {
            if audioQueue.isEmpty {
                isDecoderAllowedToRun = false
            }
            await withCheckedContinuation{ continuation in
                decodeContinuation = continuation
            }
        }
        
        let buffer = audioQueue.removeFirst()
        
        renderContinuation?.resume()
        renderContinuation = nil
        return buffer
    }
}
