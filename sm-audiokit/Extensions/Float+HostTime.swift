//
//  Float+HostTime.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 12/6/21.
//

import Foundation

extension DispatchTime {
    // .advanced(by:) is iOS 13+ only, so we do this instead:
    func advanced(nanoseconds: Int) -> DispatchTime {
        return self + Double(nanoseconds) / 1000000000.0
    }
}
