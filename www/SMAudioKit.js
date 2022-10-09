var exec = require("cordova/exec");

function execNativeWithArgs(methodName, transformArgs) {
  return function (args, success, error) {
    exec(success, error, "CordovaAudioKitPlugin", methodName, transformArgs(args));
  }
}

exports.apiVersion = 4;

// === Init / Setup

/**
 * Initialize AudioKit engine
 */
exports.initialize = execNativeWithArgs('initialize', (args) => [
  args.channels.map(c => c.id),
  args.channels.map(c => c.polyphonyLimit),
]);

exports.getStoredSampleList = execNativeWithArgs('getStoredSampleList', (args) => []);

exports.loadSamplesFromDisk = execNativeWithArgs('loadSamplesFromDisk', (args) => [
  args, // { packageId, sampleId }[]
]);

exports.deleteSamples = execNativeWithArgs('deleteSamples', (args) => [
  args, // { packageId, sampleId }[]
]);

exports.storeSample = execNativeWithArgs('storeSample', (args) => [
  args.packageId, // string
  args.sampleId, // string
  args.audioData, // ArrayBuffer
]);

/**
 * Prepare to play audio soon; configures AVAudioSession, syncs clock
 */
exports.startEngine = execNativeWithArgs('startEngine', (args) => [
  // passes seconds since app was loaded; unlike Date.now(), this is unaffected by NTP updates
  performance.now() /* which is in ms */ * 0.001
]);

/**
 * Audio is stopping; can deactivate AVAudioSession
 */
exports.stopEngine = execNativeWithArgs('stopEngine', (args) => []);

// === Master Channel

/**
 * Changes volume of master channel
 */
exports.setMasterVolume = execNativeWithArgs('setMasterVolume', (args) => [
  args.volume, // number (0 to 1)
  // should we just hard-code this into Swift?
  typeof args.fadeDuration == 'number' ? args.fadeDuration : 0.05, // number, defaults to 50ms fade to prevent popping
]);

exports.setMasterPitchShift = execNativeWithArgs('setMasterPitch', (args) => [
  args.cents // number
]);

// TODO:
// exports.setMasterEQ = execNativeWithArgs('setMasterEQ', (args) => []);
// exports.setMasterReverb = execNativeWithArgs('setMasterReverb', (args) => []);
// exports.setMasterCompressor = execNativeWithArgs('setMasterCompressor', (args) => []);

// === Channels

exports.setChannelVolume = execNativeWithArgs('setChannelVolume', (args) => [
  args.channel, // string
  args.volume, // number (scale TBD)
  // should we just hard-code this into Swift?
  typeof args.fadeDuration == 'number' ? args.fadeDuration : 0.05, // number, defaults to 50ms fade to prevent popping
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

const argsTransformers = {
  'playSample': (args) => [
      args.sampleId, // string (file to play)
      args.channel, // string
      args.playbackId || generateRandomPlaybackId(), // string
      args.atTime, // number
      typeof args.volume == 'number' ? args.volume : DEFAULT_VOLUME, // number (scale TBD)
      typeof args.offset == 'number' ? args.offset : 0, // number, start offset within file
      typeof args.fadeInDuration == 'number' ? args.fadeInDuration : 0,
    ],
  'setPlaybackVolume': (args) => [
      args.playbackId, // string
      args.atTime, // number
      typeof args.volume == 'number' ? args.volume : 1, // number (scale TBD)
      typeof args.fadeDuration == 'number' ? args.fadeDuration : 0.01,
    ],
  'stopPlayback': (args) => [
      args.playbackId, // string
      args.atTime, // number, stop immediately if nullish
      typeof args.fadeDuration == 'number' ? args.fadeDuration : 0.01,
    ]
}

/**
 * Batched calls
 */
exports.sendBatchedCommands = (commands, success, error) => {
  exec(success, error, "CordovaAudioKitPlugin", "sendBatchedCommands", [commands.map(([ name, args ]) => {
    return [ name, argsTransformers[ name ]?.(args) ];
  })]);
}

/**
 * @returns { playbackId: string }
 */
exports.playSample = execNativeWithArgs('playSample', argsTransformers.playSample);

exports.setPlaybackVolume = execNativeWithArgs('setPlaybackVolume', argsTransformers.setPlaybackVolume);

exports.stopPlayback = execNativeWithArgs('stopPlayback', argsTransformers.stopPlayback);





// LATER: Recording to MP3, with or without the mic
// LATER: Tuner stuff: activate, poll, deactivate
