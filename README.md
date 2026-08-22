# Liquid Lens Private API Demo

This project is an experimental iOS application dedicated to researching the private UIKit class `_UILiquidLensView` and its related selectors.

It demonstrates how the system Liquid Glass selection lens used by UIKit controls can be discovered and instantiated dynamically through the Objective-C runtime. The sample also explores the lens's resting and lifted states, custom content, punch-out behavior, movement, and interaction animations.

https://github.com/user-attachments/assets/eb9b7de6-0773-465a-983f-0ba13a188146

## Purpose

The project exists for educational and research purposes. Its goals are to:

- examine how `_UILiquidLensView` behaves at runtime;
- understand the relationship between the lens, its container, selected content, and punch-out content;
- demonstrate the transition between resting and lifted states;
- experiment with moving the lens between custom menu items;
- document behavior that is not available through public UIKit headers or documentation.

## Demonstrated private APIs

The demo resolves `_UILiquidLensView` dynamically with `NSClassFromString` and invokes private Objective-C selectors such as:

```objc
initWithRestingBackground:
setLiftedContainerView:
setLiftedContentView:
setOverridePunchoutView:
setLiftedContentMode:
setStyle:
setWarpsContentBelow:
setRestingBackgroundColor:
setLifted:animated:alongsideAnimations:completion:
```

Because these declarations are not included in the public SDK, the project calls some methods through their Objective-C implementation pointers (`IMP`).

> [!WARNING]
> **Do not use this implementation in a production or App Store application.**
>
> `_UILiquidLensView` and the selectors listed above are private APIs. Apple permits App Store applications to use only public APIs. Referencing a private class dynamically with `NSClassFromString`, constructing selector names at runtime, or calling methods through `IMP` does not make their use compliant. The class and selector strings can still be detected during App Review, and an application that uses them may be rejected or removed from distribution.
>
> Private APIs also have no compatibility guarantees. Apple can rename or remove the class, change a selector, alter an argument type, or modify its behavior in any OS update. An ABI mismatch in an `unsafeBitCast` call can cause memory corruption or a crash rather than a recoverable failure. Behavior may also differ between simulator and physical devices or between minor iOS releases.

## Requirements

- iOS 26 or later
- Xcode 26 or later

The exact availability and behavior of the private class may vary by OS build.

## Production alternatives

For shipping applications, use supported APIs instead:

- standard controls such as `UITabBar`, `UISegmentedControl`, and `UISlider`;
- `UIVisualEffectView` with `UIGlassEffect` and `UIGlassContainerEffect` in UIKit;
- `glassEffect`, `GlassEffectContainer`, and `glassEffectTransition` in SwiftUI;
- a custom animation implemented entirely with public UIKit, SwiftUI, Core Animation, or Metal APIs.

Public APIs may not expose every detail of the system tab bar's lifted lens, but they provide documented behavior, compatibility across OS updates, and App Store compliance.

## Disclaimer

This repository is not affiliated with, endorsed by, or supported by Apple. It is intended solely for learning, experimentation, and discussion of UIKit internals. Use the code at your own risk.
