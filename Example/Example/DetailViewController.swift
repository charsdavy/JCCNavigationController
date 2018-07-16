//
//  DetailViewController.swift
//  Example
//
//  Created by chars on 2018/7/16.
//  Copyright © 2018年 chars. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    public var navigationBar : UINavigationBar? = nil
    public var navigationBarItem : UINavigationItem? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.initSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func initNavigationBar() -> Void {
        if self.navigationBar == nil {
            self.navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 20, width: self.view.bounds.width, height: 64))
            self.navigationBar?.barTintColor = UIColor.white
            self.navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.black, NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17)]
            self.navigationBar?.tintColor = UIColor.white
            self.navigationBar?.barStyle = UIBarStyle.blackTranslucent
        }

        if self.navigationBarItem == nil {
            if self.title != nil {
                self.navigationBarItem = UINavigationItem.init(title: self.title!)
            } else {
                self.navigationBarItem = UINavigationItem.init()
            }
        }
    }

    func initSubviews() -> Void {
        self.view.backgroundColor = UIColor.white

        self.initNavigationBar()

        if self.navigationBar?.superview == nil {
            self.view.addSubview(self.navigationBar!)
            self.navigationBar?.items = [self.navigationBarItem] as? [UINavigationItem]
        }

        self.navigationBarItem?.leftBarButtonItem = self.backBarButtonItem()
    }

    public func back() -> Void {
        self.jccNavigationController.popViewController()
    }

    @objc func backNavigationAction(sender : UIButton) -> Void {
        self.back()
    }

    func backBarButtonItem() -> UIBarButtonItem {
        let back = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 24, height: 24))
        back.setImage(UIImage.init(named: "back_22x22"), for: UIControlState.normal)
        back.addTarget(self, action: #selector(self.backNavigationAction(sender:)), for: UIControlEvents.touchUpInside)
        return UIBarButtonItem.init(customView: back)
    }
}
