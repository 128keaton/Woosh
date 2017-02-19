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
class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    private var glanceViewController: GlanceViewController!

    private let fauxRadius = 0.01449275362
    
    override func viewDidLoad() {
        glanceViewController = self.parent?.childViewControllers[0] as! GlanceViewController
        if glanceViewController.recentLocations != nil && glanceViewController.recentLocations?.first != nil {
            self.updateRegionFromLocation(location: (glanceViewController.recentLocations?.last)!)
        }
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: Selector(("updateRegionFromLocation")), name: NSNotification.Name(rawValue: "updateRegion"), object: CLLocation())
      
    }
    func configureMapView() {
        mapView.showsUserLocation = true
    }
    func updateRegionFromLocation(location: CLLocation) {
        let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(fauxRadius, fauxRadius))
        mapView.setRegion(region, animated: true)
        print("recieved notification, with location: \(location)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("oh no")
    }


}

