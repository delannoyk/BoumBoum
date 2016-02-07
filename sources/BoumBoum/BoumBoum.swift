//
//  BoumBoum.swift
//  BoumBoum
//
//  Created by Kevin DELANNOY on 20/01/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit
import AVFoundation

public enum BoumBoumError: ErrorType {
    case AlreadyRunning
    case AlreadyStopped
    case CameraUnavailable
    case TorchModeUnsupported
    case CameraLockFailed(NSError)
    case CameraDeviceInputCreationFailed(NSError)
}

public protocol BoumBoumDelegate: class {
    func boumBoum(boumBoum: BoumBoum, didFindAverageRate rate: UInt)
}

public class BoumBoum: NSObject {
    public enum State {
        case Running
        case Stopped
    }

    public let session: AVCaptureSession
    public let camera: AVCaptureDevice?
    public weak var delegate: BoumBoumDelegate?

    public private(set) var state = State.Stopped

    private let analyzer = BoumBoumAnalyzer()
    private var cameraInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    public override convenience init() {
        self.init(session: AVCaptureSession(),
            camera: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo))
    }

    public init(session: AVCaptureSession, camera: AVCaptureDevice) {
        self.session = session
        self.camera = camera
        super.init()
    }

    private init(session: AVCaptureSession, camera: AVCaptureDevice?) {
        self.session = session
        self.camera = camera
        super.init()
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Start / Stop
    ////////////////////////////////////////////////////////////////////////////

    public func startMonitoring() throws {
        //Ensuring we have a camera
        guard let camera = camera else {
            throw BoumBoumError.CameraUnavailable
        }

        //Ensuring we're stopped
        guard state == .Stopped else {
            throw BoumBoumError.AlreadyRunning
        }

        //First, we turn on the torch
        guard camera.isTorchModeSupported(.On) else {
            throw BoumBoumError.TorchModeUnsupported
        }

        do {
            try camera.lockForConfiguration()
            camera.torchMode = .On
            camera.unlockForConfiguration()
        } catch let error {
            throw BoumBoumError.CameraLockFailed(error as NSError)
        }

        //Then, we create an input
        let cameraInput: AVCaptureDeviceInput
        if let existingInput = self.cameraInput {
            cameraInput = existingInput
        }
        else {
            do {
                cameraInput = try AVCaptureDeviceInput(device: camera)
                self.cameraInput = cameraInput
            } catch let error {
                throw BoumBoumError.CameraDeviceInputCreationFailed(error as NSError)
            }
        }

        //Let's create the output
        let cameraOutput = videoOutput ?? configuredCameraOutput(self)
        videoOutput = cameraOutput

        //Configure session
        session.sessionPreset = AVCaptureSessionPresetLow
        session.addInput(cameraInput)
        session.addOutput(cameraOutput)

        //And we're good to go
        session.startRunning()
        state = .Running
    }

    public func stopMonitoring() throws {
        //Ensuring we have a camera
        guard let camera = camera else {
            throw BoumBoumError.CameraUnavailable
        }

        //Ensuring we're running
        guard state == .Running else {
            throw BoumBoumError.AlreadyStopped
        }

        //First, we stop the session
        session.stopRunning()

        //Then we remove input and output
        if let cameraInput = cameraInput {
            session.removeInput(cameraInput)
        }
        if let videoOutput = videoOutput {
            session.removeOutput(videoOutput)
        }

        //And we turn off the torch
        guard camera.isTorchModeSupported(.On) else {
            throw BoumBoumError.TorchModeUnsupported
        }

        do {
            try camera.lockForConfiguration()
            camera.torchMode = .Off
            camera.unlockForConfiguration()
        } catch let error {
            throw BoumBoumError.CameraLockFailed(error as NSError)
        }

        //We're good to go
        state = .Stopped
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Output creation
    ////////////////////////////////////////////////////////////////////////////

    private func configuredCameraOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) -> AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        let queue = dispatch_queue_create("be.delannoyk.boumboum", nil)
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)
        ]
        return videoOutput
    }

    ////////////////////////////////////////////////////////////////////////////
}

extension BoumBoum: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        guard let value = CMSampleBufferGetImageBuffer(sampleBuffer)?.averageRGBHSVValueFromImageBuffer() else {
            return
        }

        analyzer.pushValues(value.hsv)
        if let rate = analyzer.averageBoumBoum() {
            dispatch_sync(dispatch_get_main_queue()) { [weak self] in
                if let strongSelf = self {
                    strongSelf.delegate?.boumBoum(strongSelf, didFindAverageRate: rate)
                }
            }
        }
    }
}
