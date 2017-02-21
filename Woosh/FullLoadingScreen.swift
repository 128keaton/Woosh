//
//  FullLoadingScreen.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/19/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class FullLoadingScreen: UIViewController {
    fileprivate var spinner: UIActivityIndicatorView?
    fileprivate var label: UILabel?
    fileprivate var blurView: UIVisualEffectView?

    private(set) public var isVisible = false
    override func viewDidLoad() {
        self.setupSpinner()
        self.setupLabel()
        self.setupBlurView()
        self.view.backgroundColor = UIColor.clear
    }
    func setupLabel() {
        label = UILabel(frame: CGRect(x: 15, y: 55, width: self.view.frame.width - 15, height: 25))
        label?.textColor = .black
        label?.textAlignment = .center
        label?.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightSemibold)
        label?.text = "Locating airports"
    }
    func setupSpinner() {
        self.spinner = UIActivityIndicatorView(frame: self.view.frame)
        let transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        self.spinner?.transform = transform
        self.spinner?.color = UIColor.black
    }
    func setupBlurView() {
        let blurEffect = UIBlurEffect(style: .light)

        blurView = UIVisualEffectView(effect: blurEffect)
        blurView?.frame = self.view.bounds
        blurView?.addSubview(spinner!)
        blurView?.addSubview(label!)
        self.view.addSubview(blurView!)
    }
    override func viewWillAppear(_ animated: Bool) {
        self.isVisible = true
        spinner?.startAnimating()
    }
    override func viewWillDisappear(_ animated: Bool) {

        spinner?.stopAnimating()
    }
    func addToView(view: UIView) {
        view.addSubview(self.view)
    }
    func removeFromView() {
        UIView.animate(withDuration: 0.5, animations: { self.blurView?.alpha = 0.0 },
                       completion: { (value: Bool) in
            self.view.removeFromSuperview()
            self.isVisible = false
        })

    }
}
