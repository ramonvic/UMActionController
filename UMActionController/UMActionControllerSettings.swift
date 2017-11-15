//
//  UMActionControllerSettings.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 12/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

public struct UMActionControllerSettings {

    public struct Behavior {
        public var hideOnTap = true
        public var disableMotion = false
        public var disableBouncing = false
        public var disableBlur = true
        public var disableBlurForContentView = false
        public var disableBlurForBackgroundView = false
        public var actionWaitControllerClose = true
        public var actionDismissesActionController = true
    }

    public struct ViewStyle {
        public var cornerRadius = CGFloat(0)
        public var backgroundColor = UIColor.white
        public var separatorColor = UIColor.clear
        public var horizontalMargin = CGFloat(0)
        public var verticalMargin = CGFloat(0)
        public var marginTop = CGFloat(30)
        public var marginBottom = CGFloat(0)
    }

    public struct TitleStyle {
        public var textColor = UIColor.gray
        public var font: UIFont? = UIFont(name: "HelveticaNeue-Light", size: 24)
        public var textAlignment = NSTextAlignment.left
        public var horizontalMargin = CGFloat(16)
        public var marginBottom = CGFloat(10)
    }

    public struct MessageStyle {
        public var textColor = UIColor.gray
        public var font: UIFont? = UIFont(name: "HelveticaNeue-Light", size: 17)
        public var textAlignment = NSTextAlignment.left
        public var horizontalMargin = CGFloat(16)
    }

    public struct ActionStyle {
        public var horizontalMargin = CGFloat(16)
        public var verticalMargin = CGFloat(16)

        public var buttonHeight = CGFloat(55)
        public var font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        public var backgroundColor = UIColor.black
        public var textColor = UIColor.white
        public var borderColor = UIColor.black
    }

    public struct CancelActionStyle {
        public var font = UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
        public var backgroundColor = UIColor.white
        public var textColor = UIColor.black
        public var borderColor: UIColor = UIColor.black
    }

    public struct DestructiveActionStyle {
        public var font = UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
        public var backgroundColor = UIColor.white
        public var textColor = UIColor.red
        public var borderColor: UIColor = UIColor.red
    }

    public struct DismissAnimationStyle {
        public var delay = TimeInterval(0.0)
        public var duration = TimeInterval(0.2)
    }

    public struct PresentAnimationStyle {
        public var damping = CGFloat(0.6)
        public var delay = TimeInterval(0.0)
        public var duration = TimeInterval(0.6)
    }

    public struct AnimationStyle {
        public var type: UMActionControllerTransitionType = .slide
        public var present = PresentAnimationStyle()
        public var dismiss = DismissAnimationStyle()
    }

    public var behavior = Behavior()
    public var view = ViewStyle()
    public var title = TitleStyle()
    public var message = MessageStyle()
    public var cancel = CancelActionStyle()
    public var destructive = DestructiveActionStyle()
    public var action = ActionStyle()
    public var animation = AnimationStyle()

    public static var `default`: UMActionControllerSettings {
        return UMActionControllerSettings()
    }
}
