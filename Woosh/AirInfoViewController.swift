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
import MapKit
class AirInfoViewController: UIViewController {
    var selectedAirportIdent: String? = nil {
        didSet {
            print(selectedAirportIdent ?? "oops")
            self.setupView(ident: selectedAirportIdent!)
        }
    }

    @IBOutlet var airportNameLabel: UILabel?
    @IBOutlet var airportMunicipalityLabel: UILabel?
    @IBOutlet var airportMapView: MKMapView?
    @IBOutlet var airportIdentLabel: UILabel?


    var query: FIRDatabaseQuery?
    var airportData: [String: AnyObject] = [:]
    var ref: FIRDatabaseReference!
    var airInfoTable: AirInfoTable!

    var phoneNumber: String? = nil
    func setupView(ident: String) {
        ref = FIRDatabase.database().reference()


        query = self.ref.child("airports").queryOrdered(byChild: "name").queryEqual(toValue: ident)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed" {
            let dest = segue.destination as! AirInfoTable
            airInfoTable = dest
        }
    }

    func locatePhoneNumber(locationName: String, coordinate: CLLocationCoordinate2D) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = (locationName)
        request.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpanMake(0.001, 0.001))
        let actualSearch = MKLocalSearch(request: request)

        actualSearch.start { response, _ in
            guard let response = response else {
                return
            }
            // find a phone number for the airport
            if response.mapItems.first!.phoneNumber != nil {
                let number = response.mapItems.first!.phoneNumber!.replacingOccurrences(of: "\\D", with: "", options: String.CompareOptions.regularExpression, range: response.mapItems.first!.phoneNumber!.startIndex..<response.mapItems.first!.phoneNumber!.endIndex)
                self.phoneNumber = number
                print("Phone number: \(number)")
            } else {
                print("No number *boop boop*")
            }

        }

    }
    @IBAction func callAirport() {
        if self.phoneNumber != nil {
            if let url = NSURL(string: "telprompt://\(self.phoneNumber)") {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "No phone number on file", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    func dropPinAt(placemark: MKPlacemark) {
        let airpoint = MKPointAnnotation()
        airpoint.coordinate = placemark.coordinate
        airpoint.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
                airpoint.subtitle = "\(city) \(state)"
        }
        airportMapView?.addAnnotation(airpoint)
    }
    @IBAction func goBack() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        ref = FIRDatabase.database().reference()
        airportMapView?.layer.cornerRadius = 20
        airportMapView?.clipsToBounds = true
        self.setNeedsStatusBarAppearanceUpdate()
        if UIDevice.current.userInterfaceIdiom != .phone {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        query?.observe(.value, with: { (snapshot) in
            for airport in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (airport as AnyObject).key).value as! [String: AnyObject]
                self.navigationController?.title = childSnapshot["ident"] as? String
                self.airportIdentLabel?.text = childSnapshot["ident"] as? String
                let type = "\(childSnapshot["type"]!)"
                self.navigationItem.title = type.titleized
                self.airportNameLabel?.text = "\(childSnapshot["name"]!)"
                let region = "\(childSnapshot["region"]!)".replacingOccurrences(of: "US-", with: "")
                self.airportMunicipalityLabel?.text = "\(childSnapshot["municipality"]!), \(region)"

                let coordinate = CLLocationCoordinate2D(latitude: Double(childSnapshot["latitude_deg"] as! String)!, longitude: Double(childSnapshot["longitude_deg"] as! String)!)
                self.locatePhoneNumber(locationName: "\(childSnapshot["name"]!)", coordinate: coordinate)
                self.setMapRegion(coordinate: coordinate)
                // remove stuff we don't need
                var trimmedSnapshot = childSnapshot
                trimmedSnapshot.removeValue(forKey: "name")
                trimmedSnapshot.removeValue(forKey: "iso_country")
                trimmedSnapshot.removeValue(forKey: "local_code")
                trimmedSnapshot.removeValue(forKey: "region")
                if self.airInfoTable != nil {
                    self.airInfoTable.airportData = trimmedSnapshot
                    self.airInfoTable.tableView.reloadData()
                }


                print(childSnapshot)
            }
        })
    }
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return UIStatusBarStyle.lightContent
    }
    func setMapRegion(coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        let placemark = MKPlacemark(coordinate: coordinate)
        self.dropPinAt(placemark: placemark)

        self.airportMapView?.showsPointsOfInterest = true
        self.airportMapView?.setRegion(region, animated: true)

    }

}
enum UIUserInterfaceIdiom: Int {
    case unspecified

    case phone // iPhone and iPod touch style UI
    case pad // iPad style UI
}
