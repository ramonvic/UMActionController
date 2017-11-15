//
//  UMGroupedAction.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 12/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

open class UMGroupedAction<T> : UMAction<T> where T : UIView {

    open var actions: [UMAction<T>]!

    public convenience init(style: UMActionStyle, andActions actions: [UMAction<T>]) {
        self.init()
        self.style = style;
        self.actions = actions;
    }

    public override init() {
        super.init()
    }

    open override var isCancel: Bool {
        return self.actions.filter { $0.style == .cancel }.count > 0
    }

    override func executeHandlerOfCancelActionWithController(_ controller: UMActionController<T>) {
        for action in self.actions {
            if action.isCancel {
                action.executeHandlerOfCancelActionWithController(controller)
                break
            }
        }
    }

    open override var controller: UMActionController<T>! {
        get {
            return self.actions.first!.controller
        }
        set {
            self.actions.forEach { $0.controller = newValue }
        }
    }

    open override func loadView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        let metrics: [String : Any] = [
            "separatorHeight": (1.0 / UIScreen.main.scale),
            "actionHorizontalMargin": self.controller.settings.action.horizontalMargin/2
        ]

        var currentLeft: UIView?

        self.actions.forEach { action in
            action.view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
            view.addSubview(action.view)

            if currentLeft == nil {
                let bindings:[String: UIView] = [
                    "actionView": action.view
                ]
                _ = view.addConstraints(format: "V:|-(0)-[actionView]-(0)-|",
                                        metrics: metrics,
                                        views: bindings)
                _ = view.addConstraints(format: "|-(0)-[actionView]",
                                        metrics: metrics,
                                        views: bindings)

            } else {
                let separatorView = UIView(color: controller.settings.view.separatorColor)
                view.addSubview(separatorView)

                let bindings:[String: UIView] = [
                    "actionView": action.view,
                    "separatorView": separatorView,
                    "currentLeft": currentLeft!
                ]

                _ = view.addConstraints(format: "V:|-(0)-[actionView]-(0)-|",
                                        metrics: metrics,
                                        views: bindings)
                _ = view.addConstraints(format: "V:|-(0)-[separatorView]-(0)-|",
                                        metrics: metrics,
                                        views: bindings)
                _ = view.addConstraints(format: "[currentLeft(==actionView)]-(actionHorizontalMargin)-[separatorView(separatorHeight)]-(actionHorizontalMargin)-[actionView(==currentLeft)]",
                                        metrics: metrics,
                                        views: bindings)
            }

            currentLeft = action.view
        }

        let bindings:[String: UIView] = [
            "currentLeft": currentLeft!
        ]

        _ = view.addConstraints(format: "[currentLeft]-(0)-|",
                                metrics: metrics,
                                views: bindings)
        
        return view
    }
}
