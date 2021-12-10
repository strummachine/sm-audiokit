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

enum SampleStorageError: Error, CustomStringConvertible {
    case cannotGetSampleList(error: Error)
    case cannotUnwrapDocumentsDirectoryURL
    case cannotDeleteSamples(error: Error)
    var description: String {
        switch self {
        case .cannotGetSampleList(let error):
            return String("Error: Unable to retrieve sample list:\(error)")
        case .cannotUnwrapDocumentsDirectoryURL:
            return "Error: Unable to unwrap Documents Directory URL"
        case .cannotDeleteSamples(let error):
            return String("Error: Unable to delete samples:\(error)")
        }
    }
}

enum AudioManagerError: Error, CustomStringConvertible {
    case audioEngineCannotStart(error: Error)
    case cannotFindSample(sampleId: String)
    case cannotFindChannel(channel: String)
    case cannotFindChannelId(channelId: String)
    case cannotUnwrapMainMixerNode
    case cannotUnwrapLastRenderTime
    case cannotUnwrapDocumentsDirectoryURL
    var description: String {
        switch self {
            case .audioEngineCannotStart(let error):
                return String("Audio engine cannot start. Error message:\(error.localizedDescription)")
            case .cannotFindSample(let sampleId):
                return String("Cannot find sample with sampleId:\(sampleId)")
            case .cannotFindChannel(let channel):
                return String("Cannot find channel with channelId:\(channel)")
            case .cannotFindChannelId(let id):
                return String("Cannot unwrap channel id with id:\(id)")
            case .cannotUnwrapDocumentsDirectoryURL:
                return "Cannot unwrap Documents Directory URL"
            case .cannotUnwrapMainMixerNode:
                return "Cannot unwrap main mixer node. Most likely nil or engine is not running"
            case .cannotUnwrapLastRenderTime:
                return "Cannot Unwrap lastRenderTime. Most likely nil or engine is not running"
        }
    }
}

enum SamplePlaybackError: Error, CustomStringConvertible {
    case cannotLoadPlayer
    
    var description: String {
        switch self {
        case .cannotLoadPlayer:
            return "Cannot load player"
        }
    }
}
