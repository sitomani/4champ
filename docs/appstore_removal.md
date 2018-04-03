# Why I Removed 4champ from AppStore

I don't know if it is very common to have disputes/issues with AppStore review, but my mod player app has bumped to such 
twice, the second time unresolvable at least for the time being.

## What's in a name?

When I released the 1.0 version of 4champ it was actually called **AMP Player**, referring to the 
[Amiga Music Preservation](amp.dascene.net) site that the app connects to for searching + downloading modules. 
In the codebase there is still a lot of references to the original application name, although they are not visible
in the UI.

By the end of 2013 I got contacted by Apple Review team about the application name. Apple had received a trademark dispute from
the holder of AMP trademark, claiming that my app was constituting an infringement by using AMP in its name. It was pretty
frightening to get mails from Apple legal, but this seemed to be something that could be tackled by just rebranding so I kept
my cool and started thinking. I still wanted to keep the 'amp' somewhere, and came up with the name **4champ** that refers also
to 4-channel music. After the name change, there was no further trademark clash (I screened 4champ in a couple of trademark
search services to be sure before release).

So, I was not a complete rookie any more when 4champ 2.1 review turned south.

## The final dispute

In October 2016, after a couple of weeks since I had uploaded the most recent version for review to iTunesConnect, I 
asked what was going on, and in a while I got a message about app rejection, accompanied with this message:

>Your app allows users to save or download music, video, or other media content without authorization 
>from the relevant third-party sources.
>Specifically, your app contains audio downloading from dascene.net.
>We've attached screenshot(s) for your reference.

No kidding? My app, after having been available in App Store for over 3 years, had passed a dozen reviews with a breeze. 
Now it suddenly was found to violate the review guideline 5.2.3 Audio/Video Downloading, which in its current form states that

>Apps should not facilitate illegal file sharing or include the ability to save, convert, or download media 
>from third party sources (e.g. Apple Music, YouTube, SoundCloud, Vimeo, etc.) without explicit authorization 
>from those sources. Streaming of audio/video content may also violate Terms of Use, so be sure to check before
>your app accesses those services. Documentation must be provided upon request.

In my response to AppStore Review team I referred to 
[Amiga Music Preservation forum](http://amp.dascene.net/forum/index.php/topic,508.0.html) 
where **Crown** of Cryptoburners, one of AMP administrators announces the release of AMP player first version. 
I had *naturally* contacted AMP staff before
putting out an application that relies heavily on their service, and they had absolutely no issues with that. Also

>**a fundamental principle of the demoscene is about sharing, editing and remixing other people's work**

as **Magic** and **Netpoet** put it in their 
[Copyright and the Demoscene](http://hugi.scene.org/online/hugi36/hugi%2036%20-%20demoscene%20forum%20netpoet%20magic%20copyright%20and%20its%20meaning%20for%20the%20demoscene.htm) article.

Email messages and forum posts were not considered 'Documentation' by Apple Review team. Somehow I was not surprised that 
my demoscene philosophy references had no discernible impact either. It took some messages to get
a confirmation from AppStore on what kind of documentation would be needed. There was no templates but my agreement 
proposals were commented upon promptly, so no hard feelings there. I finally made a very short document template which, once
signed would be considered solid permission for my app to use amp.dascene.net resources.

Meanwhile, I was also having a tight correspondence with the AMP team about the topic. Once I got a draft agreement
about use of amp.dascene.net module database in my app done, I posted that for screening to AMP, but eventually it got
turned down. In the end, it came down to Apple requiring a volunteer based online service administrator to sign an agreement 
with publisher of an app that makes use of their service in order to keep the app (that is not directly in relation with 
AMP) in the AppStore - it just did not click.

I can relate to both Apple and AMP team here. Apple's interest is to keep out of any legal disputes that might arise from
potentially copyright-infringing apps on their platform - hence the need to document the permission, and it's the app 
developer's response to provide sufficient material. AMP team on the other hand are a bunch of demosceners who maintain 
perhaps the largest tracker music database in the net, just for the common good. I really appreciate their work and effort, 
and could not blame them a bit for not signing an agreement just for the sake of Apple and my app that is not part of AMP, 
even though it is practically dependent of the service.


## Plan ~~B~~G

Clearly I was at a dead end with 4champ. It seemed impossible to get the Apple Review dispute sorted out by any means 
that I could think of, and the agreement plan had gone off too. At this point, around September 2017 I decided to pull 
4champ from AppStore altogether. It did not feel right to keep the app available, if I could not release any updates to it. 
As a matter of fact, it was a nice policy from Apple to let the version 2.0 stay in during the lengthy conversations.

So I set up this github repository, and added just a license and readme files back in September 2017, as a placeholder for
releasing the app as open source project. If I could not get it listed in AppStore, anybody with Xcode could build it from
sources and install it on their own devices. I have also some ideas about how to get the listed again in AppStore, more 
about that later.

By the time of writing this, I have done some initial moves towards getting the code committed in github. Due to the long
release pause there's some OS updates for me to catch up with, and I also plan to do somewhat major rewrite in Swift 
before uploading the app sources. You can follow the [index](index.md) page for updates as I proceed with these actions.

