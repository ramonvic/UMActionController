//
//  UMActionController.swift
//  UMActionController-Demo
//
//  Created by Ramon Vicente on 11/08/17.
//  Copyright © 2017 Roland Moers. All rights reserved.
//

import UIKit

extension UIView {
    public convenience init(color: UIColor) {
        self.init(frame: .zero)
        self.backgroundColor = color
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

public enum UMActionControllerStyle : Int {

    case white
    case black

    public static var `default` = UMActionControllerStyle.white
}

open class UMActionController<T> : UIViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate where T : UIView {

    open private(set) var style: UMActionControllerStyle = .default

    open var settings: UMActionControllerSettings = UMActionControllerSettings.default

    open override var title: String? {
        didSet {
            self.headerTitleLabel.text = title
        }
    }
    open var message: String? {
        didSet {
            self.headerMessageLabel.text = message
        }
    }

    var hasBeenDismissed: Bool = false

    var yConstraint: NSLayoutConstraint?

    open var contentView: T!

    open var actions: [UMAction<T>] {
        var actions = self.additionalActions
        actions!.append(contentsOf: self.cancelActions)
        actions!.append(contentsOf: doneActions)
        return actions!
    }

    fileprivate var additionalActions: [UMAction<T>]!
    fileprivate var doneActions: [UMAction<T>]!
    fileprivate var cancelActions: [UMAction<T>]!

    fileprivate var topContainer: UIView!
    fileprivate var bottomContainer: UIView!

    fileprivate lazy var headerTitleLabel: UILabel! = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    fileprivate lazy var headerMessageLabel: UILabel! = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    public lazy var backgroundView: UIView = {
        var backgroundView: UIView!

        if self.internalDisableBlurEffectsForBackgroundView {
            backgroundView = UIView(frame: .zero)
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4);
        } else {
            let effect = UIBlurEffect(style: self.backgroundBlurEffectStyleForCurrentStyle)
            backgroundView = UIVisualEffectView(effect: effect)
        }

        backgroundView.translatesAutoresizingMaskIntoConstraints = false;

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped))
        backgroundView.addGestureRecognizer(tapRecognizer)

        return backgroundView
    }()

    var backgroundBlurEffectStyleForCurrentStyle: UIBlurEffectStyle {
        switch self.style {
        case .black:
            return .light;
        default:
            return .dark;
        }
    }

    var containerBlurEffectStyleForCurrentStyle: UIBlurEffectStyle {
        switch self.style {
        case .black:
            return .dark;
        default:
            return .extraLight;
        }
    }

    fileprivate var internalDisableBlurEffects: Bool {
        if UIAccessibilityIsReduceTransparencyEnabled() {
            return true
        }

        return self.settings.behavior.disableBlur
    }

    fileprivate var internalDisableBlurEffectsForContentView: Bool {
        if self.internalDisableBlurEffects {
            return true
        }
        return self.settings.behavior.disableBlurForContentView
    }

    fileprivate var internalDisableBlurEffectsForBackgroundView: Bool {
        if self.internalDisableBlurEffects {
            return true
        }
        return self.settings.behavior.disableBlurForBackgroundView
    }

    fileprivate var internalDisableBouncingEffects: Bool {
        guard !UIAccessibilityIsReduceMotionEnabled() else {
            return true
        }

        return self.settings.behavior.disableBouncing
    }

    fileprivate var internalDisableMotionEffects: Bool {
        guard !UIAccessibilityIsReduceMotionEnabled() else {
            return true
        }

        return self.settings.behavior.disableMotion
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(style aStyle: UMActionControllerStyle, title aTitle: String? = nil, message aMessage: String? = nil, select selectAction: UMAction<T>? = nil, andCancel cancelAction: UMAction<T>? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.setup()

        self.style = aStyle
        self.title = aTitle
        self.message = aMessage

        if let selectAction = selectAction,
            let cancelAction = cancelAction {
            cancelAction.style = .cancel
            let actions: [UMAction<T>] = [cancelAction, selectAction]
            let groupedAction = UMGroupedAction(style: .default, andActions: actions)
            self.addAction(groupedAction)
        } else {
            if let cancelAction = cancelAction {
                cancelAction.style = .cancel
                self.addAction(cancelAction)
            }

            if let selectAction = selectAction {
                self.addAction(selectAction)
            }
        }

        self.prepare()
    }

    open func prepare() {

    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.translatesAutoresizingMaskIntoConstraints = true;
        self.view.backgroundColor = .clear;
        self.view.layer.masksToBounds = true;

        self.setupUIElements()
        self.setupContainerElements()

        if self.modalPresentationStyle != .popover {
            self.view.addSubview(self.backgroundView)

            let bindings:[String: UIView] = [
                "backgroundView": self.backgroundView
            ]

            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[backgroundView]-(0)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: bindings)

            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|-(0)-[backgroundView]-(0)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: bindings)

            self.view.addConstraints(verticalConstraints)
            self.view.addConstraints(horizontalConstraints)
        }

        self.view.addSubview(self.topContainer)
        if cancelActions.count > 0 {
            self.view.addSubview(self.bottomContainer)
        }

        self.setupConstraints()

        if self.modalPresentationStyle == .popover {
            self.setupTopContainersTopMarginConstraint()
        }

        if !self.internalDisableMotionEffects {
            let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            verticalMotionEffect.minimumRelativeValue = -10
            verticalMotionEffect.maximumRelativeValue = 10

            let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontalMotionEffect.minimumRelativeValue = -10
            horizontalMotionEffect.maximumRelativeValue = 10

            let motionEffectGroup = UIMotionEffectGroup()
            motionEffectGroup.motionEffects = [verticalMotionEffect, horizontalMotionEffect]
            self.view.addMotionEffect(motionEffectGroup)
        }

        let minimalSize = self.view.systemLayoutSizeFitting(CGSize(width: 999, height: 999))
        self.preferredContentSize = CGSize(width: minimalSize.width, height: minimalSize.height + 10)

        if self.responds(to: #selector(getter: popoverPresentationController)) {
            self.popoverPresentationController?.delegate = self
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.hasBeenDismissed = false
    }

    @objc
    func backgroundViewTapped() {
        if self.settings.behavior.hideOnTap {
            self.handleCancelNotAssociatedWithAnyButton()
        }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        switch self.style {
        case .black:
            return .default
        default:
            return .lightContent;
        }
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return UMActionControllerTransition(style: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return UMActionControllerTransition(style: .dismissing);
    }

    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.handleCancelNotAssociatedWithAnyButton()
    }
}

extension UMActionController {
    fileprivate func setup() {
        self.additionalActions = []
        self.doneActions = []
        self.cancelActions = []

        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self
    }

    fileprivate func setupUIElements() {
        self.headerTitleLabel.font = self.settings.title.font
        self.headerTitleLabel.textColor = self.settings.title.textColor
        self.headerTitleLabel.textAlignment = self.settings.title.textAlignment
        self.headerTitleLabel.sizeToFit()

        self.headerMessageLabel.font = self.settings.message.font
        self.headerMessageLabel.textColor = self.settings.message.textColor
        self.headerMessageLabel.textAlignment = self.settings.message.textAlignment
        self.headerMessageLabel.sizeToFit()
    }

    fileprivate func setupContainerElements() {
        if self.internalDisableBlurEffects {
            self.topContainer = UIView(frame: .zero)
            self.topContainer.addSubview(self.contentView)

            if self.title != nil {
                self.headerTitleLabel.text = self.title
                self.topContainer.addSubview(self.headerTitleLabel)
            }

            if self.message != nil {
                self.headerMessageLabel.text = self.message
                self.topContainer.addSubview(self.headerMessageLabel)
            }

            self.additionalActions.forEach {
                self.topContainer.addSubview($0.view)
            }

            self.doneActions.forEach {
                self.topContainer.addSubview($0.view)
            }
        } else {

            let blur = UIBlurEffect(style: self.containerBlurEffectStyleForCurrentStyle)
            let vibrancy = UIVibrancyEffect(blurEffect: blur)

            let vibrancyView = UIVisualEffectView(effect: vibrancy)
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            if !self.internalDisableBlurEffectsForContentView {
                vibrancyView.contentView.addSubview(self.contentView)
            }

            if self.title != nil {
                self.headerTitleLabel.text = self.title
                vibrancyView.contentView.addSubview(self.headerTitleLabel)
            }

            if self.message != nil {
                self.headerMessageLabel.text = self.message
                vibrancyView.contentView.addSubview(self.headerMessageLabel)
            }

            self.additionalActions.forEach {
                vibrancyView.contentView.addSubview($0.view)
            }

            self.doneActions.forEach {
                vibrancyView.contentView.addSubview($0.view)
            }

            let container = UIVisualEffectView(effect: blur)
            container.contentView.addSubview(vibrancyView)

            self.topContainer = container

            if self.internalDisableBlurEffectsForContentView {
                self.topContainer.addSubview(self.contentView)
            }
        }

        if self.internalDisableBlurEffects {
            self.bottomContainer = UIView(frame: .zero)

            self.cancelActions.forEach {
                self.bottomContainer.addSubview($0.view)
            }
        } else {

            let blur = UIBlurEffect(style: self.containerBlurEffectStyleForCurrentStyle)
            let vibrancy = UIVibrancyEffect(blurEffect: blur)

            let vibrancyView = UIVisualEffectView(effect: vibrancy)
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.cancelActions.forEach {
                vibrancyView.contentView.addSubview($0.view)
            }

            let container = UIVisualEffectView(effect: blur)
            container.contentView.addSubview(vibrancyView)

            self.bottomContainer = container
        }

        //Container properties
        self.topContainer.layer.cornerRadius = self.settings.view.cornerRadius
        self.topContainer.clipsToBounds = true;
        self.topContainer.translatesAutoresizingMaskIntoConstraints = false;

        if self.internalDisableBlurEffects {
            self.topContainer.backgroundColor = self.settings.view.backgroundColor;
        } else {
            self.topContainer.backgroundColor = .clear;
        }

        self.bottomContainer.layer.cornerRadius = self.settings.view.cornerRadius;
        self.bottomContainer.clipsToBounds = true;
        self.bottomContainer.translatesAutoresizingMaskIntoConstraints = false;

        if self.internalDisableBlurEffects {
            self.bottomContainer.backgroundColor = self.settings.view.backgroundColor;
        } else {
            self.bottomContainer.backgroundColor = .clear;
        }
    }

    func setupConstraints() {

        var metrics: [String : Any] = [
            "separatorHeight": (1.0 / UIScreen.main.scale),
            "horizontalMargin": self.settings.view.horizontalMargin,
            "verticalMargin": self.settings.view.verticalMargin,
            "titleLabelHorizontal": self.settings.title.horizontalMargin,
            "titleLabelMarginBottom": self.settings.title.marginBottom,
            "titleLabelMarginTop": self.settings.view.marginTop,
            "messageLabelHorizontal": self.settings.message.horizontalMargin,
            "actionHorizontalMargin": self.settings.action.horizontalMargin,
            "actionVerticalMargin": self.settings.action.verticalMargin,
            "actionVerticalHalfMargin": self.settings.action.verticalMargin/2
        ]

        let bindings: [String : UIView] = [
            "topContainer": self.topContainer,
            "bottomContainer": self.bottomContainer,
            "headerTitleLabel": self.headerTitleLabel,
            "headerMessageLabel": self.headerMessageLabel
        ]

        //Container constraints
        _ = self.view.addConstraints(format: "|-(horizontalMargin)-[topContainer]-(horizontalMargin)-|",
                                           metrics: metrics,
                                           views: bindings)

        if self.cancelActions.count > 0 {
            _ = self.view.addConstraints(format: "V:[topContainer]-(verticalMargin)-[bottomContainer]-(verticalMargin)-|",
                                               metrics: metrics,
                                               views: bindings)

            _ = self.view.addConstraints(format: "|-(horizontalMargin)-[bottomContainer]-(horizontalMargin)-|",
                                               metrics: metrics,
                                               views: bindings)
        } else {
            _ = self.view.addConstraints(format: "V:[topContainer]-(verticalMargin)-|",
                                               metrics: metrics,
                                               views: bindings)
        }

        //Top container content constraints
        var currentTopView: UIView?;

        for (index, action) in self.doneActions.enumerated() {
            let separatorView = UIView(color: self.settings.view.separatorColor)
            self.addSubview(separatorView, to: self.topContainer)

            metrics["actionVerticalDynamicMargin"] = index == 0 ? self.settings.action.verticalMargin : self.settings.action.verticalMargin/2

            if currentTopView == nil {
                let bindings: [String : UIView] = [
                    "actionView": action.view,
                    "separatorView": separatorView
                ]

                _ = self.topContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                   metrics: metrics,
                                                   views: bindings)
                _ = self.topContainer.addConstraints(format: "|-(0)-[separatorView]-(0)-|",
                                                   metrics: metrics,
                                                   views: bindings)
                _ = self.topContainer.addConstraints(format: "V:[separatorView(separatorHeight)]-(actionVerticalMargin)-[actionView]-(actionVerticalDynamicMargin)-|",
                                                   metrics: metrics,
                                                   views: bindings)
            } else {
                let bindings: [String : UIView] = [
                    "actionView": action.view,
                    "separatorView": separatorView,
                    "currentTopView": currentTopView!
                ]

                _ = self.topContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                           metrics: metrics,
                                                           views: bindings)
                _ = self.topContainer.addConstraints(format: "|-(0)-[separatorView]-(0)-|",
                                                           metrics: metrics,
                                                           views: bindings)
                _ = self.topContainer.addConstraints(format: "V:[separatorView(separatorHeight)]-(actionVerticalHalfMargin)-[actionView]-(actionVerticalDynamicMargin)-[currentTopView]",
                                                           metrics: metrics,
                                                           views: bindings)
            }

            currentTopView = separatorView
        }

        _ = self.topContainer.addConstraints(format: "|-(0)-[contentView]-(0)-|",
                                                   metrics: metrics,
                                                   views: ["contentView": self.contentView])

        if currentTopView != nil {
            _ = self.topContainer.addConstraints(format: "V:[contentView]-(0)-[currentTopView]",
                                                       metrics: metrics,
                                                       views: ["contentView": self.contentView, "currentTopView": currentTopView!])
        } else {
            _ = self.topContainer.addConstraints(format: "V:[contentView]-(0)-|",
                                                       metrics: metrics,
                                                       views: ["contentView": self.contentView])
        }

        if self.additionalActions.count > 0 || self.message != nil || self.title != nil {
            currentTopView = self.contentView

            self.additionalActions.forEach{ action in
                let separatorView = UIView(color: self.settings.view.separatorColor)
                self.addSubview(separatorView, to: self.topContainer)

                let bindings: [String : UIView] = [
                    "actionView": action.view,
                    "separatorView": separatorView,
                    "currentTopView": currentTopView!
                ]

                _ = self.topContainer.addConstraints(format: "|-(0)-[separatorView]-(0)-|",
                                                           metrics: metrics,
                                                           views: bindings)
                _ = self.topContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                           metrics: metrics,
                                                           views: bindings)
                _ = self.topContainer.addConstraints(format: "V:[actionView]-(actionVerticalMargin)-[separatorView(separatorHeight)]-(actionVerticalMargin)-[currentTopView]",
                                                           metrics: metrics,
                                                           views: bindings)

                currentTopView = action.view
            }

            if self.message != nil || self.title != nil {
                let separatorView = UIView(color: self.settings.view.separatorColor)
                self.addSubview(separatorView, to: self.topContainer)

                let bindings: [String : UIView] = [
                    "separatorView": separatorView,
                    "currentTopView": currentTopView!
                ]

                _ = self.topContainer.addConstraints(format: "|-(0)-[separatorView]-(0)-|",
                                                     metrics: metrics,
                                                     views: bindings)
                _ = self.topContainer.addConstraints(format: "V:[separatorView(separatorHeight)]-(0)-[currentTopView]",
                                                     metrics: metrics,
                                                     views: bindings)

                currentTopView = separatorView

                if self.message != nil {

                    let bindings: [String : UIView] = [
                        "messageLabel": self.headerMessageLabel,
                        "currentTopView": currentTopView!
                    ]

                    _ = self.topContainer.addConstraints(format: "|-(messageLabelHorizontal)-[messageLabel]-(messageLabelHorizontal)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                    _ = self.topContainer.addConstraints(format: "V:[messageLabel]-(10)-[currentTopView]",
                                                         metrics: metrics,
                                                         views: bindings)

                    currentTopView = self.headerMessageLabel
                }

                if self.title != nil {

                    let bindings: [String : UIView] = [
                        "titleLabel": self.headerTitleLabel,
                        "currentTopView": currentTopView!
                    ]

                    _ = self.topContainer.addConstraints(format: "|-(titleLabelHorizontal)-[titleLabel]-(titleLabelHorizontal)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                    _ = self.topContainer.addConstraints(format: "V:[titleLabel]-(titleLabelMarginBottom)-[currentTopView]",
                                                         metrics: metrics,
                                                         views: bindings)

                    currentTopView = self.headerTitleLabel
                }
            }

            let bindings: [String : UIView] = [
                "currentTopView": currentTopView!
            ]

            _ = self.topContainer.addConstraints(format: "V:|-(titleLabelMarginTop)-[currentTopView]",
                                                 metrics: metrics,
                                                 views: bindings)

        } else  {

            let bindings: [String : UIView] = [
                "contentView": self.contentView
            ]

            _ = self.topContainer.addConstraints(format: "V:|-(0)-[contentView]",
                                                 metrics: metrics,
                                                 views: bindings)
        }

        if self.cancelActions.count == 1 {
            let action = self.cancelActions.last!

            let bindings: [String : UIView] = [
                "actionView": action.view
            ]

            _ = self.bottomContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                 metrics: metrics,
                                                 views: bindings)
            _ = self.bottomContainer.addConstraints(format: "V:|-(actionVerticalMargin)-[actionView]-(actionVerticalMargin)-|",
                                                 metrics: metrics,
                                                 views: bindings)
        } else if self.cancelActions.count > 1 {
            currentTopView = nil

            self.cancelActions.forEach { action in
                if currentTopView == nil {
                    let bindings: [String : UIView] = [
                        "actionView": action.view
                    ]
                    _ = self.bottomContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                    _ = self.bottomContainer.addConstraints(format: "V:[actionView]-(actionVerticalMargin)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                } else {
                    let separatorView = UIView(color: self.settings.view.separatorColor)
                    self.addSubview(separatorView, to: self.bottomContainer)

                    let bindings: [String : UIView] = [
                        "actionView": action.view,
                        "currentTopView": currentTopView!,
                        "separatorView": separatorView
                    ]

                    _ = self.bottomContainer.addConstraints(format: "|-(0)-[separatorView]-(0)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                    _ = self.bottomContainer.addConstraints(format: "|-(actionHorizontalMargin)-[actionView]-(actionHorizontalMargin)-|",
                                                         metrics: metrics,
                                                         views: bindings)
                    _ = self.bottomContainer.addConstraints(format: "V:[actionView]-(actionVerticalMargin)-[separatorView(separatorHeight)]-(actionVerticalMargin)-[currentTopView]",
                                                         metrics: metrics,
                                                         views: bindings)

                    currentTopView = action.view
                }
            }

            _ = self.bottomContainer.addConstraints(format: "V:|-(0)-[currentTopView]",
                                                    metrics: metrics,
                                                    views: ["currentTopView": currentTopView!])
        }
    }

    func setupTopContainersTopMarginConstraint() {
        self.view.translatesAutoresizingMaskIntoConstraints = false;

        let metrics: [String : Any] = [
            "verticalMargin": self.settings.view.verticalMargin
        ]

        let bindings: [String : UIView] = [
            "topContainer": self.topContainer
        ]

        _ = self.view.addConstraints(format: "V:|-(verticalMargin)-[topContainer]",
                                                metrics: metrics,
                                                views: bindings)
    }
}

extension UMActionController {
    
    func handleCancelNotAssociatedWithAnyButton() {
        
        for anAction in self.cancelActions + self.doneActions {
            if anAction.isCancel {
                anAction.executeHandlerOfCancelActionWithController(self)
            }
        }
    }
}

extension UMActionController {
    
    open func addAction(_ action: UMAction<T>) {
        switch action.style {
        case .additional:
            self.additionalActions.append(action)
            break;
        case .done:
            self.doneActions.append(action)
            break;
        case .cancel:
            self.cancelActions.append(action)
            break;
        case .destructive:
            self.doneActions.append(action)
            break;
        }
        
        action.controller = self;
    }
    
    func addSubview(_ subView: UIView, to container: UIView) {
        if let container = container as? UIVisualEffectView,
            let subContainer = container.contentView.subviews.first as? UIVisualEffectView {
            subContainer.contentView.addSubview(subView)
        } else {
            container.addSubview(subView)
        }
    }
}
