var exec = require("cordova/exec");

function execNativeWithArgs(methodName, transformArgs) {
  return function(args, success, error) {
    exec(success, error, "CordovaAudioKitPlugin", methodName, transformArgs(args));
  }
}

// === Init / Setup

/**
 * Initialize AudioKit engine
 */
exports.initialize = execNativeWithArgs('initialize', (args) => []);

/**
 * Load audio-package from bundle.
 * @returns { loadedSamples: { sampleId: string; duration: number }[]
 * @throws if there's a problem loading the bundle
 */
exports.setupChannels = execNativeWithArgs('setupChannels', (args) => [
  args.channelNames, // string[]
]);

// /**
//  * Load audio-package from bundle.
//  * @returns { loadedSamples: { sampleId: string; duration: number }[]
//  * @throws if there's a problem loading the bundle
//  */
// exports.loadPackage = execNativeWithArgs('loadPackage', (args) => [
//   args.path, // string, path relative to Meteor's /public directory
// ]);

/**
 * Load sample from MP3 data
 * @returns { sampleId: string; duration: number }
 * @throws if there's a problem loading the file
 */
exports.loadSample = execNativeWithArgs('loadSample', (args) => [
  args.sampleId, // string
  args.audioData, // ArrayBuffer
]);

/**
 * Prepare to play audio soon; configures AVAudioSession, syncs clock
 */
exports.gonnaPlay = execNativeWithArgs('gonnaPlay', (args) => [
  // passes seconds since app was loaded; unlike Date.now(), this is unaffected by NTP updates
  performance.now() /* which is in ms */ * 0.001
]);

/**
 * Audio is stopping; can deactivate AVAudioSession
 */
exports.gonnaStop = execNativeWithArgs('gonnaStop', (args) => []);

// === Master Channel

// TODO: Should we just re-use the "setChannel_____" calls with "master" as the channel name?

/**
 * Changes volume of master channel over specified time period
 */
exports.setMasterVolume = execNativeWithArgs('setMasterVolume', (args) => [
  args.volume, // number (scale TBD)
  // TODO: should we just hard-code this into Swift?
  args.fadeDuration || 0.05, // number, defaults to 50ms fade to prevent popping
]);

// TODO:
// exports.setMasterEQ = execNativeWithArgs('setMasterEQ', (args) => []);
// exports.setMasterReverb = execNativeWithArgs('setMasterReverb', (args) => []);
// exports.setMasterCompressor = execNativeWithArgs('setMasterCompressor', (args) => []);

// === Channels

exports.setChannelVolume = execNativeWithArgs('setChannelVolume', (args) => [
  args.channel, // string
  args.volume, // number (scale TBD)
  // TODO: should we just hard-code this into Swift?
  args.fadeDuration || 0.05, // number, defaults to 50ms fade to prevent popping
]);

exports.setChannelPan = execNativeWithArgs('setChannelPan', (args) => [
  args.channel, // string
  args.pan, // number (-1 to 1)
]);

exports.setChannelMuted = execNativeWithArgs('setChannelMuted', (args) => [
  args.channel, // string
  args.muted, // boolean
]);

// === Playbacks

function generateRandomPlaybackId() {
  return (
    Math.floor(Math.random() * 3600000000).toString(36) + 
    (Math.floor(performance.now() * 100) % 3600000).toString(36)
  );
}

/**
 * @returns { playbackId: string }
 */
exports.playSample = execNativeWithArgs('playSample', (args) => [
  args.sampleId, // string (file to play)
  args.channel, // string
  args.playbackId || generateRandomPlaybackId(), // string
  args.atTime, // number
  args.volume || DEFAULT_VOLUME, // number (scale TBD)
  args.offset || 0, // number, start offset within file
  args.playbackRate || 1, // number
  args.fadeInDuration || 0,
  args.playDuration || -1,
]);

/**
 * Schedule fade volume of playback over specified duration.
 */
exports.setPlaybackVolume = execNativeWithArgs('setPlaybackVolume', (args) => [
  args.playbackId, // string
  args.atTime, // number
  args.volume || 1, // number (scale TBD)
  args.fadeDuration || 0.001,
]);

/**
 * We can hold off on this... initial experiments suggest it is a crappy
 * substitute for actual string bending...
 */
exports.setPlaybackRate = execNativeWithArgs('changePlaybackRate', (args) => [
  args.playbackId, // string
  args.atTime, // number
  args.playbackRate || 1, // number
  args.tweenDuration || 0.001,
]);

/**
 * Stop playback at specified time over specified fade duration.
 */
exports.stopPlayback = execNativeWithArgs('stopPlayback', (args) => [
  args.playbackId, // string
  args.atTime, // number, stop immediately if nullish
  args.fadeDuration || 0.001,
]);

// LATER: Recording to MP3, with or without the mic
// LATER: Tuner stuff: activate, poll, deactivate
