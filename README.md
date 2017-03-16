![README-images/TranscriptionsHeaderNewSmaller.png](README-images/TranscriptionsHeaderNewSmaller.png)



A text editor optimized for fast manual transcription of audio- or video material on the Mac.

Load media in the player, use the controls to adjust speed and volume, set keyboard shortcuts for media control in the preferences pane and type away. Transcriptions also supports text-substitutions by inserting "@" followed by a text-token.

**Transcriptions is [Free/Libre Open Source Software](https://en.wikipedia.org/wiki/Free_and_open-source_software). Please support development by [buying the Transcriptions binary in the AppStore](https://itunes.apple.com/at/app/transcriptions/id911974149?l=en&mt=12) or by [donating via PayPal](http://www.unet.univie.ac.at/~a0206600/TranscriptionsDonate.html). Thanks to all supporters!**

For Mac OSX 10.9 Mavericks and below, use version 0.8 that can be found [here](https://code.google.com/p/transcriptions/downloads/list).

**Check out the [app overview](README-images/transcriptionsAppOverview.pdf) to get started.**

## Features: ##

  * Media with tape behavior
  * Customizeable media-control shortcuts([->shortcut recorder](https://github.com/Kentzo/ShortcutRecorder))
  * Timestamps
  * Text substitution
  * Footpedal-support
     * ([->audiotranskription.de](http://www.audiotranskription.de/deutsch/transkription/usb-fussschalter-f-pro/usb-fussschalter-f-pro.html))
     * ([->altoedge.com](http://www.altoedge.com/pedals/index.html)): The pedal mapping is currently hard-coded:
        * Left button: rewind and play while holding the left button down
        * Middle button: press and hold the middle button to play in the normal rate release the button to pause
        * Right button: fast forward and play while holding the right button down



**MBW Pick of the week: March 30, 2010**

[![](README-images/MacBreakWeekly120X120.jpg)](http://www.mbwpicks.com/2010/03/30/picks-from-mbw-187-a-stick-between-their-legs/)

Transcriptions source code is used in the application [F5(Mac)](http://www.audiotranskription.de/f5.htm).


## Screenshot: ##


![README-images/TranscriptionsScreenshot.png](README-images/TranscriptionsScreenshot.png)




## Requirements: ##
**Version 1.0**
  * Mac OSX 10.10 Yosemite


**Version 0.8**
  * Mac OSX 10.5 Leopard
  * [Perian](http://perian.org/) and [Flip4Mac](http://www.microsoft.com/windows/windowsmedia/player/wmcomponents.mspx) **recommended**



Sparkle is used up to Version 0.8. Please download the [binary from the Mac App Store](https://itunes.apple.com/at/app/transcriptions/id911974149?l=en&mt=12) to get updates starting from Version 1.0.
[![](README-images/Sparkle.png)](http://sparkle.andymatuschak.org/)


## Development: ##
### Requirements

If you wish to build Transcriptions yourself, you will need the following components/tools:

* a recent Xcode with support for ARC and subscripting
* OS X SDK (10.10 or later)
* Git

### Environment Setup

After cloning the repository, run the following commands inside the repository root (directory containing this `README.md` file):

    git submodule update --init --recursive

You can then open the Xcode project file and build.
