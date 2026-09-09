
internal import UIKit
internal import AVFoundation

class VideoViewModel{

    private let assetReader: AssetReader
    private let videoDecode: VideoDecode
    private let renderSynchronizer: AVSampleBufferRenderSynchronizer

    private let videoFrameBuffer: VideoFrameBuffer
    private let audioSampleBuffer: AudioSampleBuffer

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
    func playBack() {
        guard sampleBufferVideoRenderer != nil else { return }

        renderSynchronizer.addRenderer(audioRenderer.underlyingRenderer)
        renderSynchronizer.addRenderer(sampleBufferVideoRenderer!)

        Task { await decodeAudioIntoBuffer() }
        Task { await decodeVideoIntoBuffer() }
        Task { await renderVideoLoop() }
        Task { await renderAudioLoop() }
    }

    private func renderVideoLoop() async {
        while true {
            do {
                print("VIDEO RENDER")
                try await videoRenderer.renderNextFrame()
            } catch {
                print("[VIDEO RENDER]:", error)
                break
            }
        }
    }

    private func renderAudioLoop() async {
        while true {
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
                let decodedFrame = try await videoDecode.decode(sample: sampleBuffer)
                guard let decodedFrame else { continue }
                await videoFrameBuffer.enqueue(decodedFrame)
            }
        } catch {
            print("[DECODE]:", error)
        }
    }
    
}


