//
//  ViewController.swift
//  BoumBoumExample
//
//  Created by Kevin DELANNOY on 24/01/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit
import BoumBoum

class ViewController: UIViewController, BoumBoumDelegate {
    @IBOutlet weak var imageViewHeart: UIImageView?
    @IBOutlet weak var labelPulseRate: UILabel?

    let boum = BoumBoum()

    lazy var animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.7
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSNumber(float: 1)
        animation.toValue = NSNumber(float: 0.7)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        return animation
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        boum.delegate = self
    }

    @IBAction func buttonStartPressed(sender: UIButton) {
        if boum.state == .Stopped {
            do {
                try boum.startMonitoring()
                sender.setTitle("Stop Monitoring", forState: .Normal)
                imageViewHeart?.layer.addAnimation(animation, forKey: "heart")
            } catch {
            }
        }
        else {
            do {
                try boum.stopMonitoring()
                sender.setTitle("Start Monitoring", forState: .Normal)
                imageViewHeart?.layer.removeAnimationForKey("heart")
            } catch {
            }
        }
    }

    func boumBoum(boumBoum: BoumBoum, didFindAverageRate rate: UInt) {
        labelPulseRate?.text = "\(rate)"
        print(rate)
    }
}

