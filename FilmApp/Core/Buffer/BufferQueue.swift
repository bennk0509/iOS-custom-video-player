//
//  BufferQueue.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-03.
//

enum BufferQueueFactory{
    static func createBuffer(
        type:BufferType,
        maxSize: Int = 600,
        yellowThreshold: Int = 400) -> Buffer{
        switch type {
        case .audio:
            return .audio(AudioSampleBuffer(maxSize: maxSize, yellowThreshold: yellowThreshold))
        case .video:
            return .video(VideoFrameBuffer(maxSize: maxSize, yellowThreshold: yellowThreshold))
        }
    }
}

enum BufferType {
    case audio
    case video
}

//buffer queue
enum Buffer{
    //audio Buffer
    case audio(AudioSampleBuffer)
    case video(VideoFrameBuffer)
    //video Buffer
}
