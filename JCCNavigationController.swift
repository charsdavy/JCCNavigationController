//
//  JCCNavigationController.swift
//  iHealthSwift
//
//  Created by chars on 2018/7/12.
//  Copyright © 2018年 chars. All rights reserved.
//

import UIKit

enum PanDirection : Int {
    case None
    case Left
    case Right
}

class JCCNavigationController: UIViewController, UIGestureRecognizerDelegate {
    var viewControllers : NSMutableArray = NSMutableArray.init()
    var gestures : NSMutableArray = NSMutableArray.init()

    var blackMask : UIView? = nil
    var animationing : Bool = false
    var percentageOffsetFromLeft : CGFloat = 0
    var panOrigin : CGPoint = CGPoint.init(x: 0, y: 0)


    let AnimationDuration : TimeInterval = 0.5 // Push / Pop 动画持续时间
    let MaxBlackMaskAlpha : CGFloat = 0.8 // 黑色背景透明度
    let ZoomRatio : CGFloat = 0.95   // 后面视图缩放比
    let ShadowOpacity : Float = 0.8 // 滑动返回时当前视图的阴影透明度
    let ShadowRadius : CGFloat = 8.0  // 滑动返回时当前视图的阴影半径

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

        let viewRect = self.viewBoundsWithOrientation(orientation: self.interfaceOrientation)

        let rootViewController = viewControllers.firstObject as! UIViewController
        rootViewController.willMove(toParentViewController: self)
        self.addChildViewController(rootViewController)

        let rootView = rootViewController.view as UIView
        rootView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleHeight.rawValue) | UInt8(UIViewAutoresizing.flexibleWidth.rawValue)))
        rootView.frame = viewRect
        self.view.addSubview(rootView)
        rootViewController.didMove(toParentViewController: self)

        let blackMask = UIView.init(frame: viewRect)
        blackMask.backgroundColor = UIColor.black
        blackMask.alpha = 0
        blackMask.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleHeight.rawValue) | UInt8(UIViewAutoresizing.flexibleWidth.rawValue)))
        self.view.insertSubview(blackMask, at: 0)
        self.blackMask = blackMask

        self.view.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleHeight.rawValue) | UInt8(UIViewAutoresizing.flexibleWidth.rawValue)))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers.add(rootViewController)
    }

    func viewBoundsWithOrientation(orientation : UIInterfaceOrientation) -> CGRect {
        var bounds : CGRect = UIScreen.main.bounds

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

    var currentViewController : UIViewController {
        var result : UIViewController? = nil

        if self.viewControllers.count > 0 {
            result = self.viewControllers.lastObject as? UIViewController
        }
        return result!
    }

    var previousViewController : UIViewController {
        var result : UIViewController? = nil

        if self.viewControllers.count > 1 {
            result = self.viewControllers.object(at: viewControllers.count - 2) as? UIViewController
        }
        return result!
    }

    func addPanGestureToView(view: UIView) -> Void {
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(self.gestureRecognizerDidPan(panGesture:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        self.gestures.add(panGesture)
    }

    @objc func gestureRecognizerDidPan(panGesture : UIPanGestureRecognizer) -> Void {
        if self.animationing {
            return
        }

        let currentPoint = panGesture.translation(in: self.view)
        let x = currentPoint.x + self.panOrigin.x

        var panDirection = PanDirection.None
        let vel = panGesture.velocity(in: self.view)

        if vel.x > 0 {
            panDirection = PanDirection.Right
        } else {
            panDirection = PanDirection.Left
        }

        var offset : CGFloat = 0

        let currentVC = self.currentViewController
        offset = currentVC.view.frame.width - x
        currentVC.view.layer.shadowColor = UIColor.black.cgColor
        currentVC.view.layer.shadowOpacity = ShadowOpacity
        currentVC.view.layer.shadowRadius = ShadowRadius

        self.percentageOffsetFromLeft = offset / self.viewBoundsWithOrientation(orientation: self.interfaceOrientation).width
        currentVC.view.frame = self.getSlidingRectWithPercentageOffset(percentage: self.percentageOffsetFromLeft, orientation: self.interfaceOrientation)
        self.transformAtPercentage(percentage: self.percentageOffsetFromLeft)

        if panGesture.state == UIGestureRecognizerState.cancelled || panGesture.state == UIGestureRecognizerState.ended {
            if fabs(vel.x) > 100 {
                self.completeSlidingAnimationWithDirection(direction: panDirection)
            } else {
                self.completeSlidingAnimationWithOffset(offset: offset)
            }
        }
    }

    func getSlidingRectWithPercentageOffset(percentage : CGFloat, orientation : UIInterfaceOrientation) -> CGRect {
        let viewRect = self.viewBoundsWithOrientation(orientation: orientation)
        var rectToReturn : CGRect = CGRect.init()
        rectToReturn.size = viewRect.size
        rectToReturn.origin = CGPoint.init(x: max(0, (1 - percentage) * viewRect.width), y: 0)

        return rectToReturn
    }

    func transformAtPercentage(percentage : CGFloat) -> Void {
        let transf : CGAffineTransform = CGAffineTransform.identity
        let newTransformValue = 1 - percentage * (1 - ZoomRatio)
        let newAlphaValue = percentage * MaxBlackMaskAlpha
        self.previousViewController.view.transform = transf.scaledBy(x: newTransformValue, y: newTransformValue)
        self.blackMask?.alpha = newAlphaValue
    }

    func completeSlidingAnimationWithDirection(direction : PanDirection) -> Void {
        if direction == PanDirection.Right {
            self.popViewController()
        } else {
            self.rollBackViewController()
        }
    }

    func completeSlidingAnimationWithOffset(offset : CGFloat) -> Void {
        if offset < self.viewBoundsWithOrientation(orientation: self.interfaceOrientation).width * 0.5 {
            self.popViewController()
        } else {
            self.rollBackViewController()
        }
    }

    func rollBackViewController() -> Void {
        if self.animationing {
            return
        }

        let currentVC = self.currentViewController
        let previousVC = self.previousViewController
        let rect = CGRect.init(x: 0, y: 0, width: currentVC.view.frame.width, height: currentVC.view.frame.height)

        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            let transf : CGAffineTransform = CGAffineTransform.identity
            previousVC.view.transform = transf.scaledBy(x: self.ZoomRatio, y: self.ZoomRatio)
            currentVC.view.frame = rect
            self.blackMask?.alpha = self.MaxBlackMaskAlpha
        }) { (finished) in
            if finished {
                self.animationing = false
            }
        }

    }

    public func pushViewController(viewController : UIViewController) -> Void {
        self.pushViewController(viewController: viewController, completion: nil)
    }

    public func pushViewController(viewController : UIViewController, completion : (() -> Swift.Void)?) -> Void {
        self.animationing = true

        viewController.view.layer.shadowColor = UIColor.black.cgColor
        viewController.view.layer.shadowOpacity = ShadowOpacity
        viewController.view.layer.shadowRadius = ShadowRadius

        viewController.view.frame = self.view.bounds.offsetBy(dx: self.view.bounds.width, dy: 0)
        viewController.view.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleHeight.rawValue) | UInt8(UIViewAutoresizing.flexibleWidth.rawValue)))
        self.blackMask?.alpha = 0
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)

        self.view.bringSubview(toFront: self.blackMask!)
        self.view.addSubview(viewController.view)

        UIView.animate(withDuration: AnimationDuration, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            let transf : CGAffineTransform = CGAffineTransform.identity
            self.currentViewController.view.transform = transf.scaledBy(x: self.ZoomRatio, y: self.ZoomRatio)
            viewController.view.frame = self.view.bounds
            self.blackMask?.alpha = self.MaxBlackMaskAlpha
        }) { (finished) in
            if finished {
                self.viewControllers.add(viewController)
                viewController.didMove(toParentViewController: self)

                self.animationing = false
                self.gestures = NSMutableArray.init()
                self.addPanGestureToView(view: self.currentViewController.view)

                if completion != nil {
                    completion!()
                }
            }
        }
    }

    public func popViewController() -> Void {
        self.popViewControllerCompletion(completion: nil)
    }

    public func popViewControllerCompletion(completion : (() -> Swift.Void)?) {
        if self.viewControllers.count < 2 {
            return
        }

        self.animationing = true

        let currentVC = self.currentViewController
        let previousVC = self.previousViewController
        previousVC.viewWillAppear(false)

        currentVC.view.layer.shadowColor = UIColor.black.cgColor
        currentVC.view.layer.shadowOpacity = ShadowOpacity
        currentVC.view.layer.shadowRadius = ShadowRadius

        UIView.animate(withDuration: AnimationDuration, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            currentVC.view.frame = self.view.bounds.offsetBy(dx: self.view.bounds.width, dy: 0)
            let transf : CGAffineTransform = CGAffineTransform.identity
            previousVC.view.transform = transf.scaledBy(x: 1.0, y: 1.0)
            previousVC.view.frame = self.view.bounds
            self.blackMask?.alpha = 0
        }) { (finished) in
            if finished {
                currentVC.view.removeFromSuperview()
                currentVC.willMove(toParentViewController: nil)

                self.view.bringSubview(toFront: self.previousViewController.view)
                currentVC.removeFromParentViewController()
                currentVC.didMove(toParentViewController: nil)

                self.viewControllers.remove(currentVC)
                self.animationing = false
                previousVC.viewDidAppear(false)

                if completion != nil {
                    completion!()
                }
            }
        }
    }

    public func popToViewController(toViewController : UIViewController) -> Void {
        let controllers : NSMutableArray = self.viewControllers.mutableCopy() as! NSMutableArray
        let index = controllers.index(of: toViewController)
        var needRemoveViewController : UIViewController? = nil

        for i in index + 1 ... controllers.count - 2 {
            needRemoveViewController = controllers.object(at: i) as? UIViewController
            needRemoveViewController?.view.alpha = 0
            needRemoveViewController?.removeFromParentViewController()
            controllers.remove(needRemoveViewController as Any)
        }

        self.popViewController()
    }

    public func popToRootViewController() -> Void {
        let rootViewController : UIViewController = self.viewControllers.object(at: 0) as! UIViewController
        self.popToViewController(toViewController: rootViewController)
    }
}

/// Helper UIViewController extension.
extension UIViewController {
    var jccNavigationController : JCCNavigationController {
        get {
            var result : JCCNavigationController? = nil
            var view : UIView = self.view

            var responder : UIResponder? = view.next

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
}
