//
//  UADEReplayer.m
//  SamplePlayer
//
//  Created by Aleksi Sitomaniemi on 27.8.2022.
//  Copyright © 2022 4champ. All rights reserved.
//

#import "UADEReplayer.h"

static volatile int uadethread_running;

#include <uade/uadeipc.h>
#include <uade/uadecontrol.h>
#include <uade/uadeconf.h>
#include <uade/uade.h>
#include <sys/socket.h>
#include "uae.h"
#include <dirent.h>

@implementation UADEReplayer{
    struct uade_config* cfg;
    struct uade_state* ustate;
    
    int16_t* leftByte;
    int16_t* rightByte;
    char uadescorename[PATH_MAX];
    char basedir[PATH_MAX];
    int fds[2];
}

@synthesize name = _name;

+ (NSArray<NSString*>*)supportedFormats {
    return @[@"AAM", // ArtAndMagic,
             @"ABK", // Amos ABK
             @"ADPCM",// ADPCM_mono
             @"ADSC", // AudioSculpture
             //@"AHX" // -> HivelyPlayer
             @"AMC", // A.M. Composer
             @"AON", @"AON4", @"AON8", // Art of noise
             @"APS", // AProSys
             @"ASH", // Ashley Hogg
             @"AST", // ActionAmics
             @"BD", @"BDS", // Ben Daglish
             @"BFC", @"BSI", // Future Composer (BSI)
             @"BSS", // BeathovenSynthesizer
             @"BP", @"BP3",  // SoundMon
             @"BYE", // Andrew Parton
             @"CIN", // Chinemaware
             @"CORE",// Core Design
             @"DB",@"DIGI", // DigiBooster
             @"DH",  // David Hanney
             @"DL",@"DL_DELI",@"DLN",  // Dave Lowe
             @"DM1", @"DM2", @"DLM1", @"DLM2", // Delta Music
             @"DMU", @"DMU2", @"MUG", @"MUG2", // Mugician
             //@"DIGI" OpenMPT
             @"DNS", // DynamicSynthesizer
             @"DSC", // DigitalSonixChrome
             @"DSS", // DigitalSoundStudio
             @"DSR", // Desire
             @"DUM", // Infogrames
             @"DW",  // David Whittaker
             @"DZ",  // DariusZendeh
             @"EA", @"MG", // EarAche
             @"EMOD", @"QC", // Quadra Composer
             @"EMS", @"EMSV6", // EMS
             @"EX",  // FashionTracker
             @"FC", @"FC13", @"FC14", @"FC3", @"FC4", // Future Composer
             @"FC-M",// FC-M Packer
             @"FP",  // Future Player
             @"FRED",// Fred
             @"FUZZ",// Fuzzac Packer
             @"GLUE", @"GM",// GlueMon
             @"GRAY",// Fred Gray
             @"GMC", // GMC
             @"HD",  // Howie Davies
             @"HIP", @"SOG", @"MCMD",  // Jochen Hippel
             @"HIP7", @"S7G", // Jochen Hippel 7V
             @"HST", // Jochen Hippel ST
             @"HOT", // Anders Øland
             @"IMS", // ImageMusicSystem
             @"IS",  // In Stereo
             @"IS20",// In Stereo 2
             @"JAM", @"JC", // JamCracker
             @"JCB", @"JCBO", // Jason Brooke
             @"JD", @"DODA", //Special FX
             @"JO",  // Jesper Olsen
             @"JP", @"JPN", @"JPND", // Jason Page
             @"JPO", @"JPOLD", // Steve Turner
             @"JMF", // Janko Mrsic-Flogel
             @"JT", @"MON_OLD", // Jeroen Tel
             @"KH",  // Kris Hatlelid
             @"KIM", // Kim Christensen
             @"KRIS",// ChipTracker
             @"LME", // LegglessMusicEditor
             @"MA", // Music Assembler
             @"MAX", // Maximum Effect
             @"MC", @"MCR", @"MCO", // Major Coooksey
             @"MCMD",
             @"MD", // Mike Davies
             @"MMDC",
             @"MM4", @"MM8", // Music Maker
             @"MMS", @"SFX20", // MultiMedia Sound
             @"MED", @"MMD0", @"MMD1", @"MMD2", @"OCTAMED", // Octamed
             @"MK2", @"MKII", // MarkII
             @"MXTX",// Maxtrax
             @"MCMD",// MCMD
             @"MIDI",// MIDI-loriciel
             //@"ML",@"Ml"  // MusicLine Editor - disabled since ML player does not handle file paths longer than 127 chars.
             @"MOK", // Silmarilis
             @"MON", // ManiacsOfNoise
             @"MSO", // Medley
             @"MTP2", @"HN", @"THN", // Major Tom's Player
             @"MW", @"AVP", // Martin Walker
             @"NTP", // NovoTrade Packer
             @"OKT", // Oktalyzer
             @"ONE", // OnEscapee
             @"OSP", // Synth Pack
             @"PAT", // Paul Tonge
             @"PAP", // Pierre Adane
             @"PM20",// Promizer
             @"PM40",// Promizer
             @"PN",  // Pokey Noise
             @"POWT", @"PT", // Laxity
             @"PRT", // Pretracker
             @"PRU1",// ProRunner
             @"PRU2",// ProRunner
             @"PS",  // Paul Shields
             @"PSA", // ProfessionalSoundArtists
             @"PSF", // SoundFactory
             @"PUMA",// PumaTracker
             @"PVP", // PeterVerswyvelen
             @"RIFF",// Riff Raff
             @"RJ", @"RJP", // Richard Joseph
             @"RH", @"RHO", // Rob Hubbard
             @"SC", @"SCT", // Sound Control
             @"SCN", @"S-C", // Sean Connolly
             @"SA", @"SONIC",  // Sonic Arranger
             @"SB",  // SteveBarrett
             @"SAS", // SpeedyA1System
             @"SCR", // Sean Conran
             @"SDR", // Synthdream
             @"SFX", @"SFX13", // Sound-FX
             @"SID1", @"SID2", @"SMN", // SidMon 1,2
             @"SJS", // SoundPlayer
             @"SM", @"SM1", @"SM2", @"SM3", @"SMPRO", // SoundMaster
             @"SNK", // Paul Summers
             @"SNG", // ZoundMonitor
             @"SNX", @"SMUS", @"TINY", // Sonix Music Driver
             @"SPL", // Sound Programming Language
             @"SS", // SpeedySystem
             @"ST", @"SYNMOD", // SynTracker
             @"SUN", // SunTronic
             @"SYN", // Synth
             @"SYNMOD", // Syntracker
             @"TCB", // TCB Tracker
             @"THM", // Thomas Hermann
             @"TMK", // Time Tracker
             @"TF",  // Tim Follin
             @"TMFX", @"TMFX1.5", @"TFHD1.5", @"TMFX7V", @"TFHD7V", @"TMFXPRO", @"MDST", @"MDAT",// TFMX
             @"TME", // TheMusicalEnlightement
             @"TPU", // Dirk Bialluch
             @"TRC", @"TRO", @"DP", @"TRONIC", // Tronic
             @"TWO", // NTSP-System
             @"TW",  // SoundImages
             @"UFO", @"MUS", // UFO
             @"VSS", // Voodoo Supreme Synthesizer
             @"WB",  // Wally Beben
             @"YM",  // YM-2149,
             @"QPA", @"SQT", @"QTS", // Quartet - PSG - ST
    ];
}

// Handle main UADE thread (amiga emu)
-(void) uadeThread:(NSArray*)params {
    uadethread_running = 1;
    NSLog(@"UADECore enter");
    @autoreleasepool {
        const char* inParam = [[params objectAtIndex:0] UTF8String];
        const char* outParam = [[params objectAtIndex:1] UTF8String];
        
        [[NSThread currentThread] setThreadPriority:0.9f];
        const char *argv[5] = {"uadecore", "-i", inParam, "-o", outParam};
        uadecore_main(5,(char**)argv);
    }
    NSLog(@"UADECore exit");
    uadethread_running=0;
}

- (UADEReplayer*) init {
    self = [super init];
    if (self) {
        _name = @"UADE";
        NSString* bu = [NSBundle mainBundle].resourcePath;
        NSString* bd = [bu stringByAppendingString:@"/Frameworks/uade_ios.framework/UADERes.bundle"];
        
        strcpy(basedir, [bd UTF8String]);
        struct uade_config *cfg = uade_new_config();
        sprintf(uadescorename, "%s/score",basedir);
        uade_config_set_option(cfg, UC_VERBOSE, [@"1" UTF8String]);
        uade_config_set_option(cfg, UC_BASE_DIR, basedir);
        uade_config_set_option(cfg, UC_SCORE_FILE, uadescorename);
        ustate = [self create_state:cfg];
        free(cfg);
        
    }
    return self;
}

- (void)dealloc {
    NSLog(@"UADEReplayer deallocated");
}

- (void) cleanup {
    uae_quit();
    uade_stop(ustate);
    uade_cleanup_state(ustate);
    while(uadethread_running) {
    }
    quit_program = 0;
    close(fds[0]);
    close(fds[1]);
}

/// Create UADE state. Implementation is identical with `uade_new_state` provided by libuade,
/// with the exception that uadecore is spawned in a thread, not a separate process.
/// @param extraconfig any client-specific configuration
- (struct uade_state*) create_state:(struct uade_config*)extraconfig {
    struct uade_state *state;
    DIR *bd;
    char path[PATH_MAX];
    const char *basedir;
    
    state = calloc(1, sizeof *state);
    if (!state)
        return NULL;
    
    basedir = NULL;
    if (extraconfig != NULL && extraconfig->basedir_set)
        basedir = extraconfig->basedir.name;
    
    if (!uade_load_initial_config(state, basedir)) {
        NSLog(@"Config not loaded");
        return nil;

    }
    if (extraconfig) {
        state->extraconfig = *extraconfig;
    }
    else {
        uade_config_set_defaults(&state->extraconfig);
    }
    
    state->config = state->permconfig;
    uade_merge_configs(&state->config, &state->extraconfig);
    
    uade_load_initial_song_conf(state);
    //load_content_db(state);
    
    bd = opendir(state->config.basedir.name);
    if (bd == NULL) {
        NSLog(@"Could not access dir %s", state->config.basedir.name);
        return nil;
    }
    closedir(bd);
    
    uade_config_set_option(&state->config, UC_UADECORE_FILE,
                           UADE_CONFIG_UADE_CORE);
        
    snprintf(path, sizeof path, "%s/uaerc", state->config.basedir.name);
    uade_config_set_option(&state->config, UC_UAE_CONFIG_FILE, path);
    
    uade_merge_configs(&state->config, &state->extraconfig);
    
    if (access(state->config.uae_config_file.name, R_OK)) {
        NSLog(@"Could not read uae config file: %s", state->config.uae_config_file.name);
        return nil;
    }
    
    // set up ipc
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, fds)) {
        NSLog(@"Cannot create socket pair");
        return nil;
    };
    
    NSArray* params = @[[NSString stringWithFormat:@"%d", fds[0]], [NSString stringWithFormat:@"%d", fds[0]]];
    [NSThread detachNewThreadSelector:@selector(uadeThread:) toTarget:self withObject:params];
    
    uade_set_peer(&state->ipc, 1, fds[1], fds[1]);
    if (uade_send_string(UADE_COMMAND_CONFIG, state->config.uae_config_file.name, &state->ipc)) {
        NSLog(@"Can not send config name: %s", strerror(errno));
        return nil;
    }
    
    return state;
}

- (bool)loadModule:(NSString *)path type:(NSString *)type {
    
    NSData* data = [[NSFileManager defaultManager] contentsAtPath:path];
    if (!data) return false;
    
    
    uade_stop(ustate);
    
    if (!uade_is_our_file_from_buffer([path UTF8String], data.bytes, data.length, ustate)) {
        NSLog(@"Not our file");
        return false;
    }
    uade_play_from_buffer([path UTF8String], data.bytes, data.length, 0, ustate);
    
    return true;
}

- (void)setCurrentPosition:(int)newPosition {
}

- (void)setInterpolationFilterLength:(NSInteger)value {
    if (value == 0 ) {
        uade_config_set_option(&ustate->config, UC_FORCE_LED_ON, nil);
        uade_set_filter_state(ustate, 1);
    } else {
        uade_config_set_option(&ustate->config, UC_FORCE_LED_OFF, nil);
        uade_set_filter_state(ustate, 0);
    }
}

- (void)setStereoSeparation:(NSInteger)value {
    float newValue = (float)value/100.0*2.0; // (parameter range 0-100, uade range 0-2)
    uade_effect_pan_set_amount(ustate, newValue);
}

- (int)currentPosition {
    if(ustate) {
        const struct uade_song_info *info = uade_get_song_info(ustate);
        int bytespersecond = UADE_BYTES_PER_FRAME *
                         uade_get_sampling_rate(ustate);
        int64_t playTime = (info->subsongbytes) / bytespersecond;
        return (int)playTime;
    }
    return 0;
}

- (NSArray<NSString *> *)getInstruments {
    return @[];
}

- (NSArray<NSString *> *)getSamples {
    const struct uade_song_info *info = uade_get_song_info(ustate);
    NSString* playerName = [[NSString stringWithUTF8String: info->playerfname] componentsSeparatedByString:@"/"].lastObject;
    return @[@"UADE Player:", playerName];
}

- (NSString*) replayerName {
    return @"UADE";
}

- (int)moduleLength {
    if(ustate) {
        const struct uade_song_info *info = uade_get_song_info(ustate);
        return ustate->song.info.duration;
    }
    return 0;
}

- (NSInteger)numberOfChannels {
    return 4;
}

- (NSInteger)volumeOnChannel:(NSInteger)channel {
    return 1;
}

- (int)readFrames:(size_t)count bufLeft:(int16_t *)bufLeft bufRight:(int16_t *)bufRight {
    int16_t buf[count*2];
    ssize_t retVal = uade_read(&buf, sizeof buf, ustate);

    struct uade_notification n;
    // Check for song end
    if (uade_read_notification(&n, ustate)) {
        bool atEnd = n.type == UADE_NOTIFICATION_SONG_END;
        uade_cleanup_notification(&n);
        if(atEnd) {
            return 0;
        }
    }

    if(retVal<0) {
        NSLog(@"Error reading data");
        return 0;
    }
    for(int ptr=0; ptr<(count*2); ptr+=2) {
        *bufLeft++ = buf[ptr];
        *bufRight++ = buf[ptr+1];
    }
    return (int)retVal;
}

@end
