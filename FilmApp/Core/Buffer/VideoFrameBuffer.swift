//
//  VideoFrameBuffer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-01.
//

actor VideoFrameBuffer{
    private let core: CustomBufferQueue<DecodedVideoFrame>
    init(maxSize: Int = 600, yellowThreshold: Int = 30) {
        core = CustomBufferQueue(yellowThreshold: yellowThreshold, maxSize: maxSize)
    }
    
    func enqueue(_ buffer: DecodedVideoFrame) async { await core.enqueue(buffer) }
    func dequeue() async -> DecodedVideoFrame { await core.dequeue() }
}
