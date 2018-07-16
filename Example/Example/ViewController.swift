//
//  ViewController.swift
//  Example
//
//  Created by chars on 2018/7/16.
//  Copyright © 2018年 chars. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var navigationBar : UINavigationBar? = nil
    public var navigationBarItem : UINavigationItem? = nil

    var tableView : UITableView? = nil
    var dataArray : NSArray? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.initSubviews()
        self.loadDataArray()
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

    func initTableView() -> Void {
        if self.tableView == nil {
            self.tableView = UITableView.init(frame: CGRect.init(x: 0, y: 64, width: self.view.bounds.width, height: self.view.bounds.height - 64), style: UITableViewStyle.plain)
            self.tableView?.separatorColor = UIColor.init(red: 59.0 / 255.0, green: 59.0 / 255.0, blue: 59.0 / 255.0, alpha: 0.2)
            self.tableView?.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20) // 设置间距，这里表示separator离左边和右边均20像素
            self.tableView?.delegate = self
            self.tableView?.dataSource = self
        }
    }

    func initSubviews() -> Void {
        self.view.backgroundColor = UIColor.white
        self.title = "Example"

        self.initNavigationBar()
        self.initTableView()

        if self.navigationBar?.superview == nil {
            self.view.addSubview(self.navigationBar!)
            self.navigationBar?.items = [self.navigationBarItem] as? [UINavigationItem]
        }

        if self.tableView?.superview == nil {
            self.view.addSubview(self.tableView!)
        }
    }

    func loadDataArray() -> Void {
        dataArray = ["Example 1", "Example 2", "Example 3", "Example 4", "Example 5"]

        self.tableView?.reloadData()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.dataArray?.count)!
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "ExampleViewCellId")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "ExampleViewCellId")
            cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        }

        cell?.textLabel?.text = self.dataArray?.object(at: indexPath.row) as? String

        return cell!
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailViewController : DetailViewController = DetailViewController.init()
        detailViewController.title = self.dataArray?.object(at: indexPath.row) as? String
        self.jccNavigationController.pushViewController(viewController: detailViewController)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

