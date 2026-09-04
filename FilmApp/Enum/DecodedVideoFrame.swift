//
//  DecodedVideoFrame.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-08-10.
//

internal import AVFoundation

struct DecodedVideoFrame: Sendable{
    let pixelBuffer: CVPixelBuffer
    let pts: CMTime
    let duration: CMTime
}
