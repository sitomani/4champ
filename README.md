# 4champ
4champ is an app that provides a mobile interface to [Amiga Music Preservation](http://amp.dascene.net) database on iOS devices.

Many of us who grew up with computers in the 80's and early 90's remember Amiga and particularly its mind-blowing audio capabilities which were unrivaled at the era. Amiga inspired a lot of musicians to 
produce a vast amount of compositions, or modules as they were called. [Amiga Music Preservation](http://amp.dascene.net) is a non-profit 
project that collects anything related to Amiga music production. AMP database boasts over 140 thousand modules, 4champ app is your direct access to all that goodness.

### Development journal

In this repository I'm working on rewriting the app that originally was released in AppStore in 2012, and since late 2017 not available in AppStore any more 😞. You can read more about the history of the app and follow the rewrite process on the development journal that I created for this project: [sitomani.github.io/4champ](https://sitomani.github.io/4champ).

### Dependencies
4champ uses[libOpenMPT](https://github.com/OpenMPT/openmpt) and [Hivelytracker](https://github.com/pete-gordon/hivelytracker) for module playback. 

**Hivelytracker** replayer is included here, so it will be built automatically when you build xcode projects in this repository, no actions needed. 

**LibOpenMPT** repo does not build for iOS without small tweaks, which I have done on my own fork of the lib at https://github.com/sitomani/openmpt. In order to build it for use in connection with 4champ and the SamplePlayer demo app in thsi repository, you will need to take the following steps:

1. Clone https://github.com/sitomani/openmpt at same folder where you cloned this repository at (the repositories will be subfolders in same level in the directory tree).
2. Navigate in terminal to the openmpt repository root folder
3. Execute `iOS_premake.sh` to generate the xcode project files for libopenmpt.
4. Launch Xcode and open generated libopenmpt-small.xcworkspace file at `build/xcode/` folder in the openmpt repository
5. Add the three included subprojects to *Link binary with libraries* build phase (you should find `openmpt-miniz.lib`, `openmpt-minimp3.lib` and `openmpt-stb_vorbis.lib` there)
6. Get back to terminal, and execute `iOS_build.sh` to build the fat lib file for iOS use. 
7. The library file `libopenmpt-small.a` will be found under openmpt repository root, and 4champ repository projects are configured to find it there, provided that you have cloned this repository and openmpt repository in the same folder.

I plan to have a deeper look at openmpt project file generation with Genie at some point, in order to reduce the number of steps above. For the time being, the project is generated using premake, which does not fit that well when targeting iOS and one must do some housekeeping after premake run in order to build a static lib properly.

### License

The code in this repository is copyright © Aleksi Sitomaniemi 2018, and licensed under [MIT license](LICENSE). 

Module files included under *SamplePlayer* test project that I've used to verify the the replay routine are work of the original authors::

*1st_intro.mod* by florist (Aleksi Sitomaniemi - yup that's me!)<br/>
*all.in.eightchannels.xm* by Daze (Patrick Glasby-Baldwin)<br/>
*mislead.ahx* by Pink (Manfred Linzner)<br/>
*peanuts!.hvl* by Lavaburn (Dale Whinham)<br/>