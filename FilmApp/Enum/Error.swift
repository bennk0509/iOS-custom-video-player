//
//  Error.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-05.
//

import Foundation

enum ReaderError: LocalizedError{
    case cantFindVideoTrack
    case cantAddOutputToReader
    case startReadingFailed(underlyingError: Error?)

    var errorDescription: String? {
        switch self {
        case .cantFindVideoTrack:
            return "The file doesn't contain a video track."
        case .cantAddOutputToReader:
            return "Couldn't prepare the video for reading."
        case .startReadingFailed(let underlyingError):
            if let underlyingError {
                return "Couldn't read the video: \(underlyingError.localizedDescription)"
            }
            return "Couldn't read the video."
        }
    }
}

enum VideoDecodeError: LocalizedError{
    case cantCreateDecode
    case cantFindFormatDescription
    case sessionNotReady
    case decodeFrameFailed(OSStatus)
    case missingPixelBuffer

    var errorDescription: String? {
        switch self {
        case .cantCreateDecode:
            return "Couldn't create the video decoder."
        case .cantFindFormatDescription:
            return "The video format couldn't be determined."
        case .sessionNotReady:
            return "The video decoder isn't ready."
        case .decodeFrameFailed(let status):
            return "A video frame failed to decode (error \(status))."
        case .missingPixelBuffer:
            return "A decoded frame was missing its image data."
        }
    }
}

enum VideoManagerError: LocalizedError{
    case cantAddVideoRenderer
    case cantCreateSampleBuffer
    case cantCreateFormatDescription

//    var errorDescription: String? {
//        switch self {
//        case .cantAddVideoRenderer:
//            return "Couldn't set up the video renderer."
//        case .cantCreateSampleBuffer:
//            return "Couldn't prepare a frame for display."
//        }
//    }
}
