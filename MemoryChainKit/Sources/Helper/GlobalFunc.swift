//
//  GlobalFunc.swift
//  MemoryChainKit
//
//  Created by Marc Steven on 2020/4/8.
//  Copyright © 2020 Marc Steven(https://github.com/MarcSteven). All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SafariServices

/// Attempts to open the resource at the specified URL.
///
/// Requests are made using `SafariViewController` if available;
/// otherwise it uses `UIApplication:openURL`.
///
/// - Parameters:
///   - url:  The url to open.
///   - from: A view controller that wants to open the url.
public func open(url: URL, from viewController: UIViewController) {
    let vc = SFSafariViewController(url: url)
    viewController.present(vc, animated: true, completion: nil)
}

//MARK: - toggleFlash
public func toggleFlash(on:Bool) {
    guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
    guard device.hasTorch else { print("Torch isn't available"); return }

    do {
        try device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        // Optional thing you may want when the torch it's on, is to manipulate the level of the torch
        if on { try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel.significand) }
        device.unlockForConfiguration()
    } catch {
        print("Torch can't be used")
    }
}

public func checkAndOpenApp(_ appScheme:String,
                            appURL:String) {
    if UIApplication.shared.canOpenURL(URL(string: appScheme)!) {
        let url = URL(string: appScheme)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }else {
            UIApplication.shared.canOpenURL(url!)
        }
    }else {
        if let url = URL(string: appURL), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }else {
                UIApplication.shared.openURL(url)
            }
        }
    }
}


public func unsafePointer<T:AnyObject>(to object:T) ->UnsafeRawPointer {
    return UnsafeRawPointer(Unmanaged<T>.passUnretained(object).toOpaque())
}
public func unsafeMutablePointer<T:AnyObject>(to object:T)->UnsafeMutableRawPointer {
    return Unmanaged<T>.passUnretained(object).toOpaque()
}
/// Detects if the LLDB debugger is attached to the app.
///
/// - Note: LLDB is automatically attached when the app is running from Xcode.
public var isDebuggerAttached: Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    assert(junk == 0, "sysctl failed")
    return (info.kp_proc.p_flag & P_TRACED) != 0
}
public func delay(by interval:TimeInterval,
                  _ completionHandler:@escaping () ->Void) {
    Timer.schedule(delay: interval, handler: completionHandler)
}

public func synchronized<T>(_ lock: AnyObject, _ closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}

// MARK: Debounce

/// Wraps a function in a new function that will only execute the wrapped
/// function if `delay` has passed without this function being called.
///
/// - Parameters:
///   - delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to debounce. Can't accept any arguments.
/// - Returns: A new function that will only call `action` if `delay` time passes between invocations.
public func debounce(delay: DispatchTimeInterval, queue: DispatchQueue = .main, action: @escaping (() -> Void)) -> () -> Void {
    var currentWorkItem: DispatchWorkItem?

    return {
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action() }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/// Wraps a function in a new function that will only execute the wrapped function if `delay` has passed without this function being called.
///
/// Accepts an `action` with one argument.
///
/// - Parameters:
///   - delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to debounce. Can accept one argument.
/// - Returns: A new function that will only call `action` if `delay` time passes between invocations.
public func debounce<T>(delay: DispatchTimeInterval, queue: DispatchQueue = .main, action: @escaping ((T) -> Void)) -> (T) -> Void {
    var currentWorkItem: DispatchWorkItem?
    return { (p1: T) in
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action(p1) }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/// Wraps a function in a new function that will only execute the wrapped function if `delay` has passed without this function being called.
///
/// Accepts an `action` with two arguments.
///
/// - Parameters:
///   - delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to debounce. Can accept two arguments.
/// - Returns: A new function that will only call `action` if `delay` time passes between invocations.
public func debounce<T, U>(delay: DispatchTimeInterval, queue: DispatchQueue = .main, action: @escaping ((T, U) -> Void)) -> (T, U) -> Void {
    var currentWorkItem: DispatchWorkItem?
    return { (p1: T, p2: U) in
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action(p1, p2) }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

// MARK: Throttle

/// Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
///
/// - Parameters:
///   - delay: A `TimeInterval` specifying the number of seconds that needs to pass between each execution of `action`.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to throttle.
/// - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
public func throttle(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping (() -> Void)) -> () -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return {
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action()
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/// Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
///
/// Accepts an `action` with one argument.
///
/// - Parameters:
///   - delay: A `TimeInterval` specifying the number of seconds that needs to pass between each execution of `action`.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to throttle. Can accept one argument.
/// - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
public func throttle<T>(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping ((T) -> Void)) -> (T) -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return { (p1: T) in
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action(p1)
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/// Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
///
/// Accepts an `action` with two arguments.
///
/// - Parameters:
///   - delay: A `TimeInterval` specifying the number of seconds that needs to pass between each execution of `action`.
///   - queue: The queue to perform the action on. The defaults value is `.main`.
///   - action: A function to throttle. Can accept two arguments.
/// - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
public func throttle<T, U>(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping ((T, U) -> Void)) -> (T, U) -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return { (p1: T, p2: U) in
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action(p1, p2)
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}
public  func alert(title:String = "",
                   message:String = "") {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
    alert.addAction(cancelAction)
    alert.show()
}

// MARK: - Global

/// Returns the name of a `type` as a string.
///
/// - Parameter value: The value for which to get the dynamic type name.
/// - Returns: A string containing the name of `value`'s dynamic type.
public func name(of value: Any) -> String {
    let kind = value is Any.Type ? value : Swift.type(of: value)
    let description = String(reflecting: kind)

    // Swift compiler bug causing unexpected result when getting a String describing
    // a type created inside a function.
    //
    // https://bugs.swift.org/browse/SR-6787

    let unwantedResult = "(unknown context at "
    guard description.contains(unwantedResult) else {
        return description
    }

    let components = description.split(separator: ".").filter { !$0.hasPrefix(unwantedResult) }
    return components.joined(separator: ".")
}
public func insertBlurView (view: UIView, style: UIBlurEffect.Style) -> UIVisualEffectView {
    view.backgroundColor = UIColor.clear
    
    let blurEffect = UIBlurEffect(style: style)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = view.bounds
    view.insertSubview(blurEffectView, at: 0)
    return blurEffectView
}

//Utility method - takes a list of views and simply makes up new string names for them
public func dictionaryOfNames(_ array:UIView...) ->[String:UIView] {
    var dictionary = [String:UIView]()
    for (index,v) in array.enumerated() {
        dictionary["v\(index+1)"] = v
    }
    return dictionary
}

func format(with mask: String, phone: String) -> String {
    let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    var result = ""
    var index = numbers.startIndex // numbers iterator

    // iterate over the mask characters until the iterator of numbers ends
    for ch in mask where index < numbers.endIndex {
        if ch == "X" {
            // mask requires a number in this place, so take the next one
            result.append(numbers[index])

            // move numbers iterator to the next index
            index = numbers.index(after: index)

        } else {
            result.append(ch) // just append a mask character
        }
    }
    return result
}
public func swizzle(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector, kind: SwizzleMethodKind = .instance) {
    let original: Method?
    let swizzled: Method?

    switch kind {
        case .instance:
            original = class_getInstanceMethod(forClass, originalSelector)
            swizzled = class_getInstanceMethod(forClass, swizzledSelector)
        case .class:
            original = class_getClassMethod(forClass, originalSelector)
            swizzled = class_getClassMethod(forClass, swizzledSelector)
    }

    guard let originalMethod = original, let swizzledMethod = swizzled else {
        return
    }

    let didAddMethod = class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    )

    if didAddMethod {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

public enum SwizzleMethodKind {
    case `class`
    case instance
}
