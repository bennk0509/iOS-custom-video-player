//
//  VideoReader.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-04.
//

internal import AVFoundation

protocol AssetReader{
    func sampleBuffers() -> AsyncThrowingStream<CMSampleBuffer,Error>
    func audioSampleBuffers() -> AsyncThrowingStream<CMSampleBuffer,Error>
    func getAsset() -> AVAsset
}



class AssetReaderImpl: AssetReader{
    private let videoURL: URL
    private let asset: AVAsset
    
    init(videoURL: URL)
    {
        self.videoURL = videoURL
        asset = AVURLAsset(url: videoURL)
    }
    
    func getAsset() -> AVAsset{
        return asset
    }
    
    func sampleBuffers() -> AsyncThrowingStream<CMSampleBuffer,Error> {
        return AsyncThrowingStream<CMSampleBuffer,Error>{continuation in
            Task{
                do{
                    //load tracks from asset -> return tracks (type video)
                    let tracks = try await asset.loadTracks(withMediaType: .video)
                    //get video track from tracks
                    guard let videoTrack = tracks.first else{
                        throw ReaderError.cantFindVideoTrack
                    }
                    
                    let assetReader = try AVAssetReader(asset: asset)
                    let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                    
                    guard assetReader.canAdd(trackOutput) else{
                        throw ReaderError.cantAddOutputToReader
                    }
                    assetReader.add(trackOutput)
                    
                    guard assetReader.startReading() else{
                        throw ReaderError.startReadingFailed(underlyingError: assetReader.error)
                    }
                    
                    while assetReader.status == .reading {
                        // task is cancelled  -> cancelled reading
                        if Task.isCancelled {
                            assetReader.cancelReading()
                            return
                        }
                        //while reader -> get every sample buffer and return back
                        //skip marker buffers (numSamples == 0, no format description)
                        if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                           CMSampleBufferGetNumSamples(sampleBuffer) > 0 {
                            continuation.yield(sampleBuffer)
                        }
                    }
                    
                    if assetReader.status == .completed{
                        continuation.finish()
                    } else if assetReader.status == .failed, let error = assetReader.error {
                        throw error
                    } else{
                        continuation.finish()
                    }
                    
                } catch {
                    if let readerError = error as? ReaderError {
                        continuation.finish(throwing: readerError)
                        return
                    }
                    else{
                        continuation.finish(throwing: ReaderError.startReadingFailed(underlyingError: error))
                    }
                    
                }
                

            }
        }
    }

    func audioSampleBuffers() -> AsyncThrowingStream<CMSampleBuffer,Error> {
        return AsyncThrowingStream<CMSampleBuffer,Error>{continuation in
            Task{
                do{
                    let tracks = try await asset.loadTracks(withMediaType: .audio)
                    //no audio track -> finish silently, video plays without sound
                    guard let audioTrack = tracks.first else{
                        continuation.finish()
                        return
                    }

                    let assetReader = try AVAssetReader(asset: asset)
                    //decompress to LPCM so the audio renderer can play it directly
                    let outputSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
                    let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)

                    guard assetReader.canAdd(trackOutput) else{
                        throw ReaderError.cantAddOutputToReader
                    }
                    assetReader.add(trackOutput)

                    guard assetReader.startReading() else{
                        throw ReaderError.startReadingFailed(underlyingError: assetReader.error)
                    }

                    while assetReader.status == .reading {
                        if Task.isCancelled {
                            assetReader.cancelReading()
                            return
                        }
                        if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                           CMSampleBufferGetNumSamples(sampleBuffer) > 0 {
                            continuation.yield(sampleBuffer)
                        }
                    }

                    if assetReader.status == .failed, let error = assetReader.error {
                        throw error
                    }
                    continuation.finish()

                } catch {
                    if let readerError = error as? ReaderError {
                        continuation.finish(throwing: readerError)
                    }
                    else{
                        continuation.finish(throwing: ReaderError.startReadingFailed(underlyingError: error))
                    }
                }
            }
        }
    }
}


