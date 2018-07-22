//
//  Replay.h
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReplayControl <NSObject>
// Control API
- (bool) loadModule:(NSString*)path; //loads module from given path. Path extension must identify module format
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

@class Replay;

@protocol ReplayStreamDelegate <NSObject>
- (void) reachedEndOfStream:(Replay*)replay;
@end

@protocol ReplayStatusDelegate <NSObject>
- (void) playStatusChanged:(Replay*)replay;
@end

@interface Replay : NSObject<ReplayControl, ReplayInformation>
@property (nonatomic, weak) NSObject<ReplayStreamDelegate>* streamDelegate;
@property (nonatomic, weak) NSObject<ReplayStatusDelegate>* statusDelegate;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isPaused;
- (void) initAudio;
- (void) play;
- (void) stop;
- (void) pause;
- (void) resume;
@end
