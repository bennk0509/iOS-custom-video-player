//
//  VideoRenderer.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-04.
//

internal import AVFoundation

enum VideoRenderError: Error{
    case noRenderer
    case cantCreateFormatDescription
    case cantCreateSampleBuffer
}


@MainActor
class VideoRenderer {
    private weak var renderer: AVSampleBufferVideoRenderer?
    private let synchronizer: AVSampleBufferRenderSynchronizer
    private let frameBuffer: VideoFrameBuffer
    private var formatDescription: CMVideoFormatDescription?
    private var hasStartedPlayback = false

    init(frameBuffer: VideoFrameBuffer, synchronizer: AVSampleBufferRenderSynchronizer) {
            self.frameBuffer = frameBuffer
            self.synchronizer = synchronizer
        }
    func setRenderer(_ renderer: AVSampleBufferVideoRenderer) {
        self.renderer = renderer
    }
    
    func renderNextFrame() async throws {
        guard let renderer = self.renderer else {
            throw VideoRenderError.noRenderer
        }
        let frame = await frameBuffer.dequeue()
        let sampleBuffer = try makeSampleBuffer(from: frame)
        if !hasStartedPlayback {
            self.synchronizer.setRate(1.0, time: frame.pts)
            hasStartedPlayback = true
        }
        renderer.enqueue(sampleBuffer)
    }
    
    private func makeSampleBuffer(from decodedVideoBuffer: DecodedVideoFrame) throws -> CMSampleBuffer{
        let formatDescription: CMVideoFormatDescription

        if let cached = self.formatDescription{
            formatDescription = cached
        } else{
            var tempFormatDescription: CMVideoFormatDescription?
            let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: decodedVideoBuffer.pixelBuffer,
                formatDescriptionOut: &tempFormatDescription
            )
            
            guard formatStatus == noErr, let unwrappedFormat = tempFormatDescription else {
                throw VideoRenderError.cantCreateFormatDescription
            }
            
            self.formatDescription = unwrappedFormat
            formatDescription = unwrappedFormat
        }
        var timing = CMSampleTimingInfo(
            duration: decodedVideoBuffer.duration,
            presentationTimeStamp: decodedVideoBuffer.pts,
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer? = nil
        let bufferStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: decodedVideoBuffer.pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard bufferStatus == noErr, let sampleBuffer else {
            throw VideoRenderError.cantCreateSampleBuffer
        }
        return sampleBuffer
    }
    
}
