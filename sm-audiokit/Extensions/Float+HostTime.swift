//
//  Float+HostTime.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 12/6/21.
//

import Foundation

extension Float {
    var hostTime: UInt64 {
        return UInt64(Int(self * 1000 * 1000 * 1000))
    }
}
