//
//  HVLReplayer.m
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import "MPTReplayer.h"
#import "HVLReplayer.h"
#import "hvl_replay.h"


#define kSampleRate 44100
#define kHivelyRenderSamples (kSampleRate/50)
#define kBufferSamples (kSampleRate/10)
#define kNumBuffers 8


@implementation HVLReplayer {
    struct hvl_tune* currentHVLtune;
    int16_t* leftByte;
    int16_t* rightByte;
    int modlen;
    int curpos;
    
    int hvlStereoSeparation;
}

@synthesize name = _name;
@synthesize looping = _looping;
static int iHivelyBufPos = 0;

+ (NSArray<NSString*>*)supportedFormats {
    return @[@"THX", @"AHX", @"HVL"];
}

- (HVLReplayer*) init {
    self = [super init];
    if (self) {
        _name = @"Hively";
        hvl_InitReplayer();
        
        iHivelyBufPos = kHivelyRenderSamples;
        leftByte = static_cast<int16_t *>(malloc(sizeof(int16_t) * kHivelyRenderSamples));
        rightByte = static_cast<int16_t *>(malloc(sizeof(int16_t) * kHivelyRenderSamples));
        
        memset( leftByte, 0, sizeof(int16_t) * kHivelyRenderSamples);
        memset( rightByte, 0, sizeof(int16_t) * kHivelyRenderSamples);

        /*
         defstereo is the stereo seperation for playing AHX tunes (HVL tunes override
         this setting and ignore it). It can be:
         
         0 = 0%  (mono)
         1 = 25%
         2 = 50%
         3 = 75%
         4 = 100% (paula)*/
        //set stereo separation
        NSInteger stereoseparation = 50;
        hvlStereoSeparation = ceil(stereoseparation/200 * 4);
    }
    return self;
}

- (void)dealloc {
    NSLog(@"HVLReplayer deallocated");
}

- (void) cleanup {
    if (currentHVLtune) {
        hvl_FreeTune(currentHVLtune);
        free(leftByte);
        free(rightByte);
        currentHVLtune = nil;
    }
}

- (int) readFrames:(size_t)count bufLeft:(int16_t*)bufLeft bufRight:(int16_t*)bufRight {
    if (!currentHVLtune) {
        return 0;
    }

    if (currentHVLtune->ht_SongEndReached && !_looping) {
        return 0; //return zero to trigger mod change, hvl+ahx loop forever
    }
    int left = (int)count;
    int readsize = 0;
    
    while ( (left > 0) && (iHivelyBufPos < kHivelyRenderSamples) ) {
        *bufLeft++ = leftByte[iHivelyBufPos];
        *bufRight++ = rightByte[iHivelyBufPos];
        iHivelyBufPos++;
        left--;
        readsize++;
    }
    
    while ( left > 0 ) {
        hvl_DecodeFrame(currentHVLtune, (int8*)leftByte, (int8*)rightByte, 2);
        iHivelyBufPos = 0;
        while ( (left > 0) && (iHivelyBufPos < kHivelyRenderSamples) ) {
            *bufLeft++ = leftByte[iHivelyBufPos];
            *bufRight++ = rightByte[iHivelyBufPos];
            iHivelyBufPos++;
            left--;
            readsize++;
        }
    }
    
    return readsize;
}

- (void) setStereoSeparation:(NSInteger)value {
    if (currentHVLtune == nil) {
        return;
    }
    int sep = ceil(value/100 * 4);
    currentHVLtune->ht_defstereo = sep;
    //no effect during playback.
}

- (void) setInterpolationFilterLength:(NSInteger)value {
    //nop
}

- (int) currentPosition {
    if (!currentHVLtune) {
        return 0;
    }
    int playtime = currentHVLtune->ht_PlayingTime;
    curpos = CGFloat(playtime) / currentHVLtune->ht_SpeedMultiplier / 50;
    return curpos;
}

- (int) moduleLength {
    return modlen/1000;
}

- (void) setCurrentPosition:(int)newPosition {
    if (!currentHVLtune) {
        return;
    }
    curpos = hvl_Seek(currentHVLtune, newPosition * 1000);
}

- (NSArray*) getSamples
{
    if (!currentHVLtune) {
        return @[];
    }
    
    int samples = currentHVLtune->ht_InstrumentNr;
    NSMutableString* infoStr = [[NSMutableString alloc] init];
    NSMutableArray* sampleArray = [NSMutableArray new];
    @try {
        for (int i = 0; i<samples; i++) {
            
            const char* sampleName = currentHVLtune->ht_Instruments[i].ins_Name;
           NSString* str = [[NSString alloc] initWithUTF8String:sampleName];
            if  (str) {
                [sampleArray addObject:str];
            }
        }
    } @catch (NSException *exception) {
        infoStr = [@"Could not get info for module" mutableCopy];
    } @finally {
    }
    return sampleArray;
}

- (NSArray<NSString*>*) getInstruments
{
    return [self getSamples];
}

- (NSInteger) numberOfChannels {
    if (!currentHVLtune) {
        return 4;
    }
    return currentHVLtune->ht_Channels;
}

- (NSInteger) volumeOnChannel:(NSInteger)channel {
    if (!currentHVLtune) {
        return 0;
    }
    CGFloat floatGain = CGFloat(currentHVLtune->ht_Voices[channel].vc_AudioVolume);
    
    //map the gain to 0-100 scale to match with what openMPT does
    int gain = floatGain * CGFloat(100.0/64.0);
    return gain;
}

- (bool) loadModule:(NSString *)path type:(NSString*) type {
  currentHVLtune = hvl_LoadTune((TEXT*)[path UTF8String], 44100, hvlStereoSeparation );
  if (currentHVLtune == nil) {
    return false;
  }
  
  curpos = 0;
  modlen = hvl_GetPlayTime(currentHVLtune);
  
  
  hvl_InitSubsong(currentHVLtune, 0);
  return true;
}

@end
