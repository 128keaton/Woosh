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
class GlanceViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    public let locationManager = CLLocationManager()
    private let notificationName = Notification.Name("updateRegion")
    public var recentLocations: [CLLocation]?
    private let fauxRadius = 0.01449275362
    private var selectedAirport: MKPlacemark? = nil
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        self.setupOverlayView()
        self.initLocationManager()
    }

    func setupOverlayView() {



        overlayView.backgroundColor = UIColor.white
        overlayView.layer.cornerRadius = 20
        overlayView.clipsToBounds = true


    }


    // MARK: Airport location logic

    func searchForAirports(coordinate: CLLocationCoordinate2D) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = "Airport"
        request.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(fauxRadius, fauxRadius))
        let actualSearch = MKLocalSearch(request: request)

        actualSearch.start { response, _ in

            guard let response = response else {
                return
            }
            self.processAirports(airports: response.mapItems)

        }


    }
    func processAirports(airports: [MKMapItem]) {
        var airportTooClose: MKMapItem? = nil
        if airports.count != 0 {
            for airport in airports {
                let locationOfAirport = CLLocation(latitude: airport.placemark.coordinate.latitude, longitude: airport.placemark.coordinate.longitude)
                self.addRadiusCircle(location: locationOfAirport)
                self.dropPinAt(placemark: airport.placemark)
                let distance = (locationOfAirport.distance(from: (recentLocations?.last)!)) / 1609.344
                if distance <= 5.0 {
                    airportTooClose = airport
                    print(airport.name! + " is too close!")


                }
            }

        } else {
            print("No airports found")
        }
        if airportTooClose != nil {
            self.detailLabel.text = (airportTooClose?.name!)! + " is too close!"
            self.statusLabel.text = "No"
        } else {
            self.statusLabel.text = "Yes"
            self.detailLabel.text = "You can fly"
        }


    }

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
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "phone"), for: .normal)


        button.addTarget(self, action: #selector(callAirport(_:)), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }

    func addRadiusCircle(location: CLLocation) {
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 8046.72 as CLLocationDistance)
        self.mapView.add(circle)
    }
    func updateRegionFromLocation(location: CLLocation) {
        let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(fauxRadius, fauxRadius))
        mapView.setRegion(region, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        if self.recentLocations?.first != nil {
            print(self.searchForAirports(coordinate: (self.recentLocations?.first?.coordinate)!))
        }
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

            let callAlert = UIAlertController(title: "Do you want to call \(response.mapItems.first!.name!)?", message: "This will direct you to the Phone app.", preferredStyle: UIAlertControllerStyle.actionSheet)
            let callAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
                if let url = NSURL(string: "tel://\(response.mapItems.first?.phoneNumber)"), UIApplication.shared.canOpenURL(url as URL) {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
            })
            let dismissAction = UIAlertAction(title: "No", style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            })
            callAlert.addAction(callAction)
            callAlert.addAction(dismissAction)
            
            self.present(callAlert, animated: true, completion: nil)
            

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
        if locations.first != nil {
            DispatchQueue.global(qos: .background).async {
                self.recentLocations = locations
                print(self.recentLocations!)
                // print("location:: \(locations)")

                DispatchQueue.main.async {

                    NotificationCenter.default.post(name: self.notificationName, object: locations.last)
                    self.updateRegionFromLocation(location: locations.last!)
                    self.testForLocate()

                }
            }


        }
    }
    func testForLocate() {
        if self.recentLocations != nil {
            self.searchForAirports(coordinate: (self.recentLocations?.first?.coordinate)!)
        }
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
