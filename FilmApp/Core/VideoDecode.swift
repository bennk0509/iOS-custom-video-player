//
//  VideoDecode.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-10.
//

import VideoToolbox

protocol VideoDecode{
    func decode(sample: CMSampleBuffer) async throws -> DecodedVideoFrame?
}

actor VTVideoDecodeImpl: VideoDecode{
    private var session: VTDecompressionSession?
    private var currentFormatDescription: CMFormatDescription?
    init(){}
    
    func decode(sample: CMSampleBuffer) async throws -> DecodedVideoFrame? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sample) else {
            throw VideoDecodeError.cantFindFormatDescription
        }
        
        if session == nil || !VTDecompressionSessionCanAcceptFormatDescription(session!, formatDescription: formatDescription) {
            try setUpSession(with: formatDescription)
        }
        
        guard let session = session else {
            throw VideoDecodeError.sessionNotReady
        }
        return try await withCheckedThrowingContinuation { continuation in
            let status = VTDecompressionSessionDecodeFrame(
                session,
                sampleBuffer: sample,
                flags: [._EnableAsynchronousDecompression],
                infoFlagsOut: nil
            ) { status, _, imageBuffer, pts, duration in
                if status != noErr {
                    continuation.resume(throwing: VideoDecodeError.decodeFrameFailed(status))
                    return
                }
                
                guard let pixelBuffer = imageBuffer else {
                    continuation.resume(throwing: VideoDecodeError.missingPixelBuffer)
                    return
                }

                if let ambientViewingEnvironment = CMFormatDescriptionGetExtension(
                    formatDescription,
                    extensionKey: kCMFormatDescriptionExtension_AmbientViewingEnvironment
                ) {
                    CVBufferSetAttachment(
                        pixelBuffer,
                        kCVImageBufferAmbientViewingEnvironmentKey,
                        ambientViewingEnvironment,
                        .shouldPropagate
                    )
                }
                continuation.resume(returning: DecodedVideoFrame(pixelBuffer: pixelBuffer, pts: pts, duration: duration))
            }
            if status != noErr {
                continuation.resume(throwing: VideoDecodeError.decodeFrameFailed(status))
            }
        }
    }
    

    private func setUpSession(with formatDescription: CMVideoFormatDescription) throws{
        self.currentFormatDescription = formatDescription
        
        if let oldSession = session{
            VTDecompressionSessionInvalidate(oldSession)
        }
        
        var pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        if let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [CFString: Any] {
            if let bitsPerComponent = extensions[kCMFormatDescriptionExtension_BitsPerComponent] as? Int, bitsPerComponent == 10 {
                pixelFormat = kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            }
        }
        
        let imageBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [CFString: Any]
        ]

        let status = VTDecompressionSessionCreate(allocator: nil, formatDescription: formatDescription, decoderSpecification: nil, imageBufferAttributes: imageBufferAttributes as CFDictionary, decompressionSessionOut: &session)

        if status != noErr{
            print("[DECODE] Failed to create a session: \(status)")
            throw VideoDecodeError.cantCreateDecode
        }

        if let session {
            VTSessionSetProperty(
                session,
                key: kVTDecompressionPropertyKey_PropagatePerFrameHDRDisplayMetadata,
                value: kCFBooleanTrue
            )
        }
    }
    
//    private func prepareToEncodeFrames(){
//        let encoderSpecifications = [
//            kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: true as CFBoolean
//        ] as CFDictionary
//        
//        
//        let status = VTCompressionSessionCreate(allocator: kCFAllocatorDefault, width: self.width, height: self.height, codecType: kCMVideoCodecType_H264, encoderSpecification: encoderSpecification, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: outputCallback, refcon: Unmanaged.passUnretained(self).toOpaque(), compressionSessionOut: &session)
//            print("H264Coder init \(status == noErr) \(status)")
//            // This demonstrates setting a property after the session has been created
//            guard let compressionSession = session else { return }
//            VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
//            VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
//            VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
//            VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: CFNumberCreate(kCFAllocatorDefault, CFNumberType.intType, &self.fps))
//            VTCompressionSessionPrepareToEncodeFrames(compressionSession)
//    }
    
}
