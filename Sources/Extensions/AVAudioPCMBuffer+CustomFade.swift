//
//  AVAudioPCMBuffer+CustomFade.swift
//  sm-audiokit
//
//  Created by Maximilian Maksutovic on 12/1/21.
//

import Foundation
import AVFAudio
import AudioKit

extension AVAudioPCMBuffer {
    // We need Fade OUTS not fade INs
    
    /// - Returns: A new buffer from this one that has Web Audio fade applied, sm = StrumMachine
       public func smFadeIn(inTime: Double) -> AVAudioPCMBuffer? {
           guard let floatData = floatChannelData, inTime > 0 else {
               Log("Error fading buffer, returning original...")
               return self
           }

           let fadeBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                             frameCapacity: frameCapacity)

           let length: UInt32 = frameLength
           let sampleRate = format.sampleRate
           let channelCount = Int(format.channelCount)

           // initial starting point for the gain, if there is a fade in, start it at .01 otherwise at 1
           var gain: Double = inTime > 0 ? 0.01 : 1

           let sampleTime: Double = 1.0 / sampleRate

           var fadeInPower: Double = 1.0
           
           
           // WebAudioEquation: value = to + (from - to) * e ^ (-3 * time / duration)
           // PolynomialEquation: value = 0.99 * to + (from - 0.99 * to) * ( (time - 3.6 * duration) / (3.6 * duration) ) ^ 10
           
           let toGain = 1.0
           let fromGain = 0.01
           let e = M_E
           let fadeDuration = inTime
           
//           let raisedTo = (-3 * )
           
           fadeInPower = toGain + (fromGain - toGain) * e
           
           //// Default exponential curve
           //fadeInPower = exp(log(10) * sampleTime / inTime)

           // where in the buffer to end the fade in
           let fadeInSamples = Int(sampleRate * inTime)

           // i is the index in the buffer
           for i in 0 ..< Int(length) {
               // n is the channel
               for n in 0 ..< channelCount {
                   if i < fadeInSamples, inTime > 0 {
                        gain += fadeInPower
                   }
                   else {
                       gain = 1.0
                   }

                   // sanity check
                   if gain > 1 {
                       gain = 1
                   } else if gain < 0 {
                       gain = 0
                   }

                   let sample = floatData[n][i] * Float(gain)
                   fadeBuffer?.floatChannelData?[n][i] = sample
               }
           }
           // update this
           fadeBuffer?.frameLength = length

           // set the buffer now to be the faded one
           return fadeBuffer
       }
}
