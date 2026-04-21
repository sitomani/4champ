# 4champ

4champ is an app that provides a mobile interface to [Amiga Music Preservation](http://amp.dascene.net) database on iOS devices.

[![appstore badge](docs/images/appstore_badge.png "click to open page in appstore")](https://apps.apple.com/app/4champ/id578311010)

![application screenshots](docs/images/screens.png "4champ search and radio screens")

Many of us who grew up with computers in the 80's and early 90's remember Amiga and particularly its mind-blowing audio capabilities which were unrivaled at the era. Amiga inspired a lot of musicians to
produce a vast amount of compositions, or modules as they were called. [Amiga Music Preservation](http://amp.dascene.net) is a non-profit
project that collects anything related to Amiga music production. AMP database boasts over 160 000 modules, 4champ app is your direct access to all that goodness.

If you're interested to test new features when they're getting implemented before official App Store releases, you can join the beta program at https://testflight.apple.com/join/j1yhaJQ1.

You can read more about the history of the app and follow my work on the app at the development journal that I created for this project: [sitomani.github.io/4champ](https://sitomani.github.io/4champ).

You can also follow the 4champ accounts on [X (4champ_app)](https://x.com/4champ_app) or [Mastodon (@4champ@mastodon.social)](https://mastodon.social/@4champ) to stay up to date on what's happening with the app.

### Main Features of the app

- Search: Search the AMP database by module, composer, group name or sampletexts.
- Radio: You can listen to a random set of tunes from the whole collection of over 150000 modules, or stream from the head, i.e. the most recently added ones. You can also play from the local collection from set of modules that you've selected to keep for offline mode and build your own custom channels through from search results.
- Playlists: Build your own playlists from modules.
- Local Collection: store modules locally - persistent storage for off-line listening of modules.
- Settings: Control stereo separation, sound interpolation etc.
- Import modules from filesystem (local / cloud / network)
- CarPlay support

### Dependencies

#### Optional dependencies

The project has build phase for running **[SwiftLint](https://github.com/realm/SwiftLint)** which will be skipped if you do not have swiftlint installed, so you do not need it to build the project.

#### Module Playback Libraries

**Hivelytracker** replayer code is included in [4champ/Replay/Hively](4champ/replay/hively) folder, so it will be built automatically when you build xcode projects in this repository, no further actions needed.

**LibOpenMPT** repo does not build for iOS without small tweaks, which I have done on my own fork of the lib at https://github.com/sitomani/openmpt. 

**UADE** likewise, the UADE framework implementation is my port for iOS at https://gitlab.com/sitomani/uade-ios.

The **LibOpenMPT** and **UADE** are configured as submodules in this repository. When you clone this repo, you need to build the libraries first to build 4champ. Run the following shell script to get a working build:

```shell
./build_deps.sh
```
this will prepare the frameworks that 4champ project expects to be found in this folder.

### Building the app

After setting up the dependencies you can open 4champ.xcodeproj in Xcode and build the application. On simulator you can run the app without any further changes.

In order to run the app on device, you will need to replace the bundle identifier with another id, because Xcode will create a development certificate on the fly for the device build and same bundle identifier cannot be present in multiple certificates.

The Xcode generated developer certificate will only be valid for 7 days, which means that you'll need to reinstall from Xcode every week to use the app. To work around this nuisance, you can create an ad hoc distribution certificate for signing the app in Apple Developer Center if you are a member of the Apple Developer Program.

### License

The code in this repository is copyright © Aleksi Sitomaniemi and dual licensed under [GPL](LICENSE.GPL) and [MIT](LICENSE.MIT), **except** for HivelyTracker replay routine code which is by licenced under [BSD-3](4champ/replay/hively/LICENSE) by [Pete Gordon](https://github.com/pete-gordon).

Module files included under _SamplePlayer_ test project that I've used to verify the the replay routines are work of the original authors:

_1st_intro.mod_ by florist (Aleksi Sitomaniemi - yup that's me!)<br/>
_all.in.eightchannels.xm_ by Daze (Patrick Glasby-Baldwin)<br/>
_jinx.jam_ by Jeff (Ingmar Hänsch)<br/>
_mislead.ahx_ by Pink (Manfred Linzner)<br/>
_octagroove.ml_ by Ziphoid (John Carehag)<br/>
_peanuts!.hvl_ by Lavaburn (Dale Whinham)<br/>
_sweet_dreams.aon_ by Toodeloo (Anders Nilsson)<br/>
