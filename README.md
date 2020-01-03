NSSound_SystemVolumeExtension
================
This is based on the original ISSoundAdditions adapted to Swift by mabi99 (Marco Binder, Heidelberg, Germany). First forked Jan 2020.

Major changes: original ISSOundAdditions methods were moved to the private interface of the NSSound extension. Public interface is now perfectly Swift 5 conforming, and everything is consitently prefixed with "systemSound...". System volume can muted state are now accessed as properties (gettable & settable); systemVolumeIncreaseBy() and systemVolumeDecreaseBy() were removed: simply use NSSound.systemVolume += 0.1 or the like!

Minor change: the private function to set the system volume now has an optional parameter muteOff:Bool, which specifies if setting the volume automatically un-mutes the system. This CAN be desired, but it can also make sense not to. The public interface to systemVolume does not use this option currently (auto-unmutes as previously in ISSoundAdditions).

One added convenience function is systemVolumeFadeToMute(seconds:Float, blocking:Bool), which does what its name implies: it fades out the volume softly during the specified time (default 3 seconds). This function is threaded if blocking was set to false (default: true). In this case, the fadeing out happens in the background while the function immediatelly returns; caveat: during the fadeing out, the user can manually change the volume or mute the system– the function will stubbornly continue what it's been doing. No big harm, but something to keep in mind. NOTE: the function resets the system volume to the volume before muting, so that the user can unmute the system (e.g. by the keyboard mute key) to return to the previous volume as expected from a muted system. (This is realized by the new "mutingOff" parameter of the private setSystemVolume() function.)

Disclaimer: I have tested the code reasonably well, but I assume no liability for any harm or inconvenience it may cause- use at own risk! On the other hand, I claim no copy right, just go ahead and use it! Would just be nice to be acknowledged if you use it...


ISSoundAdditions
================
ISSoundAdditions is a NSSound category to read and modify system volume effortlessly.

It's entirely built using CoreAudio to get and set the volume of the system sound and some other utilities.
It was implemented using the Apple documentation and various unattributed code fragments
found on the net. For this reason, its use is free for all.
 
Getting Started
=============
To use this category, your application cannot run on OS X versions prior to OS X Snow Leopard 10.6.

There are only two things to do, to correctly configure the ISSoundAdditions:

1. Link your project against the CoreAudio Framework: in Xcode 5, select your project and then select your target. Look for the "Linked Frameworks and Libraries" section and click on the "+" button: in the panel that appears, select "CoreAudio.framework" and click "Add".
2. ISSoundAdditions is composed of two files: ISSoundAdditions.h and its implementation .m. Add these files to your Xcode Project and import **ISSoundAdditions.h** in one of your classes.

Thanks to the fact that the ISSoundAdditions is a category of the NSSound class, you can use all of the new methods by just calling them on the NSSound class.

Features
=============
ISSoundAdditions offers all the information that you might need when working with system volume and output devices:

* Get and set the system volume of the selected output device.
* Increase or decrease the system volume by a specified value.
* Instantly mute and unmute the selected output device.

Documentation
=============

`+ (AudioDeviceID)defaultOutputDevice;`
Returns the AudioDeviceID of the currently selected output device.

`+ (float)systemVolume;`
Returns a float representing the current system volume (Range: 0.0 - 1.0).

`+ (void)setSystemVolume:(float)inVolume;`
Sets the system volume of the currently selected output device to *inVolume*  (Range: 0.0 - 1.0).

`+ (void)increaseSystemVolumeBy:(float)amount;`
Increases the system volume by *amount*.

`+ (void)decreaseSystemVolumeBy:(float)amount;`
Decreases the system volume by *amount*.

`+ (void)applyMute:(Boolean)m;`
Mute or unmute the currently selected output device.

`+ (Boolean)isMuted;`
Return whether the default device is muted.

`#define	THRESHOLD`
ISSoundAdditions will mute the output device if the computed system volume (after a call to *setSystemVolume* or *increaseSystemVolumeBy*) is lower than the threshold.
If your application have to deal with non-standard output devices, you might need to change this value.

Project State
=============
The ISSoundAdditions is currently in a **Release** state. You can use it freely in a stable application.

Other Stuff
=============

## What's Missing
Currently, the ISSoundAdditions supports almost all the features we planned for it. If you're interested in contributing, don't hesitate to fork this repo!

## Special Thanks
* The StackOverflow community
* You, that are spending your time reading this text!
