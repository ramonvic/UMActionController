//
//  UIView+Constraints.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 12/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

extension UIView {

    func addConstraints(format: String, metrics: [String: Any]? = nil, views: [String: Any]? = nil) -> [NSLayoutConstraint] {
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: format,
                                                         options: NSLayoutFormatOptions(rawValue: 0),
                                                         metrics: metrics,
                                                         views: views ?? [:])
        self.addConstraints(constraints)
        return constraints
    }
}
