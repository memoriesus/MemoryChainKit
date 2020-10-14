//
//  UIWindowExtension.swift
//  MemoryChainKit
//
//  Created by Marc Steven on 2020/3/17.
//  Copyright © 2020 Marc Steven(https://github.com/MarcSteven). All rights reserved.
//

import UIKit

public extension UIWindow {
    func topViewController()->UIViewController? {
        var top = self.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            }else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            }else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            }else {
                break
            }
        }
        return top
    }
}
public extension UIWindow {
    func setRootViewController(_ viewController:UIViewController) {
        if rootViewController == viewController {
            return
        }
        if let rootVC = (rootViewController as? UINavigationController)?.rootViewController,
            rootVC == viewController{
            return
        }
        rootViewController = viewController.embedInNavigationControllerIfNeeded()
        makeKeyAndVisible()
    }
}
