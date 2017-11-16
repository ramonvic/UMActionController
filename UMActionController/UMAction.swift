//
//  UMAction.swift
//  RMActionController-Demo
//
//  Created by Ramon Vicente on 11/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

public enum UMActionStyle : Int {
    case done
    case cancel
    case destructive
    case additional
    public static var `default` = UMActionStyle.done
}

open class UMAction<T> : NSObject where T : UIView {

    open var handler: ((UMActionController<T>) -> Swift.Void)?

    public var style: UMActionStyle = .default
    open private(set) var title: String?
    open private(set) var image: UIImage?
    open var controller: UMActionController<T>!

    open lazy var view: UIView! = {
        let view = self.loadView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    open var isCancel: Bool {
        return self.style == .cancel
    }

    open var isDestructive: Bool {
        return self.style == .destructive
    }

    public convenience init(title: String, style: UMActionStyle, andHandler handler: ((UMActionController<T>) -> Swift.Void)? = nil) {
        self.init(style: style, andHandler: handler)
        self.title = title
    }

    public convenience init(image: UIImage, style: UMActionStyle, andHandler handler: ((UMActionController<T>) -> Swift.Void)? = nil) {
        self.init(style: style, andHandler: handler)
        self.image = image
    }

    public convenience init(title: String, image: UIImage, style: UMActionStyle, andHandler handler: ((UMActionController<T>) -> Swift.Void)? = nil) {
        self.init(style: style, andHandler: handler)
        self.title = title
        self.image = image
    }

    public convenience init(style: UMActionStyle, andHandler handlerAction: ((UMActionController<T>) -> Swift.Void)? = nil) {
        self.init()
        self.style = style
        self.handler = { controller in

            if !controller.settings.behavior.actionWaitControllerClose {
                if let handlerAction = handlerAction {
                    handlerAction(controller)
                }
            }

            if controller.settings.behavior.actionDismissesActionController ||
                controller.settings.behavior.actionWaitControllerClose {
                let animated = (controller.modalPresentationStyle == .popover || controller.yConstraint != nil)
                controller.dismiss(animated: animated, completion: { 
                    if controller.settings.behavior.actionWaitControllerClose, let handlerAction = handlerAction {
                        handlerAction(controller)
                    }
                })
            }
        }
    }

    public override init() {
        super.init()
    }

    open func loadView() -> UIView {

        let actionButton = UIButton(type: .custom)
        actionButton.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        actionButton.layer.borderWidth = 1.0

        if self.isCancel {
            actionButton.titleLabel?.font = controller.settings.cancel.font
            actionButton.setTitleColor(controller.settings.cancel.textColor, for: .normal)

            actionButton.layer.borderColor = self.controller.settings.cancel.borderColor.cgColor
        } else if self.isDestructive {
            actionButton.titleLabel?.font = controller.settings.destructive.font
            actionButton.setTitleColor(controller.settings.destructive.textColor, for: .normal)

            actionButton.layer.borderColor = self.controller.settings.destructive.borderColor.cgColor
        } else {
            actionButton.titleLabel?.font = controller.settings.action.font
            actionButton.setTitleColor(controller.settings.action.textColor, for: .normal)
            actionButton.setTitleColor(controller.settings.action.textColor.withAlphaComponent(0.8), for: .disabled)

            actionButton.layer.borderColor = self.controller.settings.action.borderColor.cgColor
        }

        actionButton.layer.cornerRadius = 4
        actionButton.layer.masksToBounds = true

        if !self.controller.settings.behavior.disableBlur {
            actionButton.setBackgroundImage(UIImage(color: UIColor.white.withAlphaComponent(0.3)), for: .highlighted)
        } else {
            var backgroundColor = controller.settings.action.backgroundColor
            switch self.controller.style {
            case .white:
                if self.isCancel || self.isDestructive {
                    backgroundColor = controller.settings.cancel.backgroundColor
                } else if isDestructive {
                    backgroundColor = controller.settings.destructive.backgroundColor
                }
                break;
            case .black:
                backgroundColor = UIColor(white: 0.2, alpha: 1)
                break;
            }

            actionButton.setBackgroundImage(UIImage(color: backgroundColor), for: .normal)
            actionButton.setBackgroundImage(UIImage(color: backgroundColor), for: .highlighted)
            actionButton.setBackgroundImage(UIImage(color: backgroundColor), for: .disabled)
        }

        if self.title != nil {
            actionButton.setTitle(self.title, for: .normal)
        } else if self.image != nil {
            actionButton.setImage(self.image, for: .normal)
        }

        let metrics = [
            "buttonHeight": controller.settings.action.buttonHeight
        ]

        let bindings = [
            "actionButton": actionButton
        ]

        _ = actionButton.addConstraints(format: "V:[actionButton(buttonHeight)]",
                                             metrics: metrics,
                                             views: bindings)

        return actionButton;
    }

    @objc open func actionTapped(_ sender: Any?) {
        if let handler = self.handler {
            handler(self.controller)
        }
    }

    func executeHandlerOfCancelActionWithController(_ controller: UMActionController<T>) {
        if self.style == .cancel, let handler = handler {
            handler(controller)
        }
    }
}
