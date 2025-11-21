# refracta

### Quick heads-up

I still don't know how to call this project yet, a framework, web framework, game framework, whatever it suits your needs I guess.

Most of the code is just my best attempt to port some goodies from [osu!framework](https://github.com/ppy/osu-framework) C# code, some of the code might be HORRIBLE and I know it, Haxe misses a couple of C# features and I try my best to workaround them, any suggestion on the code, please open an issue or a pull request regarding it.

Also this code doesn't contain a SINGLE bit of thread-safe code unlike the C# code, it will eventually be implemented but only IF necessary.

### WIP

This project is still somewhat barebones, even if I use it on 2 of my projects, it SHOULD work out of the box.

##### Lil' fun fact!

This project is originated from 2 of my projects, since they share the codebase and I've been modifying both of them to suit my needs

sometimes the other project lacks the changes of the other one AND I'm lazy to sync it properly, so it's better if I just do it a library.

### Libraries

hxasync for JS and Python targets to add support for the async attribute, on native targets this shouldn't be evaluated at any point, rather it will use another library for native async support.

scopes for the `finally` behaviour on a try-catch block

### The refracta family

THIS is refracta.core (not named after it because I thought that without an extension it already looked like something as the base of the family) and there's a couple more of libraries on the works that could work out of the box too.

- `refracta.preloader` - A simple preloader that can work with any project, embeds the specified folder. On JS targets it can export the preloaded content into a separate file, reducing the size of the main JS file.
- `refracta.injection` - A fork of [haxe-injection]() for the framework to plug it somewhat deeper into the framework while adding the `BackgroundDependencyLoader` attribute as a macro and more.
- `refracta.async` - A fork of [hxasync]() which fixes an issue with the async macro and adds a bridge to another library with native async support.
- `refracta.events` - An event manager with macros and a basic event system (similar to AetherFramework Events System).