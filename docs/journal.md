# 4champ Development Journal

### 1-31 October 2022 Some esoteric formats anyone?

For the Hacktoberfest campaign I took up the challenge to finalise my integration of UADE replayer to 4champ. A big body of work had to first be done on the UADE side. 

I had earlier forked the main UADE repository to https://gitlab.com/sitmoani/uade-ios, and done quick modifications to get the code to build first for macOS. I started out from latest release of UADE, i.e. version 3.02. Building UADE requires a couple of dependencies, namely Heikki Orsila's `bencodetools` and `libao`. The first was a breeze to get from gitlab and build, but for the latter I tried first the suggested homebrew install which went all right, but the package was either missing headers, or they were in some off-path location. To iron the bumps out I ended up cloning the [libao repository](https://github.com/xiph/libao) and building it from sources. This way I got also the headers properly into `/usr/local/include/ao`.

At first I put together a Xcode project for creating a static framework as with OpenMPT. It seemed rather straightforward to just add all the source files in a project and build. I used my SamplePlayer test app to verify the build first. I was facing a linker error, there was no implementation for some extern structs declared in `newcpu.c`. It took a while to figure out that the `Makefile` for uadecore has a set of intermediate files generated during the build process, which have to be part of the build for those structs to have an implementation. Once I got that straight, my testbed implementation started to play back test songs. So far so good.

Static framework was not suitable for my purposes though, as for UADE to run it is necessary to have the amiga binaries available as resources, which I wanted not to bring into 4champ repository directly. Dynamic framework it was then, and after stumbling through the setup for quite some time, I managed to get it down so that I can package the UADE implementation into `uade_ios.xcframework` that carries the lib AND the resources needed to run the amiga emulation, in a nice Xcode compatible bundle. Hooray!

During the process I also found a bug in the UADE, it would not play back MusicLine Editor format tracks if the file path to the module was longer than 127 characters. In case of iOS apps, the sandbox paths tend to be long enough to cross this boundary. Luckily vast majority of formats work also with longer paths. ML format support will be activated later when the bug gets a fix in UADE.

The UADE library comes licensed as parts GPL, parts LGPL and then some custom licenses for the amiga player routines. In practice, since 4champ now links to UADE, it gets tainted by the GPL license and now is GPL licensed as well as a whole. MIT license stays in, alongisde with GPL. I am aware of the debate around whether or not AppStore is compatible with GPL - and then again, there is a multitude of really popular apps that are GPL licensed and available in the app store. So I'm boldly going the same route with [Signal](https://github.com/signalapp/Signal-iOS), [ProtonMail](https://github.com/ProtonMail/ios-mail) and [VLC](https://github.com/videolan/vlc-ios).

### 27 Oct 2021 We need to go back

A couple of months ago 4champ got a review in AppStore where the reviewer stated that the only thing he/she was missing was a way to see the previously played tracks when listening to 4champ radio. I had thought about something similar myself, and this gave me a good motivation kick to put it next in the backlog. Well now it is implmented in the app!

### 10 Aug 2021 Modules, modules everywhere

It has been requested by users occasionally if it would be possible to import your own modules to 4champ. Well now it is! 4champ now works as a share target for the supported module types, or if you want to get a bunch of files in at once, you can trigger module import from either local modules tab, or playlist tab. After the files have been imported, you can assign a composer name in case you'd like.

The data model changes done for the import are deliberately done in a way that could serve for additional module database support (e.g. [modarchive.org](https://modarchive.org/) or [Modland](https://www.exotica.org.uk/wiki/Special:Modland)). There is a lot of common modules to these, but each service hosts a set of modules that are not found in others. It would be interesting to jump back into node.js after quite some years to implement this. Stay tuned! :)

### 15 May 2021 Goodbye Carthage, Hello Swift Package Manager

Thought it would be time to give [Swift Package Manager](https://swift.org/package-manager/) a try. As all my three dependencies are available thru SwiftPM the switchover was smooth & effortless <3.

### 26 December 2020 Small steps

Quite some year, this one. Without touching the global events, just a bit of a summary of what happened lately for 4champ. In November, I pushed out a small update to the app that enabled reviewing through the About page. The app will also ask for a review after receiving a bit of trigger actions first, using the iOS review mechanics, so it won't be bugging you too often.

For the last actions this year I managed to rebuild the libopenmpt from the latest sources, and got the updgrade out for beta testing just in time before AppStore holiday break! Now I'm cleaning up here and there and will also be posting about my progress with the libopenmtp iOS build on the OpenMPT forum. Also, updating the main repository README to reflect the changes in building the lib.

### 3 May 2020 Back in the AppStore!

It's been long time coming, and the time has finally come. 4champ is now again listed at the AppStore for iOS devices. It's been a really interesting four weeks since I started the TestFlight beta first invite only, and from Easter on with public link.

During the beta period, I got a number of improvement suggestions, crash reports and comments that proved really helpful in getting the app finalised for release. 5 hours after I published the app, I got the first 5 star review - which makes me really glad and proves that my efforts with this project have not been void.

Now, get your installs at [https://apps.apple.com/app/4champ/id578311010](https://apps.apple.com/app/4champ/id578311010) and don't forget to rate the app if you like it!

### 11 Apr 2020 Easter Eggs Anyone?

Thanks to the 2020 coronavirus pandemic and isolation I've been fighting boredom by finally writing the last missing big feature for the app, the playlists support. The playlist handling came out a bit differently as compared to the original app release where all modules got added to a playlist when listened once, which resulted in a number of clunky features to counteract the behaviour. In my opinion, it's now more in line with common sense.

With the playlists, I also had the chance to experiment a bit with SwiftUI. The playlists related views are implemented mostly in SwiftUI, but as I went on to learn the ropes with the new descriptive UI language, I noticed that it's not quite ready for full showtime yet. Refer to my Twitter feed for some specific findings behind this opinion.

And yes, the build from this repository is also now in Testflight Beta! The nice folks from Amiga Music Preservation have helped me out get the Apple third party content usage issue solved, and I'm anticipating an official AppStore release in the forthcoming weeks. Stay tuned, and if you'd like to have a go with the beta version, drop me a pm in Twitter (https://twitter.com/4champ_app).

### 05 Feb 2020 New formats for free

While working on the datascience section of the 4champ project, I noticed that the OpenMPT player can replay
OK (alternate extension for OKT) and DTM (Digital Tracker/Digital Home Studio). Added these formats to
the supported formats list, and now there's 28 more modules that you can listen to on 4champ. Cheers!

### 04 Jan 2020 Brilliant New Year!

To kick off 2020 with something a bit different, I've added a data science section
under the Github pages area along with this development journal. I will be posting
observations and analytics on the 4champ / Amiga Music Preservation database along
the way in the [DataScience Section](2020ds/ds_toc.md). To get notified on updates,
star this repository for notifications, or follow [@4champ](https://twitter.com/4champ_app) in Twitter.

### 17 October 2019 Happy Hacktoberfest!

I attended a local [Hacktoberfest](https://hacktoberfest.digitalocean.com) event hosted by [Electrobit Automotive](https://www.elektrobit.com) where I fixed a crash bug that emerged with iOS13 on the 4champ build. I was using a custom UISearchBar textfield access routine that iOS13 renders obsolete, as it now supports access to the search field in the SDK. In addition to the crash fix I corrected some style issues that iOS13 brought along. The dark mode support thing is TBD if I'll support it at all; the app is quite dark as it is.

### 13 August 2019 Download all mods by a composer

I attended [Datastorm 2019](https://datastorm.party) this year in the beginning of August, and during the party I managed to push a small new update to the repository. Now it is possible to download all modules by a composer on the Search view when you've selected a single Composer. By downloading the modules, you get to listen them in offline mode too, and in later updates it will be possible to build playlists of your local modules.

![alt Download All](images/download_all.jpeg "Download all modules by a composer")

### 29 July 2019 Notification on new modules

One of the most useful features that I had on the AppStore version was the notification on new modules. It's always nice to check what's the latest additions in the database. Majority of the additions are new old stock that has been found, but every now and then there's also modern day tunes coming in from a demoscene event.

The notification support is built using UserNotifications library, and is based on the app performing a background fetch to check for new items in database. In the event of new mods it will put up a local notification, and you can see the number of new mods in the badge on the app icon and on Radio tab in the 4champ UI.

### 15 June 2019 Local Collection view implementation

Ok so it took half a year but I finally got the time to squeeze the local collection implementation in. There are no fancy bells / whistles but when you search for mods or listen to 4champ radio, you can now mark modules for keeping by tapping the ⭐ button next to the module name in the "Now playing" area, Visualizer view or the Radio display. If you choose to unfavorite the module later, it will still be kept in the local collection until deleted.

While implementing this, I forgot that I had a cleanup function in the app that would delete all module files from application's documents directory at launch, to prevent unnecessary accumulation of files. When I ran the app first time with the original bundle identifier on my iPhone, the cleanup code wiped my whole collection (~5000 modules, about 1G of data). It was a moment of 🤯. Now the implementation is safe, even if you install on top of the appstore version.

If you look carefully to the codebase, you'll notice that there is some indications of features that are not available, e.g. sharing. Most of the stuff is coming, and some might be dropped from the Swift version.

The most notable feature yet to come is the support for playlists. After getting that done, the app is for most parts on par with the old AppStore Objective-C app. No promises, but I'm setting the end of year as deadline for that.

The Github project is now hooked up in [Codebeat](https://codebeat.co) static analysis platform, and every pull request (also my own) will get a scan for issues before it gets merged.

### 30 November 2018 🎧Better headphones experience

I had the settings branch going for quite a time before merge. My intention was to require user to type in the AMP website domain name before downloading modules, if that would enable me to get the app listed on App Store again, but... no dice with Apple Review 😔. This was to be done through settings UI, which now only has control for stereo separation.

### 4 October 2018 Bounty Bear Is Searching...

Over the past weeks I've dedicated a couple of evenings for 4champ, and the search feeature is ready to be shipped. Shipping here means merging from my development branch to master, since I'm still not taking my chances with Apple Review. That day is going to dawn but not yet.

When I originally started working with 4champ in 2012 it only supported search for module by name of the mod. The first AppStore release back in 2013 had search by module or composer name. Later I added group search. The release 2.1 that did not pass Apple Review introduced search in module texts (i.e. sample / instrument names). All these search options are now available in the 4champ github repo master branch.

In addition to the search support, some minor improvements were made on the playback handling with headphones: The default stereo separation value is set to more headphone-friendly value, and playback is paused now when headphones are disconnected.

### 23 July 2018 Power on!

In the scorching heat wave we had in Finland in July 2018 it was too hot to go out, so I sat down near the air conditioning and put together the Radio feature basics. The option to store modules locally is not implemented yet, but you can listen to two 4champ radio channels: _All_ plays tunes from the entire collection (as of today 149123 modules). _New_ Plays most recently added tunes (which does not mean that they're new - most of the additions are older ones, but often around Demoscene party weekends there is a set of all fresh modules too). In addition to the basic audio playback, you can also now see volume bars visualisation and module internal texts by tapping the now playing area at the bottom of the screen when the radio is on. Yay!

### 12 June 2018 Setting up the scene for rewrite

As explained below, quite a bit of hours have been poured into the 4champ version 2.1 that never got out. However, coming back to the code after a significant break - we're talking a year or so, it just did not feel comfortable to continue from there, with all the legacy Objective-C code (some of it the very first lines of iPhone sw I ever wrote).

So a rewrite it is. I have a couple of google analytics hooks in the app store version, and looking at the figures it is pretty clear that where the app is still used it is mostly used for the radio feature. The average session duration is around half an hour, so for those who still use it, use it quite a bit.

Therefore I've decided to start with the radio feature. The first milestone is to get the radio feature + about page working, so that I can perhaps start to really dig into getting the app also back listed on the store.

The first commit towards this target was done on June 12 and it was just the About view skeleton set up using Clean Swift templates. More to follow later.

### 21 April 2018 I can hear things

It was time for a rewrite on the replay routine that handles modules for 4champ. In the original app, playlist handling and replay were bundled in a single player class that used modplug to render the modules into audio stream. I wanted to avoid such tight coupling, and decided to implement the playing of modules in a way that allows for swapping the actual player libraries on the fly.
![alt replay class diagram](images/replay_class.png "Replay class diagram")

For now, I'm sticking with two libs: **libOpenMPT** and **HivelyTracker**. The first has a C++ interface, and the second is a C implementation. Since Swift does not have direct C/C++ interoperability, the Swift-facing Replay class and the library-specific wrappers are written in Objective-C.

To test run my implementation I also wrote a very bare-bones sample mod player app that bundles a set of different types of modules that resides under
SamplePlayer folder in the [4champ repository](https://github.com/sitomani/4champ/). You can try that out, just build the app in xcode and run in simulator or device.<br/>
![alt Sampleplayer screen](images/sampleplayer_screen.png "SamplePlayer screenshot")

### 17 April 2018

Decided to start from the dependencies - I had LibOpenMPT integrated in my original project, but it was a very clumsy
hack. In fact, I did not remember quite exactly how I put the iOS build together and after updating to latest OpenMPT sources
from github I was facing some build errors.

Some tweaking with the OpenMPT Lua scripts and I could get the thing to work, somewhat. Premake5 official release does not work too well for iOS projects so it took a pbxproj file script hack to get it done, and building requires a manual step to add the dependency libraries to linking phase, but now I have it under my OpenMPT fork at [https://github.com/sitomani/openmpt](https://github.com/sitomani/openmpt).

Output from the build scripts in my fork repo is a fat binary for libopenmpt-small containing all the necessary architectures for 4champ.

### 3 April 2018

These pages are created to document my development efforts and related endeavours around 4champ mod player app.
I hope publishing my progress here will inspire me to give the project a nudge more often than during past months.

As a first entry to this dev journal I guess it would make sense to introduce the project and the goals,
as I have not pushed any code yet. Basically, I have two main goals for 4champ in 2018:

1. Rewrite the app in Swift. I'll write down the [history of 4champ](app_history.md) on a separate page where I'll
   elaborate why I want to do the rewrite.
2. Find a way to get listed on AppStore again. The story about [why I had to remove 4champ from AppStore](appstore_removal.md)
   will also be posted on a separate page
