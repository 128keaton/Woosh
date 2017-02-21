//
//  AirInfoViewController.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/21/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class AirInfoViewController: UIViewController {
    var selectedAirportIdent: String? = nil {
        didSet {
            print(selectedAirportIdent ?? "oops")
            self.setupView()
        }
    }

    var ref: FIRDatabaseReference!

    func setupView() {
        let query = self.ref.child("airports").queryOrdered(byChild: "name").queryEqual(toValue: self.selectedAirportIdent)

        query.observe(.value, with: { (snapshot) in
            print(snapshot)

        })


    }
    override func viewDidLoad() {
        // Setup the default Firebase reference.
        ref = FIRDatabase.database().reference()
    }

}
