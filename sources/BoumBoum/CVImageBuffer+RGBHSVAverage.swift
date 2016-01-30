//
//  CVImageBuffer+RGBHSVAverage.swift
//  BoumBoum
//
//  Created by Kevin DELANNOY on 20/01/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit
import AVFoundation

typealias RGB = (r: CGFloat, g: CGFloat, b: CGFloat)
typealias HSV = (h: CGFloat, s: CGFloat, v: CGFloat)

extension CVImageBuffer {
    func averageRGBHSVValueFromImageBuffer() -> (rgb: RGB, hsv: HSV) {
        CVPixelBufferLockBaseAddress(self, 0)

        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        var buffer = UnsafeMutablePointer<UInt8>(CVPixelBufferGetBaseAddress(self))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)

        //Let's compute average RGB value of the frame
        var r = CGFloat(0)
        var g = CGFloat(0)
        var b = CGFloat(0)

        for _ in 0..<height {
            for x in 0..<width {
                let rx = x * 4
                b = b + CGFloat(buffer[rx])
                g = g + CGFloat(buffer[rx + 1])
                r = r + CGFloat(buffer[rx + 2])
            }
            buffer += bytesPerRow
        }

        CVPixelBufferUnlockBaseAddress(self, 0)

        let bufferSize = width * height
        r = r / CGFloat(255 * bufferSize)
        g = g / CGFloat(255 * bufferSize)
        b = b / CGFloat(255 * bufferSize)

        let rgb = (r, g, b)
        let hsv = RGBToHSV(rgb)
        return (rgb, hsv)
    }

    private func RGBToHSV(value: RGB) -> HSV {
        let minimum = min(value.r, min(value.g, value.b))
        let maximum = max(value.r, max(value.g, value.b))
        let delta = maximum - minimum

        if maximum > CGFloat(FLT_EPSILON) {
            let h: CGFloat
            let v = maximum
            let s = delta / maximum

            if value.r == maximum {
                h = (value.g - value.b) / delta
            }
            else if value.g == maximum {
                h = 2 + (value.b - value.r) / delta
            }
            else {
                h = 4 + (value.r - value.g) / delta
            }

            if h < 0 {
                return (h + 360, 0, 0)
            }
            return (h, s, v)
        }
        return (0, 0, 0)
    }
}
