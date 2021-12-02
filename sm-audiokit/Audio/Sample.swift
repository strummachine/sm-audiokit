//
//  Sample.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 11/29/21.
//

import Foundation

struct Sample {
    var id: String
    var url: URL
    var duration: Float64    

    init(id: String, url: URL, duration: Float64) {
        self.id = id
        self.url = url
        self.duration = duration
    }
}

