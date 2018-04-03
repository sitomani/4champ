# History of 4champ

## How it all started

Back in May 2012 I quite abruptly found myself without a project when my customer then decided to pull the plug on a whole 
platform development program. I had been working mostly with QT/QML on mobile linux and Symbian platforms, but there was
no new projects in the radar for the time being on those platforms. So I decided to get familiar with something new, namely
iOS. I wanted to learn with a project that would be fun to work with, and the idea to create a mod player for iOS came to me 
pretty quickly. It took a couple of weeks to create the first rough bare bones version that never got published, but was
already capable of downloading modules from [amp.dascene.net](amp.dascene.net) and playing them back with 
[Bass audio library](http://www.un4seen.com/). 

After getting aqcuianted with Objective-C and iOS I quite promtply got involved a customer project and the development mode 
for 4champ changed to a leisure time project. Thus it took almost a year to get the 1.0 version published in AppStore in 
April 2103. By then, I had ditched the Bass library in favor of [libmodplug](https://github.com/Konstanty/libmodplug), as it
was free and supported more module formats.

During the app development, [Boogie Software Hackfests](https://www.youtube.com/watch?v=FCMmzvXABvY&) have been essential in
getting the new features pushed, as these 3-day trips to the countryside with geek colleagues really help getting things done
at least to a certain level. Looking at the git commit history of the original repository the hackfest weekends show pretty
clearly.

## Short version history

#### 1.0 April 23 2013
Initial release. This version had composer and module name search, and you mark your favorite mods once downloaded.

#### 1.1 Jul 9 2013
Search in local modules, search groups in amp.dascene.net, multiple playlists.

#### 1.2 Aug 24 2013
Minor update with STK format support added, and some graphical enhancements

#### 1.3 Jan 4 2014
4champ radio introduced (random playback from the full amp.dascene.net catalog). AFAIK 4champ was the first iOS mod player 
app to have this kind of feature.

#### 1.4 Feb 24 2014
Module sharing implemented, i.e. users can share what they are listening to Twitter/Facebook etc. I have been using 
this quite a bit myself on my [@4champ_app](https://twitter.com/4champ_app) twitter account, and occasionally I've seen
some others use it too!

#### 1.5 Sep 8 2014
Added **New in AMP** radio channel that enables playback of the most recently added tunes. Local notification implemented
that shows the number of new mods available in amp.dascene.net. First 64-bit version of the app.

#### 1.6 Nov 14 2014
Added analytics to the project to gain some insights about users, operating system related changes.

#### 1.7 Jan 1 2015
In-app settings added for controlling playback settings and some other things. Shuffle mode added to playlists.

#### 1.8 Jul 25 2015
Localisation added in six languages (en, fi, dk, no, de, ru). App rating dialog added.

#### 1.9 Nov 21 2015
First version to support download of all modules by a composer in one go.

#### 2.0 Aug 2 2015
The **Assembly 2015** release (out just before ASM2015 which was the first [Assembly](https://assembly.org) I participated after my teens!). 
Now playing view added to the player (see module sample texts while playing). This was also the first version where the
background play feature was no longer an in-app purchase, but free for all users.

### Version 2.1 that never was

After August 2015 I have done a whole lot:

* Enabled search in sample texts
* Integrated with OpenMPT as playback library on [sagamusix](https://github.com/sagamusix)'s suggestion
* 3D touch support on the app icon for one-touch radio start
* Added visualizer on the now-playing screen that shows nice volume bars during playback
* Hivelytracker formats support (AHX, HVL) added
* Implemented rough Apple Watch companion to the app
* Started Swift migration with some first tests

When I was about to publish all this, my app review seemed to take unusually long. After a couple of weeks I asked the review 
team what was going on, and got a response that there's some issues yet to be checked and they'd come back to me soon. And so
they did, with a <font color='red'>rejection</font>. A lengthy correspondence with Apple Review and Amiga Music Preservation staff
followed, but eventually I decided to give it a rest and removed the app from store. Read the whole story: 
[Why I removed 4champ from AppStore](appstore_removal.md).
