//
//  UADEReplayer.h
//  SamplePlayer
//
//  Created by Aleksi Sitomaniemi on 27.8.2022.
//  Copyright © 2022 4champ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Replay.h"

@interface UADEReplayer : NSObject<ReplayControl, ReplayInformation, ReplayerStream>

@end
