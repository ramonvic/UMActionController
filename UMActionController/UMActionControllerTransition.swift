//
//  UMActionControllerTransition.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 12/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

public enum UMActionControllerTransitionType : Int {
    case fade
    case slide
}

public enum UMActionControllerTransitionStyle : Int {
    case presenting
    case dismissing
}

class UMActionControllerTransition: NSObject, UIViewControllerAnimatedTransitioning  {

    public var animationStyle: UMActionControllerTransitionStyle!

    init(style animationStyle: UMActionControllerTransitionStyle) {
        super.init()
        self.animationStyle = animationStyle
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {

        if self.animationStyle == .presenting {
            if let toVC = transitionContext?.viewController(forKey: .to) as? UMActionController {
                return toVC.settings.behavior.disableBouncing ? 0.3 : toVC.settings.animation.present.duration
            }
        } else {
            if let fromVC = transitionContext?.viewController(forKey: .from) as? UMActionController {
                return fromVC.settings.animation.dismiss.duration
            }
        }


        return 1.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        let duration = self.transitionDuration(using: transitionContext)

        if self.animationStyle == .presenting {
            if let actionController = transitionContext.viewController(forKey: .to) as? UMActionController {

                var damping: CGFloat = 1.0
                var delay = 0.0

                if !actionController.settings.behavior.disableBouncing {
                    damping = actionController.settings.animation.present.damping
                    delay = actionController.settings.animation.present.delay
                }

                actionController.setupTopContainersTopMarginConstraint()

                actionController.backgroundView.alpha = 0;
                containerView.addSubview(actionController.backgroundView)
                containerView.addSubview(actionController.view)

                let bindings:[String: UIView] = [
                    "backgroundView": actionController.backgroundView
                ]

                _ = containerView.addConstraints(format: "V:|-(0)-[backgroundView]-(0)-|", views: bindings)
                _ = containerView.addConstraints(format: "|-(0)-[backgroundView]-(0)-|", views: bindings)

                let centerConstraint = NSLayoutConstraint(item: actionController.view,
                                                          attribute: .centerX, relatedBy: .equal,
                                                          toItem: containerView, attribute: .centerX,
                                                          multiplier: 1, constant: 0)
                let widthConstraint = NSLayoutConstraint(item: actionController.view,
                                                         attribute: .width, relatedBy: .equal,
                                                         toItem: containerView, attribute: .width,
                                                         multiplier: 1, constant: 0)

                containerView.addConstraint(centerConstraint)
                containerView.addConstraint(widthConstraint)

                actionController.yConstraint = NSLayoutConstraint(item: actionController.view,
                                                                  attribute: .bottom, relatedBy: .equal,
                                                                  toItem: containerView, attribute: .bottom,
                                                                  multiplier: 1, constant: 50)

                containerView.addConstraint(actionController.yConstraint!)

                containerView.setNeedsUpdateConstraints()
                containerView.layoutIfNeeded()

                containerView.removeConstraint(actionController.yConstraint!)

                actionController.yConstraint = NSLayoutConstraint(item: actionController.view,
                                                                  attribute: .bottom, relatedBy: .equal,
                                                                  toItem: containerView, attribute: .bottom,
                                                                  multiplier: 1, constant: 0)

                containerView.addConstraint(actionController.yConstraint!)

                containerView.setNeedsUpdateConstraints()

                actionController.view.alpha = 0.0
                actionController.backgroundView.alpha = 0.0

                if actionController.settings.animation.type == .slide {
                    UIView.animate(withDuration: duration,
                                   delay: delay, usingSpringWithDamping: damping,
                                   initialSpringVelocity: 1,
                                   options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                                    actionController.backgroundView.alpha = 1
                                    actionController.view.alpha = 1.0
                                    containerView.layoutIfNeeded()
                    }, completion: { (finished) in
                        transitionContext.completeTransition(finished)
                    })
                } else {
                    containerView.layoutIfNeeded()
                    UIView.animate(withDuration: duration, animations: {
                        actionController.backgroundView.alpha = 1.0
                        actionController.view.alpha = 1.0
                    }, completion: { (finished) in
                        transitionContext.completeTransition(finished)
                    })
                }
            }

        } else if self.animationStyle == .dismissing {
            if let actionController = transitionContext.viewController(forKey: .from) as? UMActionController {

                let delay = actionController.settings.animation.dismiss.delay

                if actionController.settings.animation.type == .slide {
                    containerView.removeConstraint(actionController.yConstraint!)
                    actionController.yConstraint = NSLayoutConstraint(item: actionController.view,
                                                                      attribute: .bottom, relatedBy: .equal,
                                                                      toItem: containerView, attribute: .bottom,
                                                                      multiplier: 1, constant: 50)
                    containerView.addConstraint(actionController.yConstraint!)

                    containerView.setNeedsUpdateConstraints()

                    UIView.animate(withDuration: duration, delay: delay, options: .beginFromCurrentState, animations: {
                        actionController.backgroundView.alpha = 0
                        actionController.view.alpha = 0.0
                        containerView.layoutIfNeeded()
                    }, completion: { (finished) in
                        actionController.view.removeFromSuperview()
                        actionController.backgroundView.removeFromSuperview()

                        actionController.hasBeenDismissed = false
                        transitionContext.completeTransition(finished)
                    })
                } else {
                    containerView.layoutIfNeeded()
                    UIView.animate(withDuration: duration, delay: delay, options: .beginFromCurrentState, animations: {
                        actionController.backgroundView.alpha = 0.0
                        actionController.view.alpha = 0.0
                    }, completion: { (finished) in
                        actionController.view.removeFromSuperview()
                        actionController.backgroundView.removeFromSuperview()
                        
                        actionController.hasBeenDismissed = false
                        transitionContext.completeTransition(finished)
                    })
                }
            }
        }
    }
}
