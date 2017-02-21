//
//  FirstViewController.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/18/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import UIKit
import MapKit
import QuartzCore
import Firebase

class GlanceViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    public let locationManager = CLLocationManager()
    private let notificationName = Notification.Name("updateRegion")
    public var recentLocations: [CLLocation]?
    private let fauxRadius = 0.01449275362
    private let fauxRange: Double = 0.6
    private var selectedAirport: MKPlacemark? = nil
    private var loadingScreen: FullLoadingScreen? = FullLoadingScreen()

    var swipe: UISwipeGestureRecognizer? = nil
    var selectedAirportIdent: String? = nil

    var ref: FIRDatabaseReference!
    var airportTooClose: MKMapItem? = nil

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!


    // MARK: Superclass Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the default Firebase reference.
        FIRDatabase.database().persistenceEnabled = true
        ref = FIRDatabase.database().reference()
       
        self.mapView.userTrackingMode = .follow
        mapView.delegate = self
        loadingScreen?.addToView(view: self.view)
        self.setupOverlayView()

        self.initLocationManager()
        self.setNeedsStatusBarAppearanceUpdate()
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(GlanceViewController.toggleHelperView))
        swipe?.direction = .up
        overlayView.addGestureRecognizer(swipe!)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toInfo" {
            let dest = segue.destination.childViewControllers[0] as! AirInfoViewController
            dest.selectedAirportIdent = self.selectedAirportIdent
            self.selectedAirportIdent = nil
        }
    }

    // MARK: Helper Methods


    func toggleHelperView() {
        let collapsedFrame = CGRect(x: overlayView.frame.origin.x, y: overlayView.frame.origin.y, width: overlayView.bounds.width, height: overlayView.bounds.height - 45)
        let fullFrame = CGRect(x: overlayView.frame.origin.x, y: overlayView.frame.origin.y, width: overlayView.bounds.width, height: overlayView.bounds.height + 45)
        //good ol haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        if swipe?.direction == .up {
            swipe?.direction = .down
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.05)
            UIView.setAnimationCurve(.linear)
            overlayView.frame = collapsedFrame
            generator.prepare()
            UIView.commitAnimations()
            generator.impactOccurred()
        } else {
            swipe?.direction = .up
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.05)
            UIView.setAnimationCurve(.linear)
            overlayView.frame = fullFrame
            generator.prepare()
            UIView.commitAnimations()
            generator.impactOccurred()

        }
    }
    func airportQuery(coordinate: CLLocationCoordinate2D, callback: @escaping ((_ data: [MKMapItem]) -> Void)) {
        let query = self.ref.child("airports").queryOrdered(byChild: "latitude_deg").queryStarting(atValue: "\(coordinate.latitude - fauxRange)").queryEnding(atValue: "\(coordinate.latitude + fauxRange)")
        var testObjects: [MKMapItem] = []
        query.observe(.value, with: { (snapshot) in

            for airport in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (airport as AnyObject).key).value as! [String: AnyObject]
                let longitude = Double(childSnapshot["longitude_deg"] as! String)
                if (coordinate.longitude - self.fauxRange ... coordinate.longitude + self.fauxRange).contains(longitude!) {
                    let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(childSnapshot["latitude_deg"] as! String)!, longitude: Double(childSnapshot["longitude_deg"] as! String)!))

                    let mapObject = MKMapItem(placemark: placemark)
                    mapObject.name = childSnapshot["name"]! as? String

                    testObjects.append(mapObject)
                }
            }
            callback(testObjects)
        })
    }

    func setupOverlayView() {
        overlayView.backgroundColor = UIColor.white
        overlayView.layer.cornerRadius = 20
        overlayView.clipsToBounds = true
    }

    func processAirports(airports: [MKMapItem]) {
        if airports.count != 0 {
            for airport in airports {
                let locationOfAirport = CLLocation(latitude: (airport.placemark.coordinate.latitude), longitude: (airport.placemark.coordinate.longitude))
                self.addRadiusCircle(location: locationOfAirport)
                self.dropPinAt(placemark: (airport.placemark))
                let distance = (locationOfAirport.distance(from: (recentLocations?.last)!)) / 1609.344
                if distance <= 5.0 {
                    self.airportTooClose = airport
                    print((airport.name!) + " is too close!")
                }
            }
            //hide loading screen now
            if self.loadingScreen?.isVisible == true {
                loadingScreen?.removeFromView()
            }
        } else {
            print("No airports found")
        }
        let generator = UINotificationFeedbackGenerator()
        if self.airportTooClose != nil {
            self.detailLabel.text = (airportTooClose?.name!)! + " is too close!"
            self.statusLabel.text = "No"
            generator.notificationOccurred(.error)
        } else {
            self.statusLabel.text = "Yes"
            self.detailLabel.text = "You can fly"
            generator.notificationOccurred(.success)
        }
    }


    func addRadiusCircle(location: CLLocation) {
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 8046.72 as CLLocationDistance)
        self.mapView.add(circle)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAirportIdent = (view.annotation?.title)!
    }
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return UIStatusBarStyle.default
    }

    func callAirport(_ sender: UIButton) {
        //oh my god, kill me
        guard let pinView = sender.superview?.superview?.superview?.superview?.superview?.superview?.superview?.superview
            else {
            return
        }
        let actualAirPin = pinView as! MKPinAnnotationView
        let annotation = actualAirPin.annotation
        let request = MKLocalSearchRequest()


        request.naturalLanguageQuery = (annotation?.title)!
        request.region = MKCoordinateRegion(center: (annotation?.coordinate)!, span: MKCoordinateSpanMake(0.001, 0.001))
        let actualSearch = MKLocalSearch(request: request)

        actualSearch.start { response, _ in
            guard let response = response else {
                return
            }
            // find a phone number for the airport
            if response.mapItems.first!.phoneNumber != nil {
                let number = response.mapItems.first!.phoneNumber!.replacingOccurrences(of: "\\D", with: "", options: String.CompareOptions.regularExpression, range: response.mapItems.first!.phoneNumber!.startIndex..<response.mapItems.first!.phoneNumber!.endIndex)
                if let url = NSURL(string: "telprompt://\(number)") {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
            } else {
                print("No number *boop boop*")
            }

        }


    }

    // MARK: CLLocationManagerDelegate

    func initLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

    }
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: (error)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.global(qos: .background).async {
                self.recentLocations = locations
                let span = MKCoordinateSpanMake(0.05, 0.05)
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.notificationName, object: locations.last)
                    self.airportQuery(coordinate: locations.last!.coordinate, callback: { (data: [MKMapItem]) in
                        print(data.count)
                        self.processAirports(airports: data)

                    })

                }
            }

        }
    }

    func toInfo(_ sender: UIButton) {
        if self.selectedAirportIdent != nil {
            performSegue(withIdentifier: "toInfo", sender: sender)
        }

    }

    //MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.red
            circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
            circle.lineWidth = 1
            return circle
        } else {
            return MKOverlayRenderer.init()
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton.init(type: .infoDark)
        button.frame = CGRect(origin: CGPoint.zero, size: smallSquare)
        button.addTarget(self, action: #selector(GlanceViewController.toInfo(_:)), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }


    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // mapView.centerCoordinate = (userLocation.location?.coordinate)!
    }




}

extension GlanceViewController: HandleMapSearch {
    func dropPinAt(placemark: MKPlacemark) {
        let airpoint = MKPointAnnotation()
        airpoint.coordinate = placemark.coordinate
        airpoint.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
                airpoint.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(airpoint)
    }
}

protocol HandleMapSearch {
    func dropPinAt(placemark: MKPlacemark)
}


extension UIView {
    func roundCornersWithLayerMask(cornerRadii: CGFloat, corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: cornerRadii, height: cornerRadii))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath

        layer.mask = maskLayer
    } }
