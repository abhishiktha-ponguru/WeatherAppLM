//
//  ViewController.swift
//  WeatherApp
//
//  Created by Abhishiktha on 4/6/20.
//  Copyright © 2020 Abhishiktha. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var textFiled: UITextField?
    
    var weatherViewModel: WeatherDetailsViewModel?
    var forecastViewModel: WeatherForecastViewModel?
    
    let locationManager = CLLocationManager()
    
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            forecastViewModel?.lattitude = currentLocation?.latitude
            forecastViewModel?.longitude = currentLocation?.longitude
            if Reachability.isConnectedToNetwork {
                forecastViewModel?.getClimateDetails()
            } else {
                self.showAlert("Alert!", ErrorMessage.internetError)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ScreenName.weatherApp
        configureViewModel()
    }
    
    func configureViewModel() {
        weatherViewModel = WeatherDetailsViewModel()
        weatherViewModel?.viewModelDidload = {[weak self] (result, error) in
            guard error == nil else {
                self?.showAlert("Alert!", ErrorMessage.noDataError)
                return
            }
            self?.performSegue(withIdentifier: Segues.details, sender: WeatherType.weather)
        }
        
        forecastViewModel = WeatherForecastViewModel()
        forecastViewModel?.viewModelDidload = {[weak self] (result, error) in
            guard error == nil else {
                self?.showAlert("Alert!", ErrorMessage.noDataError)
                return
            }
            self?.performSegue(withIdentifier: Segues.details, sender: WeatherType.forecast)
        }
    }
    
    @IBAction func openCurrentDetails() {
        self.locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func openDetails() {
        if validateTextFiled() {
            weatherViewModel?.countries = textFiled?.text
            if Reachability.isConnectedToNetwork {
                weatherViewModel?.getClimateDetails()
            } else {
                self.showAlert("Alert!", ErrorMessage.internetError)
            }
        } else {
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.07
            animation.repeatCount = 3
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: (textFiled?.center.x ?? 0) - 10, y: textFiled?.center.y ?? 0))
            animation.toValue = NSValue(cgPoint: CGPoint(x: (textFiled?.center.x ?? 0) + 10, y: textFiled?.center.y ?? 0))
            
            textFiled?.layer.add(animation, forKey: "position")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? WeatherType {
            if segue.identifier == Segues.details {
                guard let detailsVC = segue.destination as? WeatherDetailsViewController else { return }
                if sender == .weather {
                    detailsVC.dataSource = weatherViewModel?.convertTextToDecodable()
                } else {
                    detailsVC.dataSource = forecastViewModel?.convertClimateToDecodable()
                }
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFiled?.resignFirstResponder()
        openDetails()
        return true
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        locationManager.stopUpdatingLocation()
    }
}

extension ViewController {
    func validateTextFiled() -> Bool {
        let countriesCount = textFiled?.text?.components(separatedBy: ",").count ?? 0
        if countriesCount > 2 && countriesCount < 8 {
            return true
        }
        return false
    }
}
