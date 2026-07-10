//  SwipeBack.swift
//  Re-enables the interactive edge-swipe "back" gesture in NavigationStack even when
//  the system back button is hidden (the detail screen draws its own back bar, so the
//  default gesture would otherwise be disabled).

import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow the swipe-back when there is something to pop.
        viewControllers.count > 1
    }
}
