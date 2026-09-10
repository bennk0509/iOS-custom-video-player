
internal import UIKit
internal import AVFoundation

@MainActor
class VideoViewModel{

    private let assetReader: AssetReader
    private let videoDecode: VideoDecode
    private let renderSynchronizer: AVSampleBufferRenderSynchronizer

    private let videoFrameBuffer: VideoFrameBuffer
    private let audioSampleBuffer: AudioSampleBuffer

    private var decodeTasks: [Task<Void,Never>] = []
    private var encodeTasks: [Task<Void,Never>] = []
    private var isPlaying: Bool = false
    private var isFirstTime: Bool = true
    private let videoRenderer: VideoRenderer
    private let audioRenderer: AudioRenderer
    weak var sampleBufferVideoRenderer: AVSampleBufferVideoRenderer? {
        didSet {
            guard let sampleBufferVideoRenderer else { return }
            videoRenderer.setRenderer(sampleBufferVideoRenderer)
        }
    }
    init(assetReader: AssetReader) {
        self.assetReader = assetReader
        self.videoDecode = VTVideoDecodeImpl()
        self.videoFrameBuffer = VideoFrameBuffer()
        self.audioSampleBuffer = AudioSampleBuffer()
        
        self.renderSynchronizer = AVSampleBufferRenderSynchronizer()
        
        self.videoRenderer = VideoRenderer(frameBuffer: videoFrameBuffer, synchronizer: self.renderSynchronizer)
        
        self.audioRenderer = AudioRenderer(audioBuffer: audioSampleBuffer)
    }
    func playBack() async{
        guard sampleBufferVideoRenderer != nil else { return }
        if isFirstTime {
            renderSynchronizer.addRenderer(audioRenderer.underlyingRenderer)
            renderSynchronizer.addRenderer(sampleBufferVideoRenderer!)
            isFirstTime = false
        }
        if isPlaying {
            await stop()
        }
        
        isPlaying = true
        decodeTasks.append(Task { await decodeVideoIntoBuffer() })
        decodeTasks.append(Task { await decodeAudioIntoBuffer() })
        encodeTasks.append(Task { await renderVideoLoop()})
        encodeTasks.append(Task { await renderAudioLoop()})
    }
    
    func pause() {
        renderSynchronizer.setRate(0.0, time: renderSynchronizer.currentTime())
    }
    func resume() {
        renderSynchronizer.setRate(1.0, time: renderSynchronizer.currentTime())
    }

    func stop() async{
        for task in decodeTasks{
            if !task.isCancelled {
                task.cancel()
            }
        }
        for task in encodeTasks{
            if !task.isCancelled {
                task.cancel()
            }
        }
        for task in decodeTasks { await task.value }
        for task in encodeTasks { await task.value }
        decodeTasks.removeAll()
        encodeTasks.removeAll()
        await self.videoDecode.reset()
        await videoRenderer.flush()
        await audioRenderer.flush()
        self.assetReader.reset()
        renderSynchronizer.setRate(0.0, time: .zero)
        isPlaying = false
    }

    private func renderVideoLoop() async {
        while !Task.isCancelled {
            do {
                try await videoRenderer.renderNextFrame()
            } catch {
                print("[VIDEO RENDER]:", error)
                break
            }
        }
    }

    private func renderAudioLoop() async {
        while !Task.isCancelled {
            do {
                try await audioRenderer.renderNextSample()
            } catch {
                print("[AUDIO RENDER]:", error)
                break
            }
        }
    }

    private func decodeAudioIntoBuffer() async {
        do {
            let audioBuffersStream = assetReader.audioSampleBuffers()
            for try await sample in audioBuffersStream {
                if Task.isCancelled {break}
                await audioRenderer.enqueue(sample)
            }
        } catch {
            print("[Audio] ERROR: \(error)")
        }
    }

    private func decodeVideoIntoBuffer() async {
        do {
            let buffersStream = assetReader.sampleBuffers()
            for try await sampleBuffer in buffersStream {
                if Task.isCancelled {break}
                let decodedFrame = try await videoDecode.decode(sample: sampleBuffer)
                guard let decodedFrame else { continue }
                await videoFrameBuffer.enqueue(decodedFrame)
            }
        } catch {
            print("[DECODE]:", error)
        }
    }
    
}


