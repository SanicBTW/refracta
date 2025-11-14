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