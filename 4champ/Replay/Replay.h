//
//  Replay.h
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/// The Replay control API
@protocol ReplayControl <NSObject>

/**
 Supported @formats
 */
@property (class, nonatomic, strong, readonly) NSArray<NSString*>* supportedFormats;

/**
 Loads module for playback from given path.
 @param path identifies the module file. Path extension can identify format (type)
 @param type can be passed separately if path does not have extension. If this parameter
        is given, it will be used to determine the replayer.
 */
- (bool) loadModule:(NSString*)path type:(NSString*)type;

/**
 Sets current position in the playing module
 @param newPosition the new position in range 0 - moduleLength
 */
- (void) setCurrentPosition: (int)newPosition;
 
/**
 Sets stereo separation of the module playback
@param value integer in range 0-100. Actual Replay implementation maps to correct scale
 */
- (void) setStereoSeparation:(NSInteger)value;

/**
 Sets interpolation filter length (used for LibOpenMPT playback)
 @param value integer that maps to a interpolation filter setting defined for OPENMPT_MODULE_RENDER_INTERPOLATIONFILTER_LENGTH
 in libpopenmpt.h
 */
- (void) setInterpolationFilterLength:(NSInteger)value;

/**
 Free replayer resources
 */
- (void) cleanup;

@end

/// Visualisation API getters
@protocol ReplayInformation <NSObject>
@property (nonatomic, strong, readonly) NSString* name; // name of the replayer lib
- (int) currentPosition; //returns current position in current module in seconds. 0 if not known
- (int) moduleLength; //returns current mod length in seconds. 0 if not known
- (NSInteger) volumeOnChannel:(NSInteger)channel; //returns current volume on requested channel
- (NSInteger) numberOfChannels; //returns number of channels in current module
- (NSArray<NSString*>*) getSamples; //returns sample names of current mod
- (NSArray<NSString*>*) getInstruments; //returns instrument names of current mod
@end

/// Stream API for getting rendered frames for output
@protocol ReplayerStream <NSObject>
- (int) readFrames:(size_t)count bufLeft:(int16_t*)bufLeft bufRight:(int16_t*)bufRight;
@end

@class Replay;

@protocol ReplayStreamDelegate <NSObject>

/**
 Called when replay reaches end of the module
 @param replay identifies the Replay object
 */
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
