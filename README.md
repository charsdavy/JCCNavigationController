# JCCNavigationController

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat
            )](http://mit-license.org)
[![Platform](http://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/)
[![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat
             )](https://developer.apple.com/swift)
             
[![Issues](https://img.shields.io/github/issues/charsdavy/JCCNavigationController.svg?style=flat
           )](https://github.com/charsdavy/JCCNavigationController/issues)
[![Cocoapod](http://img.shields.io/cocoapods/v/SwiftyStoreKit.svg?style=flat)](http://cocoadocs.org/docsets/SwiftyStoreKit/)

A navigation bar integrated transition animation effect.

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate JCCNavigationController into your Xcode project using CocoaPods, specify it to a target in your `Podfile`:

```bash
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
  # your other pod
  # ...
  pod 'JCCNavigationController', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

You should open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.

For more information about how to use CocoaPods, I suggest [this tutorial](https://www.raywenderlich.com/156971/cocoapods-tutorial-swift-getting-started).

# Usage

## AppDelegate


```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    let dashboardController = IHSDashboardController.init()
    self.window?.rootViewController = JCCNavigationController.init(rootViewController: self.dashboardController!)
    self.window?.makeKeyAndVisible()

    return true
}
```

## UITableView

```swift
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let detailViewController : IHSCookDetailViewController = IHSCookDetailViewController.init()
    self.jccNavigationController.pushViewController(viewController: detailViewController)

    tableView.deselectRow(at: indexPath, animated: true)
}
```

# Screenshot

![Screenshot](./Screenshot.gif)
