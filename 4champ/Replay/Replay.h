//
//  Replay.h
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReplayControl <NSObject>
// Control API
- (bool) loadModule:(NSString*)path; //loads module from given path
- (void) setCurrentPosition: (int)newPosition; //sets current position in current mod.
- (void) setStereoSeparation:(NSInteger)value; //set stereo separation 0-200
@end

@protocol ReplayInformation <NSObject>
// Visualisation API getters
- (int) currentPosition; //returns current position in current module
- (int) moduleLength; //returns current mod length in seconds
- (NSInteger) volumeOnChannel:(NSInteger)channel; //returns current volume on requested channel
- (NSInteger) numberOfChannels; //returns number of channels in current module
- (NSArray<NSString*>*) getSamples; //returns sample names of current mod
- (NSArray<NSString*>*) getInstruments; //returns instrument names of current mod
@end

@protocol ReplayerStream <NSObject>
// Stream API
- (int) readFrames:(size_t)count bufLeft:(int16_t*)bufLeft bufRight:(int16_t*)bufRight;
@end

@interface Replay : NSObject<ReplayControl, ReplayInformation>
- (void) initAudio;
- (void) play;
- (void) stop;
- (void) pause;
- (void) resume;
@end
