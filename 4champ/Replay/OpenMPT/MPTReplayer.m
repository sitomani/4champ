//
//  MPTReplayer.m
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import "MPTReplayer.h"
#import "libopenmpt.h"

@implementation MPTReplayer {
  openmpt_module* currentOMPTFile;
}

- (bool) loadModule:(NSString *)path {
  NSData* data = [[NSFileManager defaultManager] contentsAtPath:path];
  if (!data) return false;
  
  currentOMPTFile = openmpt_module_create_from_memory2(data.bytes, (uint32_t)data.length, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  if (!currentOMPTFile) return false;
  return true;
}

- (void)dealloc {
  if (currentOMPTFile) {
    openmpt_module_destroy(currentOMPTFile);
  }
}

- (int) readFrames:(size_t)count bufLeft:(int16_t*)bufLeft bufRight:(int16_t*)bufRight {
  return (int)openmpt_module_read_stereo(currentOMPTFile, (int32_t)44100, count, bufLeft, bufRight);
}

- (void) setStereoSeparation:(NSInteger)value {
  int newValue = value * 2; // (parameter range 0-100, mpt range 0-200)
  openmpt_module_set_render_param(currentOMPTFile, OPENMPT_MODULE_RENDER_STEREOSEPARATION_PERCENT, (int32_t)newValue);
}

- (int) currentPosition {
  int cp = openmpt_module_get_position_seconds(currentOMPTFile);
  return cp;
}

- (int) moduleLength {
  int lenInSec = openmpt_module_get_duration_seconds(currentOMPTFile);
  return lenInSec;
}

- (void) setCurrentPosition:(int)newPosition {
  openmpt_module_set_position_seconds(currentOMPTFile, newPosition);
}

- (NSArray*) getSamples
{
  if (!currentOMPTFile) {
    return @[];
  }
  
  int samples = openmpt_module_get_num_samples(currentOMPTFile);
  NSMutableString* infoStr = [[NSMutableString alloc] init];
  NSMutableArray* sampleArray = [NSMutableArray new];
  @try {
    for (int i = 0; i<samples; i++) {
      const char* sampleName = openmpt_module_get_sample_name(currentOMPTFile, i);
      NSString* str = [[NSString alloc] initWithUTF8String:sampleName];
      if (str) {
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
  if (!currentOMPTFile) {
    return @[];
  }
  
  int samples = openmpt_module_get_num_instruments(currentOMPTFile);
  NSMutableString* infoStr = [[NSMutableString alloc] init];
  NSMutableArray* sampleArray = [NSMutableArray new];
  @try {
    for (int i = 0; i<samples; i++) {
      const char* sampleName = openmpt_module_get_instrument_name(currentOMPTFile, i);
      NSString* str = [[NSString alloc] initWithUTF8String:sampleName];
      if (str) {
        [sampleArray addObject:str];
      }
    }
  } @catch (NSException *exception) {
    infoStr = [@"Could not get info for module" mutableCopy];
  } @finally {
  }
  return sampleArray;
}

- (NSInteger) numberOfChannels {
  return openmpt_module_get_num_channels(currentOMPTFile);
}

- (NSInteger) volumeOnChannel:(NSInteger)channel {
  CGFloat vol =  openmpt_module_get_current_channel_vu_mono(currentOMPTFile, (int32_t)channel);
  NSInteger volInt = vol * 100;
  return volInt;
}

@end
