openfl-webaudio
===============

A Web Audio API back-end for OpenFL/HTML5

This is experimental for now.

### Planned features 

* Multiple concurrent sounds on mobile platforms (untested, but should already work)
* Ability to set sound volume on iOS for each sound (idem)
* `Microphone` implementation (work-in-progress)
* `SampleDataEvent` implementation (work-in-progress)
* `SoundTransform` support (TODO)
* `SoundMixer` support (TODO)
* Fallback to OpenFL's current `<audio>`-based implementation (TODO)
* Provide a way to automatically initialize sound at user action on iOS
 
The goal is globally to have a complete implementation of Sound and Microphone related APIs in HTML5...

### Usage / testing

* Clone this repository
* Add this line to your `project.xml`

```
<source path="PATH/TO/openfl-webaudio" if="html5" />
```
