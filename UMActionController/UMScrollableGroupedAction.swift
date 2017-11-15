//
//  UMScrollableGroupedAction.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 12/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

open class UMScrollableGroupedAction<T> : UMGroupedAction<T> where T : UIView {

    var actionWidth: CGFloat!

    public convenience init?(style: UMActionStyle, actionWidth: CGFloat, andActions actions: [UMAction<T>]) {
        self.init()

        self.style = style
        self.actions = actions
        self.actionWidth = 50
    }

    public override init() {
        super.init()
    }

    open override func loadView() -> UIView {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        var maxHeight = 0
        var currentLeft: UIView?

        self.actions.forEach { (action) in
            scrollView.addSubview(action.view)

            let viewHeight = action.view.systemLayoutSizeFitting(CGSize(width: self.actionWidth, height: 999999),
                                                                 withHorizontalFittingPriority: UILayoutPriorityRequired,
                                                                 verticalFittingPriority: UILayoutPriorityFittingSizeLevel).height
            maxHeight = max(maxHeight, Int(viewHeight))

            if currentLeft == nil {

                let bindings:[String: UIView] = [
                    "actionView": action.view
                ]

                _ = scrollView.addConstraints(format: "V:|-(0)-[actionView]-(>=0)-|",
                                              views: bindings)
                _ = scrollView.addConstraints(format: "|-(0)-[actionView]",
                                              views: bindings)
            } else {

                let bindings:[String: UIView] = [
                    "actionView": action.view,
                    "currentLeft": currentLeft!
                ]

                let metrics: [String : Any] = [
                    "actionWidth": self.actionWidth
                ]

                _ = scrollView.addConstraints(format: "V:|-(0)-[actionView]-(>=0)-|",
                                              metrics: metrics,
                                              views: bindings)
                _ = scrollView.addConstraints(format: "[currentLeft(actionWidth)]-(0)-[actionView(actionWidth)]",
                                              metrics: metrics,
                                              views: bindings)
            }

            currentLeft = action.view
        }

        let bindings:[String: UIView] = [
            "scrollView": scrollView,
            "currentLeft": currentLeft!
        ]
        let metrics: [String : Any] = [
            "scrollViewHeight": maxHeight
        ]

        _ = scrollView.addConstraints(format: "[currentLeft]-(0)-|",
                                      metrics: metrics,
                                      views: bindings)
        _ = scrollView.addConstraints(format: "V:[scrollView(scrollViewHeight)]",
                                      metrics: metrics,
                                      views: bindings)
        
        return scrollView
    }
}
