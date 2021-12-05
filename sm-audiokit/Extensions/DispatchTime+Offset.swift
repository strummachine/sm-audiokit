//
//  DispatchTime+Offset.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 12/5/21.
//

import Foundation

extension DispatchTime {
   static func offSetNow(with offset:Float) -> DispatchTime {
       let now = DispatchTime.now()
        let milliSeconds: Int = Int((offset*1000))
        let offsetTimeInterval = DispatchTimeInterval.milliseconds(milliSeconds)
        let newTime = now + offsetTimeInterval
        return newTime
    }
}
