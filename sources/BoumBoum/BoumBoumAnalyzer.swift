//
//  BoumBoumAnalyzer.swift
//  BoumBoum
//
//  Created by Kevin DELANNOY on 23/01/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit

// MARK: - BoumBoumAnalyzer
////////////////////////////////////////////////////////////////////////////

internal class BoumBoumAnalyzer {
    private var maxDeltaBetweenPulsation = CGFloat(1.5)
    private var minDeltaBetweenPulsation = CGFloat(0.1)

    private var validFrameCount = 0
    private var lastBoumBoumIsDown = false
    private var lastBoumBoumTime = CGFloat(0)
    private var matrix: [(x: CGFloat, y: CGFloat)]
    private var values: [(up: CGFloat, down: CGFloat)]
    private var periods: [(val: CGFloat, time: CGFloat)]
    private var indexes: (up: Int, down: Int, value: Int)

    var minimumFrameCountToSettle = 10

    init() {
        matrix = Array(count: 11, repeatedValue: (0, 0))
        values = Array(count: 20, repeatedValue: (-1, -1))
        periods = Array(count: 20, repeatedValue: (-1, -1))
        indexes = (0, 0, 0)
    }

    func pushValues(hsv: HSV) {
        if hsv.s > 0.5 && hsv.v > 0.5 {
            validFrameCount++

            let filtered = processValue(hsv)
            if validFrameCount > minimumFrameCountToSettle {
                addNewValue(filtered, atTime: CGFloat(CACurrentMediaTime()))
            }
        }
        else {
            validFrameCount = 0
            resetValues()
        }
    }

    // see http://www-users.cs.york.ac.uk/~fisher/mkfilter/
    private func processValue(hsv: HSV) -> CGFloat {
        matrix = matrix.shifted()

        let gain = CGFloat(1.894427025e+01)
        var tuple = matrix[matrix.count - 1]
        matrix[matrix.count - 1] = (hsv.h / gain, tuple.y)

        let y = matrix[10].x - matrix[0].x + 5 * (matrix[2].x - matrix[8].x) +
            10 * (matrix[6].x - matrix[4].x) + 0.0357796363 * matrix[1].y +
            -0.1476158522 * matrix[2].y + 0.3992561394 * matrix[3].y +
            -1.1743136181 * matrix[4].y + 2.4692165842 * matrix[5].y +
            -3.3820859632 * matrix[6].y + 3.9628972812 * matrix[7].y +
            -4.3832594900 * matrix[8].y + 3.2101976096 * matrix[9].y

        tuple = matrix[matrix.count - 1]
        matrix[matrix.count - 1] = (tuple.x, y)
        return y
    }

    private func addNewValue(value: CGFloat, atTime time: CGFloat) {
        if value > 0 {
            values[indexes.up].up = value
            indexes.up++

            if indexes.up >= 20 {
                indexes.up = 0
            }
        }
        else if value < 0 {
            values[indexes.down].down = -value
            indexes.down++

            if indexes.down >= 20 {
                indexes.down = 0
            }
        }

        let upFiltered = values.flatMap { e in
            return e.up != -1 ? e.up : nil
        }
        let averageUpValue = upFiltered.reduce(0, combine: +) / CGFloat(upFiltered.count)

        let downFiltered = values.flatMap { e in
            return e.down != -1 ? e.down : nil
        }
        let averageDownValue = downFiltered.reduce(0, combine: +) / CGFloat(downFiltered.count)

        if value < -0.5 * averageDownValue {
            lastBoumBoumIsDown = true
        }

        if value >= 0.5 * averageUpValue && lastBoumBoumIsDown {
            lastBoumBoumIsDown = false

            let delta = time - lastBoumBoumTime
            if delta < maxDeltaBetweenPulsation && delta > minDeltaBetweenPulsation {
                periods[indexes.value] = (delta, time)
                indexes.value++

                if indexes.value >= 20 {
                    indexes.value = 0
                }
            }
            lastBoumBoumTime = time
        }
    }

    private func resetValues() {
        periods = Array(count: 20, repeatedValue: (-1, -1))
        values = Array(count: 20, repeatedValue: (-1, -1))

        indexes = (0, 0, 0)
        lastBoumBoumIsDown = false
    }

    func averageBoumBoum() -> UInt? {
        let time = CGFloat(CACurrentMediaTime())
        let filtered = periods.filter { e in
            return e.val != -1 && time - e.time < 10
        }

        if filtered.count > 2 {
            let average = filtered.reduce(0, combine: { $0 + $1.val }) / CGFloat(filtered.count)
            return UInt(60 / average)
        }
        return nil
    }
}

////////////////////////////////////////////////////////////////////////////


// MARK: Array+Shift
////////////////////////////////////////////////////////////////////////////

extension Array {
    private func shifted(delta: Int = 1) -> [Element] {
        var new = [Element]()
        for e in enumerate() {
            new.append(self[(e.index + delta) % count])
        }
        return new
    }
}

////////////////////////////////////////////////////////////////////////////
