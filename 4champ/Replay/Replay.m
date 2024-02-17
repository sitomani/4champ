//
//  Replay.m
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import "Replay.h"
#import "MPTReplayer.h"
#import "UADEReplayer.h"
#import "HVLReplayer.h"
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface Replay () {
  AudioComponentInstance audioUnit;
  AURenderCallbackStruct callbackStruct;
  id<ReplayControl, ReplayInformation, ReplayerStream> renderer;
}

#define maxFrameSize 4096

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSDictionary* replayerMap;
@property (nonatomic, strong) NSArray* replayers;
#define checkStatus( err) \
if(err) {\
NSLog(@"Error in audio %@", @(err));\
}

@end

@implementation Replay

@synthesize name = _name;

// Static byte buffers for reading render data into
static SInt16* bufLeft;
static SInt16* bufRight;

+ (NSArray<NSString*>*)supportedFormats {
  NSMutableArray* formats = [[NSMutableArray alloc] init];
  [formats addObjectsFromArray:[MPTReplayer supportedFormats]];
  [formats addObjectsFromArray:[HVLReplayer supportedFormats]];
  [formats addObjectsFromArray:[UADEReplayer supportedFormats]];
  return formats;
}

-(id)init
{
  self=[super init];
  if (self) {
    self.replayers = @[[MPTReplayer class], [HVLReplayer class], [UADEReplayer class]];
    _name = @"";
  }
  return self;
}

-(void) initAudio
{
  //set up audio buffers for rendering
  bufLeft = malloc(maxFrameSize * 2 * sizeof(SInt16));
  bufRight = malloc(maxFrameSize * 2 * sizeof(SInt16));

  OSStatus status;
  
  // Describe audio component
  AudioComponentDescription desc;
  desc.componentType = kAudioUnitType_Output;
  desc.componentSubType = kAudioUnitSubType_RemoteIO;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;
  desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  
  // Get component
  AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
  
  // Get audio units
  status = AudioComponentInstanceNew(inputComponent, &audioUnit);
  checkStatus(status);
  
  UInt32 flag = 1;
  const int kOutputBus = 0;
  // Enable IO for playback
  status = AudioUnitSetProperty(audioUnit,
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Output,
                                kOutputBus,
                                &flag,
                                sizeof(flag));
  checkStatus(status);
  
  // Describe format
  AudioStreamBasicDescription audioFormat;
  audioFormat.mSampleRate      = 44100.00;
  audioFormat.mFormatID      = kAudioFormatLinearPCM;
  audioFormat.mFormatFlags    = kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  audioFormat.mFramesPerPacket  = 1;
  audioFormat.mChannelsPerFrame = 2;
  audioFormat.mBitsPerChannel   = 16;
  audioFormat.mBytesPerPacket   = 2;
  audioFormat.mBytesPerFrame    = 2;
  
  
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                kOutputBus,
                                &audioFormat,
                                sizeof(audioFormat));
  checkStatus(status);
  
  
  // Set output callback
  callbackStruct.inputProc = playbackCallback;
  callbackStruct.inputProcRefCon = (__bridge void *)(self);
  status = AudioUnitSetProperty(audioUnit,
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Global,
                                kOutputBus,
                                &callbackStruct,
                                sizeof(callbackStruct));
  checkStatus(status);
  
  
  // Initialise
  status = AudioUnitInitialize(audioUnit);
  checkStatus(status);
}

- (bool) loadModule:(NSString *)path type:(NSString*)type
{
  if (type == nil) {
    type = [[path pathExtension] uppercaseString];
  }
  Class replayerClass;
  for (int i=0; i< self.replayers.count; i++) {
    if ([[self.replayers[i] supportedFormats] containsObject:(type)]) {
      replayerClass = self.replayers[i];
    }
  }
  if (renderer) {
    [self pause];
  }
  if (![[renderer class] isEqual:replayerClass]) {
      if(renderer) {
          [renderer cleanup];
      }
    renderer = [[replayerClass alloc] init];
  }
  _name = renderer.name;
  return [renderer loadModule:path type:type];
}

- (NSInteger) volumeOnChannel:(NSInteger)channel
{
  return [renderer volumeOnChannel:channel];
}

- (NSInteger) numberOfChannels
{
  return [renderer numberOfChannels];
}

- (void)pause
{
  if(renderer) {
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
  }
  [self setPausedStatus:YES];
}

- (void)resume
{
  if(renderer) {
    OSStatus status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
    [self setPausedStatus:NO];
  }
}

- (void)stop {
  if (renderer) {
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
    [renderer setCurrentPosition:0];
  }
  [self setPlayingStatus:NO];
}

// mod specific API
- (void)play {
  OSStatus status = AudioOutputUnitStart(audioUnit);
  checkStatus(status);
  [self setPlayingStatus:YES];

}

- (NSArray*) getSamples
{
  if (renderer) {
    return [renderer getSamples];
  } else {
    return @[];
  }
}

- (NSArray<NSString*>*) getInstruments
{
  if (renderer) {
    return [renderer getInstruments];
  } else {
    return @[];
  }
}

- (int) moduleLength
{
  if (renderer) {
    return [renderer moduleLength];
  } else {
    return 0;
  }
}
- (int) currentPosition
{
  if(renderer) {
    return [renderer currentPosition];
  } else {
    return 0;
  }
}
- (void) setCurrentPosition: (int)newPosition
{
  [self pause];
  [renderer setCurrentPosition:newPosition];
  [self resume];
}

- (void)setStereoSeparation:(NSInteger)value {
  if (renderer) {
    [renderer setStereoSeparation:value];
  }
}

- (void) setInterpolationFilterLength:(NSInteger)value {
  if (renderer) {
    [renderer setInterpolationFilterLength:value];
  }
}

- (void)cleanup {
  //noop, done in loadModule for the replayer
}




-(void)dealloc {
  if (renderer != nil) {
    renderer = nil;
  }
  AudioComponentInstanceDispose(audioUnit);
}

- (void) setPlayingStatus:(BOOL)playing {
  _isPlaying = playing;
  if (playing) {
    [self setPausedStatus:NO];
  }
  if (_statusDelegate) {
    [_statusDelegate playStatusChanged:self];
  }
}

- (void) setPausedStatus:(BOOL)paused {
  _isPaused = paused;
  if (_statusDelegate) {
    [_statusDelegate playStatusChanged:self];
  }
}

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
  Replay* mp = (__bridge Replay*)inRefCon;
  if(mp->renderer) {
    int size = inNumberFrames;
    //in one frame: 2 channels, 16bits per channel
    int ret = [mp->renderer readFrames:size bufLeft:bufLeft bufRight:bufRight];
    if (ret > 0) {
      SInt16* buf = ioData->mBuffers[0].mData;
      SInt16* buf2 = ioData->mBuffers[1].mData;
      for (UInt32 frame = 0; frame < ret; frame++)
      {
        UInt16 p1 = bufLeft[frame];
        UInt16 p2 = bufRight[frame];
        buf[frame] = p1;
        buf2[frame] = p2;
      }
    } else {
      //out of bytes... just put frame's worth of zeros and inform delegate
      for( UInt32 i = 0; i < ioData->mNumberBuffers; i++ )
        memset( ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize );
      if ([mp streamDelegate]) {
        [[mp streamDelegate] reachedEndOfStream:mp];
      }
    }
  } else {
    //no replayer loaded... stop playback
    [mp stop];
  }
  
  return noErr;
}

@end
