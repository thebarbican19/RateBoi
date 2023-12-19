
[![Swift Version](https://img.shields.io/badge/Swift-5.x-orange.svg)]()
[![MacOS Support](https://img.shields.io/badge/MacOS-13.0+-green)]()
[![iOS Support](https://img.shields.io/badge/iOS-13.0+-green)]()
[![tvOS Support](https://img.shields.io/badge/tvOS-13.0+-green)]()
[![watchOS Support](https://img.shields.io/badge/watchOS-4.0+-green)]()
[![visionOS Support](https://img.shields.io/badge/visionOS-1.0+-green)]()

## RateBoi

Getting a user to write a positive review is all about timing. Get this wrong and best case scenario is they don’t review your app and you’ve missed your opportunity. The worst case is they do review it and leave a horrible review based on the bad experience. 

**RateBoi** is an open-source dependency [(GNU v3)](https://github.com/thebarbican19/RateBoi?tab=GPL-3.0-1-ov-file) for iOS & MacOS designed to make it easy to trigger reviews at the right time built for **[SprintDock](https://sprintdock.app?ref=rateboi) & [BatteryBoi](https://batteryboi.ovatar.io?ref=rateboi)**

This is done by utilizing a **‘delight’ score**. Once the delight score reaches a certain threshold in an amount of time, a callback/state is triggered and you can trigger a SkoreKit review prompt, or deliver your own custom UI and functionality. 

### Install
You can add this package to your project using Swift Package Manager. Enter the following url when adding it to your project package dependencies:

`https://github.com/thebarbican19/RateBoi`

### Setup
From your AppDelegate or another initiation point, you can call the following setup function. Here, you can set the required threshold (points) and enable/disable debugging. 

`RateBoi.main.setup(points: 30, debug: true)`

This function is **not required**, and by excluding it the required threshold will default to 20 points and debugging is triggered by the `#DEBUG` flag.

### Scoring
RateBoi triggers the rate callback when a score is reached. Updating the score should be done when the user completes a positive action, like completing the onboarding, creating a new item, etc. You can set the amount of static number of points manually. The default is determined by the time between events, app opens, and usage (in-app) and errors. If positive events are triggered in quick succession then a callback will be triggered much faster. Similarly, if fatal errors have been triggered and only one previous positive event then the callback/state will not be called. 

`RateBoi.main.setup(points: 30, debug: true)`



### Callback
TBA

### @Published State
TBA



