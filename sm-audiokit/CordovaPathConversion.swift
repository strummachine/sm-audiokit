//
//  CordovaPathConversion.swift
//  sm-audiokit
//
//  Created by Luke Abbott on 12/2/21.
//

import Foundation

class CordovaPathConversion {
    static func convert(path: NSString) -> URL? {
        let ext = path.pathExtension
        let filename = NSString(string: path.lastPathComponent).deletingPathExtension
        let directory = path.deletingLastPathComponent
        return Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "www/application/app/" + directory)
    }
}
