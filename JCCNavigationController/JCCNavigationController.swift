//
//  JCCNavigationController.swift
//  iHealthSwift
//
//  Created by chars on 2018/7/12.
//  Copyright © 2018年 chars. All rights reserved.
//

import UIKit

enum EdgeDirection: Int {
    case None
    case Left
    case Right
}

let JCCNavigationEdgeGestureDidChangedNotificationName: String = "JCCNavigationEdgeGestureDidChangedNotification"
let JCCNavigationEdgeGestureEnableStatusKey: String = "JCCNavigationEdgeGestureEnableStatus"

class JCCNavigationController: UIViewController, UIGestureRecognizerDelegate {
    var viewControllers: NSMutableArray = NSMutableArray()
    var gestures: NSMutableArray = NSMutableArray()

    var blackMask: UIView?
    var animationing: Bool = false
    var percentageOffsetFromLeft: CGFloat = 0
    var panOrigin: CGPoint = CGPoint(x: 0, y: 0)

    let AnimationDuration: TimeInterval = 0.5 // Push / Pop 动画持续时间
    let MaxBlackMaskAlpha: CGFloat = 0.8 // 黑色背景透明度
    let ZoomRatio: CGFloat = 0.95 // 后面视图缩放比
    let ShadowOpacity: Float = 0.8 // 滑动返回时当前视图的阴影透明度
    let ShadowRadius: CGFloat = 8.0 // 滑动返回时当前视图的阴影半径

    var breakEdgeGesture: Bool = false // 中断左滑手势操作

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.currentViewController != nil {
            return self.currentViewController.preferredStatusBarStyle
        } else {
            return UIStatusBarStyle.default
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func loadView() {
        super.loadView()

        let viewRect = viewBoundsWithOrientation(orientation: interfaceOrientation)

        let rootViewController = viewControllers.firstObject as! UIViewController
        rootViewController.willMove(toParent: self)
        addChild(rootViewController)

        let rootView = rootViewController.view as UIView
        rootView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue) | UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue)))
        rootView.frame = viewRect
        view.addSubview(rootView)
        rootViewController.didMove(toParent: self)

        let blackMask = UIView(frame: viewRect)
        blackMask.backgroundColor = UIColor.black
        blackMask.alpha = 0
        blackMask.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue) | UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue)))
        view.insertSubview(blackMask, at: 0)
        self.blackMask = blackMask

        view.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue) | UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue)))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        viewControllers.add(rootViewController)

        NotificationCenter.default.addObserver(self, selector: #selector(edgeGestureDidChanged(sender:)), name: NSNotification.Name(rawValue: JCCNavigationEdgeGestureDidChangedNotificationName), object: nil)
    }

    @objc func edgeGestureDidChanged(sender: Notification) {
        let userInfo: NSDictionary? = sender.userInfo as NSDictionary?
        let status: Bool = ((userInfo?.object(forKey: JCCNavigationEdgeGestureEnableStatusKey)) != nil)
        breakEdgeGesture = status
    }

    func viewBoundsWithOrientation(orientation: UIInterfaceOrientation) -> CGRect {
        var bounds: CGRect = UIScreen.main.bounds

        if UIApplication.shared.isStatusBarHidden {
            return bounds
        } else if orientation.isLandscape {
            let width = bounds.size.width

            bounds.size.width = bounds.size.height
            bounds.size.height = width

            return bounds
        } else {
            return bounds
        }
    }

    var currentViewController: UIViewController {
        var result: UIViewController?

        if viewControllers.count > 0 {
            result = viewControllers.lastObject as? UIViewController
        }
        return result!
    }

    var previousViewController: UIViewController {
        var result: UIViewController?

        if viewControllers.count > 1 {
            result = viewControllers.object(at: viewControllers.count - 2) as? UIViewController
        }
        return result!
    }

    func addEdgeGestureToView(view: UIView) {
        let edgeGesture: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(gestureRecognizerDidEdge(sender:)))
        edgeGesture.delegate = self
        edgeGesture.edges = UIRectEdge.left
        view.addGestureRecognizer(edgeGesture)

        gestures.add(edgeGesture)
    }

    @objc func gestureRecognizerDidEdge(sender: UIScreenEdgePanGestureRecognizer) {
        if breakEdgeGesture || animationing {
            return
        }

        let currentPoint = sender.translation(in: view)
        let x = currentPoint.x + panOrigin.x

        var edgeDirection = EdgeDirection.None
        let vel = sender.velocity(in: view)

        if vel.x > 0 {
            edgeDirection = EdgeDirection.Right
        } else {
            edgeDirection = EdgeDirection.Left
        }

        var offset: CGFloat = 0

        let currentVC = currentViewController
        offset = currentVC.view.frame.width - x
        currentVC.view.layer.shadowColor = UIColor.black.cgColor
        currentVC.view.layer.shadowOpacity = ShadowOpacity
        currentVC.view.layer.shadowRadius = ShadowRadius

        percentageOffsetFromLeft = offset / viewBoundsWithOrientation(orientation: interfaceOrientation).width
        currentVC.view.frame = getSlidingRectWithPercentageOffset(percentage: percentageOffsetFromLeft, orientation: interfaceOrientation)
        transformAtPercentage(percentage: percentageOffsetFromLeft)

        if sender.state == UIGestureRecognizer.State.cancelled || sender.state == UIGestureRecognizer.State.ended {
            if abs(vel.x) > 100 {
                completeSlidingAnimationWithDirection(direction: edgeDirection)
            } else {
                completeSlidingAnimationWithOffset(offset: offset)
            }
        }
    }

    func getSlidingRectWithPercentageOffset(percentage: CGFloat, orientation: UIInterfaceOrientation) -> CGRect {
        let viewRect = viewBoundsWithOrientation(orientation: orientation)
        var rectToReturn: CGRect = CGRect()
        rectToReturn.size = viewRect.size
        rectToReturn.origin = CGPoint(x: max(0, (1 - percentage) * viewRect.width), y: 0)

        return rectToReturn
    }

    func transformAtPercentage(percentage: CGFloat) {
        let transf: CGAffineTransform = CGAffineTransform.identity
        let newTransformValue = 1 - percentage * (1 - ZoomRatio)
        let newAlphaValue = percentage * MaxBlackMaskAlpha
        previousViewController.view.transform = transf.scaledBy(x: newTransformValue, y: newTransformValue)
        blackMask?.alpha = newAlphaValue
    }

    func completeSlidingAnimationWithDirection(direction: EdgeDirection) {
        if direction == EdgeDirection.Right {
            popViewController()
        } else {
            rollBackViewController()
        }
    }

    func completeSlidingAnimationWithOffset(offset: CGFloat) {
        if offset < viewBoundsWithOrientation(orientation: interfaceOrientation).width * 0.5 {
            popViewController()
        } else {
            rollBackViewController()
        }
    }

    func rollBackViewController() {
        if animationing {
            return
        }

        let currentVC = currentViewController
        let previousVC = previousViewController
        let rect = CGRect(x: 0, y: 0, width: currentVC.view.frame.width, height: currentVC.view.frame.height)

        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            let transf: CGAffineTransform = CGAffineTransform.identity
            previousVC.view.transform = transf.scaledBy(x: self.ZoomRatio, y: self.ZoomRatio)
            currentVC.view.frame = rect
            self.blackMask?.alpha = self.MaxBlackMaskAlpha
        }) { finished in
            if finished {
                self.animationing = false
            }
        }
    }

    public func pushViewController(viewController: UIViewController) {
        pushViewController(viewController: viewController, completion: nil)
    }

    public func pushViewController(viewController: UIViewController, completion: (() -> Swift.Void)?) {
        animationing = true

        viewController.view.layer.shadowColor = UIColor.black.cgColor
        viewController.view.layer.shadowOpacity = ShadowOpacity
        viewController.view.layer.shadowRadius = ShadowRadius

        viewController.view.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        viewController.view.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue) | UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue)))
        blackMask?.alpha = 0
        viewController.willMove(toParent: self)
        addChild(viewController)

        view.bringSubviewToFront(blackMask!)
        view.addSubview(viewController.view)

        UIView.animate(withDuration: AnimationDuration, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            let transf: CGAffineTransform = CGAffineTransform.identity
            self.currentViewController.view.transform = transf.scaledBy(x: self.ZoomRatio, y: self.ZoomRatio)
            viewController.view.frame = self.view.bounds
            self.blackMask?.alpha = self.MaxBlackMaskAlpha
        }) { finished in
            if finished {
                self.viewControllers.add(viewController)
                viewController.didMove(toParent: self)

                self.animationing = false
                self.gestures = NSMutableArray()
                self.addEdgeGestureToView(view: self.currentViewController.view)

                if completion != nil {
                    completion!()
                }
            }
        }
    }

    public func popViewController() {
        popViewControllerCompletion(completion: nil)
    }

    public func popViewControllerCompletion(completion: (() -> Swift.Void)?) {
        if viewControllers.count < 2 {
            return
        }

        animationing = true

        let currentVC = currentViewController
        let previousVC = previousViewController
        previousVC.viewWillAppear(false)

        currentVC.view.layer.shadowColor = UIColor.black.cgColor
        currentVC.view.layer.shadowOpacity = ShadowOpacity
        currentVC.view.layer.shadowRadius = ShadowRadius

        UIView.animate(withDuration: AnimationDuration, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            currentVC.view.frame = self.view.bounds.offsetBy(dx: self.view.bounds.width, dy: 0)
            let transf: CGAffineTransform = CGAffineTransform.identity
            previousVC.view.transform = transf.scaledBy(x: 1.0, y: 1.0)
            previousVC.view.frame = self.view.bounds
            self.blackMask?.alpha = 0
        }) { finished in
            if finished {
                currentVC.view.removeFromSuperview()
                currentVC.willMove(toParent: nil)

                self.view.bringSubviewToFront(self.previousViewController.view)
                currentVC.removeFromParent()
                currentVC.didMove(toParent: nil)

                self.viewControllers.remove(currentVC)
                self.animationing = false
                previousVC.viewDidAppear(false)

                if completion != nil {
                    completion!()
                }
            }
        }
    }

    public func popToViewController(toViewController: UIViewController) {
        let controllers: NSMutableArray = viewControllers.mutableCopy() as! NSMutableArray
        let index = controllers.index(of: toViewController)
        var needRemoveViewController: UIViewController?

        for i in index + 1 ... controllers.count - 2 {
            needRemoveViewController = controllers.object(at: i) as? UIViewController
            needRemoveViewController?.view.alpha = 0
            needRemoveViewController?.removeFromParent()
            controllers.remove(needRemoveViewController as Any)
        }

        popViewController()
    }

    public func popToRootViewController() {
        let rootViewController: UIViewController = viewControllers.object(at: 0) as! UIViewController
        popToViewController(toViewController: rootViewController)
    }
}

/// Helper UIViewController extension.
extension UIViewController {
    var jccNavigationController: JCCNavigationController {
        var result: JCCNavigationController?
        var view: UIView = self.view

        var responder: UIResponder? = view.next

        while responder != nil {
            if (responder?.isKind(of: JCCNavigationController.self))! {
                result = responder as? JCCNavigationController
                return result!
            }

            view = view.superview!
            responder = view.next
        }

        return result!
    }
}
