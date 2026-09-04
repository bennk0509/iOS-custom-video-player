
internal import UIKit
internal import AVFoundation

class VideoViewModel{

    private let assetReader: AssetReader
    private let videoDecode: VideoDecode
    private let renderSynchronizer: AVSampleBufferRenderSynchronizer
    private let videoFrameBuffer: VideoFrameBuffer
    private let audioSampleBuffer: AudioSampleBuffer
    weak var sampleBufferVideoRenderer: AVSampleBufferVideoRenderer?
    private let sampleBufferAudioRenderer: AVSampleBufferAudioRenderer
    private var formatDescription: CMVideoFormatDescription?
    //reader - reuse
    // decode - no reuse: create inside viewmodel
    //buffer - no reuse
    //
    init(assetReader: AssetReader) {
        self.assetReader = assetReader
        self.videoDecode = VTVideoDecodeImpl()
//        self.videoFrameBuffer = BufferQueueFactory.createBuffer(type: .video)
//        self.audioSampleBuffer = BufferQueueFactory.createBuffer(type: .audio)
        self.videoFrameBuffer = VideoFrameBuffer()
        self.audioSampleBuffer = AudioSampleBuffer()
        self.sampleBufferAudioRenderer = AVSampleBufferAudioRenderer()
        self.renderSynchronizer = AVSampleBufferRenderSynchronizer()
        
    }
    //run 3 tasks
    //task 1 decode (private)
    //task 2 video enqueue (private)
    //task 3 audio enqueue (private)
    func playBack(){
        guard let sampleBufferVideoRenderer = self.sampleBufferVideoRenderer else {
            return
        }
        renderSynchronizer.addRenderer(self.sampleBufferAudioRenderer)
        renderSynchronizer.addRenderer(sampleBufferVideoRendererfo)
        Task { await enqueueAudioBuffer() }
        Task{
            await decodeVideoIntoBuffer()
        }
        Task{
            await renderVideoFromBuffer()
        }
        
        Task{
            await renderAudioFromBuffer()
        }
    }
    
    func renderVideoFromBuffer() async{
        do{
            var isPlaybackStarted = false
            while true {
                guard let videoRenderer = self.sampleBufferVideoRenderer else {
                    return
                }
                if videoRenderer.isReadyForMoreMediaData {
                    guard let frame = await videoFrameBuffer.dequeueCustom() else {
                        continue
                    }
                    try await enqueue(from: frame)
                    if !isPlaybackStarted{
                        renderSynchronizer.setRate(1.0, time: frame.pts)
                        isPlaybackStarted = true
                    }
                }
            }
        } catch {
            print("[RENDERER]: ", error)
        }
    }
    
    func renderAudioFromBuffer() async{
        while true {
            if sampleBufferAudioRenderer.isReadyForMoreMediaData {
                guard let audioBuffer = await audioSampleBuffer.dequeue() else {
                    continue
                }
                self.sampleBufferAudioRenderer.enqueue(audioBuffer)
            }
        }
    }
    

    func enqueue(from decodedVideoBuffer: DecodedVideoFrame?) async throws{
        guard let sampleBufferVideoRender = self.sampleBufferVideoRenderer else{
            return
        }
        guard let decodedVideoBuffer = decodedVideoBuffer else {
            return
        }
        guard let sampleBuffer = try makeSampleBuffer(from: decodedVideoBuffer) else{
            return
        }
        await MainActor.run {
            sampleBufferVideoRender.enqueue(sampleBuffer)
        }
    }
    
    private func enqueueAudioBuffer() async{
        do {
            let audioBuffersStream = assetReader.audioSampleBuffers()
            for try await audioSampleBuffer in audioBuffersStream {
                await self.audioSampleBuffer.enqueue(audioSampleBuffer)
            }
        } catch {
            print("[Audio] ERROR: \(error)")
        }
    }

    private func decodeVideoIntoBuffer() async{
        do{
            let buffersStream = assetReader.sampleBuffers()
            for try await sampleBuffer in buffersStream {
                let decodedFrame = try await videoDecode.decode(sample: sampleBuffer)
                guard let decodedFrame = decodedFrame else {continue}
                await videoFrameBuffer.enqueueCustom(decodedFrame)
            }
        } catch {
            print("[DECODE]:", error)
        }
    }
    
    private func makeSampleBuffer(from decodedVideoBuffer: DecodedVideoFrame?) throws -> CMSampleBuffer?{
        guard let decodedVideoBuffer = decodedVideoBuffer else{
            throw VideoManagerError.cantCreateSampleBuffer
        }
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
                throw VideoManagerError.cantCreateFormatDescription
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
        guard bufferStatus == noErr else {
            throw VideoManagerError.cantCreateSampleBuffer
        }
        return sampleBuffer
    }
    
    
}


