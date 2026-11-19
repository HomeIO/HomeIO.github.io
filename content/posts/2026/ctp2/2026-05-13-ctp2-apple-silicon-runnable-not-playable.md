---
title: "Porting CTP2 to Apple Silicon: Runnable Is Not Playable"
date: 2026-05-13T18:00:00+02:00
aliases: ["/posts/drafts/2026-05-13-ctp2-apple-silicon-runnable-not-playable/"]
topics: ["engineering"]
tags: ["ctp2", "cpp", "macos", "porting", "sdl2", "debugging"]
description: "A runnable CTP2 port was not a playable game. Lessons from conflicting class definitions, C++ variadic calls, SDL pixel formats, thread shutdown, and weak smoke tests."
---

**The first Apple Silicon port was runnable, not playable.** We could launch it and exercise a short sequence under a debugger. A normal campaign was still out of reach.

The May 10–13 work exposed problems that compilation alone could not catch: conflicting class definitions, non-trivial objects passed through C variadic calls, incompatible pixel formats, and threads outliving their resources.

## Adapt the existing engine first

The community codebase already had SDL and Meson support. We kept that foundation, used SDL2 on macOS, and repaired Windows-specific assumptions rather than replacing the engine.

The [first port commit](https://github.com/akwiatkowski/ctp2/commit/246d54543519d95c92de0ea8f34367de793d4345) linked an ARM64 executable. Among the changes were a GUID representation corrected from a 32-bit integer to a 16-byte structure and consistent coordinate-structure layouts. These fixes mattered because callers and implementations must agree on how objects are represented in memory.

But agreeing on data layout was not enough.

## One class name, two incompatible definitions

C++ compiles each source file separately. Two files can compile successfully while seeing different definitions of the same class, and the linker need not detect the disagreement.

Two compatibility headers defined the same base interface. One declared `QueryInterface`, `AddRef`, and `Release`; the other omitted `QueryInterface`. Guards suppressed whichever definition was included second, so header order could determine the definition used in each source file.

On this platform, virtual calls use positions in a function table. Omitting the first method changed those positions: the caller and the object could disagree about which function to invoke. The conflicting definitions violated C++'s One Definition Rule.

The [immediate fix](https://github.com/akwiatkowski/ctp2/commit/77a61b33302a624b92da06e1fe0d6449eb6cec06) added the missing method. One shared definition would be a stronger design than maintaining two copies.

**Debugging technique:** if a virtual call reaches an unexpected function, compare the class definitions in the preprocessed caller and implementation. Use their actual compiler flags and include paths. Header guards prevent repeated inclusion, not disagreement between separately compiled files.

## Copying the same integer can have different consequences

The event system passed handle objects through C-style variadic arguments (`...`). Those handles inherited from an `ID` class with a hand-written copy constructor:

```cpp
// Before: user-provided copy constructor.
ID(const ID &i) : m_id(i.m_id) { }

// After: compiler-generated memberwise copy.
ID(const ID &i) = default;
```

Both versions copy the same integer, but the user-provided constructor makes the copy operation non-trivial. That distinction matters when passing an object through `...`, where ordinary typed parameter checking is absent. The ARM64 build trapped or hung while creating an army through this event system.

Defaulting the constructor was the [targeted repair](https://github.com/akwiatkowski/ctp2/commit/77a61b33302a624b92da06e1fe0d6449eb6cec06). It was not a general solution for passing C++ objects through variadic functions. A typed event API would avoid this problem, but that was not the change made here.

When debugging such a call, check the argument types and their special members. An integer wrapper is not automatically interchangeable with the integer it contains.

## Separate drawing from displaying

A black window concealed several independent failures. The SDL code needed an internal pixel buffer—a *surface*—for drawing, a correctly converted copy to the window surface, and a call to display the result.

The engine drew 16-bit RGB565 pixels, but the macOS window surface used 32-bit pixels. Treating the window's format as the engine's internal format broke that distinction. The [fix](https://github.com/akwiatkowski/ctp2/commit/75fc6c9f) retained RGB565 internally and converted when copying to the window. Rewriting every drawing routine was unnecessary.

Other startup problems looked similar:

- The intro opened a movie window without a working SDL movie backend. We bypassed it.
- UI initialization failed when it could not open an X11 display. The macOS code had to tolerate that absence.
- SDL needed to process OS events for the window to become visible. The main loop also had to leave mouse events for the dedicated mouse thread instead of consuming them first.

For a blank window, check three things separately: **were pixels drawn, were they copied in the correct format, and were they displayed?** Then check whether startup or event handling prevents any of those steps.

## Stop the thread before freeing its resources

Cleanup destroyed UI surfaces while the mouse thread could still access them. The [repair](https://github.com/akwiatkowski/ctp2/commit/b2faf1c1) requested termination and joined the thread before destroying those resources.

A drawing mutex did not solve this. It protected concurrent operations, not the lifetime of the objects being used. Successful startup says nothing about shutdown safety; test both.

## An enum value is not necessarily an array index

The animation enum included negative sentinels such as `NONE = -1`, but accessors used its values directly as array indices. The [bounds-checking fix](https://github.com/akwiatkowski/ctp2/commit/52c13fadf1c0fa9e334a3f53ba9b00aa719278ea) included:

```cpp
sint32 GetHoldingCurAnimPos(UNITACTION action) const {
    // Sentinel values are not animation-array indices.
    if (action < 0 || action >= UNITACTION_MAX) return 0;
    return m_holdingCurAnimPos[action];
}
```

This prevents an out-of-bounds read. Returning zero was this accessor's fallback policy, not a universal rule: another API might need to report an invalid value instead. Check the enum's full range before using it to index storage.

## A repeatable smoke test can still prove very little

The [first harness](https://github.com/akwiatkowski/ctp2/commit/60b748557ca53762eabe19f4c3d964687bf8ed66) launched the game under LLDB and sent JSON commands over a Unix-domain socket: create a game, start it, end a turn, and quit.

It made failures easier to reproduce, but its success criteria were weak. It used fixed delays, continued after failed command responses, and could report success when the process was still alive and had to be terminated. A zero exit code also counted as success.

A useful test must check effects, not just requests:

- Did the game reach the expected state?
- Did the turn actually advance?
- Did quit finish without forced termination?

The harness gave us a repeatable way to investigate failures. Its green label did not establish those properties—and did not make the port playable.
