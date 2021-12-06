//
//  ErrorTypes.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 12/6/21.
//

import Foundation

enum AudioPackageError: Error, CustomStringConvertible {
    case unableToFindPathForResrouce
    case unableToLoadDataFromURL(error: Error)
    case unableToSerializeJSON(error: Error)
    case unableToRetrieveDocumentsDirectory(error: Error)
    case unableToStoreSampleToDisk(error: Error)
    case unknownError

    var description: String {
        switch self {
            case .unableToFindPathForResrouce:
                return "Unable to find path for Bundle Resource"
            case .unableToLoadDataFromURL(let error):
                return String("Unable to load data from URL. Error message:\(error.localizedDescription)")
            case .unableToSerializeJSON(let error):
                return String("Unable to serialize JSON. Error message:\(error.localizedDescription)")
            case .unableToRetrieveDocumentsDirectory(let error):
                return String("Unable to retrive documents directory. Error message:\(error.localizedDescription)")
            case .unableToStoreSampleToDisk(let error):
                return String("Unable to store sample to disk. Error message:\(error.localizedDescription)")
            case .unknownError:
                return "Unkown Error occured"
        }
    }
}

enum AudioManagerError: Error, CustomStringConvertible {
    case audioEngineCannotStart(error: Error)
    case cannotFindSample(sampleId: String)
    case cannotFindChannel(channel: String)
    
    var description: String {
        switch self {
            case .audioEngineCannotStart(let error):
                return String("Audio engine cannot start. Error message:\(error.localizedDescription)")
            case .cannotFindSample(let sampleId):
                return String("Cannot find sample with sampleId:\(sampleId)")
            case .cannotFindChannel(let channel):
                return String("Cannot find channel with channelId:\(channel)")
        }
    }
}
