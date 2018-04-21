//
//  MPTReplayer.h
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Replay.h"

@interface MPTReplayer: NSObject<ReplayControl, ReplayInformation, ReplayerStream>

@end
