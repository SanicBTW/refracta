# refracta - status

This document reports the current status of the code and some implementations, including some issues it might have compared to the C# source.

### Events

If the normal array with callbacks approach doesn't convince me, I'll think on making an event manager with macros and more to make it somewhat performant I guess, look into `refracta.events` on the refracta family section on the readme.

### Bindables

These are behaving mostly like the original ones but they DON'T implement interfaces for the time being, this is probably the key point of bindables on C# but since the implementation I made was kinda(?) rushed, I didn't use interfaces and it was meant to be a simple workaround bindables but in the end I implemented the whole thing.

On the other side I also didn't implement the rest of the bindable types (BindableNumber, BindableBool, etc) which is something I'll be progressively doing.

Serialization is something I haven't started working on yet since the whole thing looks hard and messy but I'll definitely get it working sometime in the future.

WeakRefs on JS are EXTREMELY weak and when I say this it's because they cannot stay long enough before getting the underlying value garbage collected, so if you need em for anything (binding through copies and such) then its better to keep the bindables on the stack or something that keeps them away from getting garbage collected.

### Exceptions

Some parts of the code will throw a simple string instead of an exception, maybe I should extend the Exception class and make my own to properly throw.

### Comments

Can't help but NOT add comments while writing the code, the minimum is adding the links to the original file, but I know I should do better with comments, sorry.

### Clocks

This code HASN'T changed and is not any different from my original code from my projects and the code itself can be pretty messy, overall I'll try to keep up with changes from osu!framework changes

Currently some clocks need a reference clock, previously it was bound to `BrowserClock` but since this library is meant to be cross-platform
I have to write a cross-platform implementation of the clock.

[21/11] Commit day

I've been working on the clocks for the past week, I stumbled upon ThrottledFramedClock for a variety of reasons it won't be included for a while, one of them being to heavily depend on the throttled clock and sleep on the tick call rather than sleeping when updating, kinda weird, also the implementation I did for RealTimeClock doesn't convince me enough but I'll leave it like this until I start working on the dependency container that will englobe the entire library.

### Scheduler

Since everything is expected to be run on the main thread exclusively, no thread safety was added (not only to the scheduler but to the entire code) hence the scheduler lacking some parts of the original c# code, like `IsMainThread`, `forceScheduled` etc...

On AddOnceWithData the generic check trick was originally gonna be different, trying to check the type of `t` against `ScheduledDelegateWithData` but testing it on a more [barebones code](https://try.haxe.org/#1A185b8f) it would result on a skip and then I came up with the [string comparison](https://try.haxe.org/#253436d0) which requires the `@:generic` metadata in order to work.