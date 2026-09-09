//
//  AudioBuffer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-02.
//

import CoreMedia

actor AudioSampleBuffer{
    private let core: CustomBufferQueue<CMSampleBuffer>
    init(maxSize: Int = 600, yellowThreshold: Int = 30) {
        core = CustomBufferQueue(yellowThreshold: yellowThreshold, maxSize: maxSize)
    }
    
    func enqueue(_ buffer: CMSampleBuffer) async { await core.enqueue(buffer) }
    func dequeue() async -> CMSampleBuffer { await core.dequeue() }
}
