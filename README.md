# 4champ
4champ is an app that provides a mobile interface to [Amiga Music Preservation](http://amp.dascene.net) database on iOS devices.

Many of us who grew up with computers in the 80's and early 90's remember Amiga and particularly its mind-blowing audio capabilities which were unrivaled at the era. Amiga inspired a lot of musicians to 
produce a vast amount of compositions, or modules as they were called. [Amiga Music Preservation](http://amp.dascene.net) is a non-profit 
project that collects anything related to Amiga music production. AMP database boasts almost 150 000 modules, 4champ app is your direct access to all that goodness.

### Development journal

In this repository I'm working on rewriting the app that originally was released in AppStore in 2012, and since late 2017 not available in AppStore any more 😞. You can read more about the history of the app and follow the rewrite process on the development journal that I created for this project: [sitomani.github.io/4champ](https://sitomani.github.io/4champ).

### Main Features and their current status in this repository
* Radio: You can listen to a random set of tunes from the whole collection of over 150000 modules, or stream from the head, i.e. the most recently added ones. You can also play from the local collection from set of modules that you've selected to keep for offline mode.
* Search (search the AMP database by module, composer, group name or sampletexts): Implemented in October 2018.
* Playlists (build your own playlists): TBD
* Local Collection (store modules locally): Persistent storage for off-line listening of modules implemented June 2019.
* Settings (control stereo separation etc): Stereo separation setting implemented in November 2018.

### Dependencies

##### A. Carthage 
4champ is built with a number of dependencies. Part of them are configured through a Cartfile, so you will need to have [Carthage](https://github.com/Carthage/Carthage) installed to prepare these. 

##### B. Frameworks configured in Cartfile
**[Alamofire](https://github.com/Alamofire/Alamofire)** is used for network comms.
**[GzipSwift](https://github.com/1024jp/GzipSwift)** is used to unpack the gzipped module files.
**[SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver)** is used for logging.

To build these, run `carthage bootstrap --platform iOS` in the root folder of the project.

##### C. Module Playback Libraries

4champ uses [libOpenMPT](https://github.com/OpenMPT/openmpt) and [Hivelytracker](https://github.com/pete-gordon/hivelytracker) for module playback. 

**Hivelytracker** replayer code is included in [4champ/Replay/Hively](4champ/replay/hively) folder, so it will be built automatically when you build xcode projects in this repository, no further actions needed. 

**LibOpenMPT** repo does not build for iOS without small tweaks, which I have done on my own fork of the lib at https://github.com/sitomani/openmpt. In order to build it for use in connection with 4champ and the SamplePlayer demo app in this repository, you will need to take the following steps:

1. Make sure you have [Premake5](https://premake.github.io/download.html) available and in the path before proceeding. 
2. Clone https://github.com/sitomani/openmpt at same folder where you cloned this repository at (the repositories will be subfolders in same level in the directory tree).
3. Navigate in terminal to the openmpt repository root folder
4. Execute `iOS_premake.sh` to generate the xcode project files for libopenmpt.
5. Launch Xcode and open generated libopenmpt-small.xcworkspace file at `build/xcode/` folder in the openmpt repository
6. Add the three included subprojects to *Link binary with libraries* build phase (you should find `openmpt-miniz.lib`, `openmpt-minimp3.lib` and `openmpt-stb_vorbis.lib` there)
7. Get back to terminal, and execute `iOS_build.sh` to build the fat lib file for iOS use. 
8. The library file `libopenmpt-small.a` will be found under openmpt repository root, and 4champ repository projects are configured to find it there, provided that you have cloned this repository and openmpt repository in the same folder.

I plan to have a deeper look at openmpt project file generation with Genie at some point, in order to reduce the number of steps above. For the time being, the project is generated using premake, which does not fit that well when targeting iOS and one must do some housekeeping after premake run in order to build a static lib properly.

### Building the app

After setting up the dependencies you can open 4champ.xcodeproj in Xcode and build the application. On simulator you can run the app without any further changes.

In order to run the app on device, you will need to replace the bundle identifier 'com.boogie.fourchamp' with another id, because Xcode will create a development certificate on the fly for the device build and same bundle identifier cannot be present in multiple certificates.

The Xcode generated developer certificate will only be valid for 7 days, which means that you'll need to reinstall from Xcode every week to use the app. To work around this nuisance, you can create an ad hoc distribution certificate for signing the app in Apple Developer Center if are a member in Apple Developer Program.

### License

The code in this repository is copyright © Aleksi Sitomaniemi 2018 and licensed under [MIT license](LICENSE), **except** for HivelyTracker replay routine code which is by licenced under [BSD-3](4champ/replay/hively/LICENSE) by [Pete Gordon](https://github.com/pete-gordon).

Module files included under *SamplePlayer* test project that I've used to verify the the replay routine are work of the original authors:

*1st_intro.mod* by florist (Aleksi Sitomaniemi - yup that's me!)<br/>
*all.in.eightchannels.xm* by Daze (Patrick Glasby-Baldwin)<br/>
*mislead.ahx* by Pink (Manfred Linzner)<br/>
*peanuts!.hvl* by Lavaburn (Dale Whinham)<br/>
