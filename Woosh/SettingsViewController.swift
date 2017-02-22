//
//  SecondViewController.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/18/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//
//  WWDC 2017 bound -- hopefully
import UIKit
import MapKit
class SettingsViewController: UIViewController {
    

    override func viewDidLoad() {
        let dismissGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        self.view.addGestureRecognizer(dismissGesture)
        
        self.view.layer.shadowColor = UIColor.black.cgColor
        self.view.layer.shadowOpacity = 1
        self.view.layer.shadowOffset = CGSize.zero
        self.view.layer.shadowRadius = 60
        self.view.layer.shouldRasterize = true
        super.viewDidLoad()

    }

    @IBAction func dismissSelf(){
        self.dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("oh no")
    }


}

