//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON
import CryptoSwift


class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"
    

    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()

    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //TODO:Set up the location manager here.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    func getWeatherData(url: String, parameters:[String: String]){
        Alamofire.request(url , method: .get, parameters: parameters).responseJSON{
            response in
            if response.result.isSuccess {
                print("Success!")
                let weatherJson : JSON = JSON(response.result.value!)
                //print(weatherJson)
                self.updateWeatherData(json : weatherJson)
            } else {
                print("Error \(response.result.error)")
                self.cityLabel.text = "Connection Issues"
            }
            
        }
    }

    //Write the getCryptoData method here: url: String, parameters:[String: String]
    func getCryptoData(url: String, parameters:[String: String]){
        //https://bittrex.com/api/v1.1/account/getbalances?apikey=c1e72e29f8d64ba0a61a383f3794b612
        //apikey=c1e72e29f8d64ba0a61a383f3794b612
        //apisecret=94b4e2e2eb7b41548e6003b0e6730e35
        
        let apisecret: String = "94b4e2e2eb7b41548e6003b0e6730e35"
        let salturl: String = "https://bittrex.com/api/v1.1/account/getbalances?apikey=\(parameters["apikey"] ?? "test")&nonce=\(parameters["nonce"]  ?? "test")"
        print("url : \(salturl)")
        let password: Array<UInt8> = Array(apisecret.utf8)
        let salt: Array<UInt8> = Array(salturl.utf8)

        do  {
            let key = try HMAC(key: password, variant: .sha512).authenticate(salt)
            print("before hash : \(key)")
            let result  = NSData(bytes:key, length:key.count).description
            print("hash : \(result)")
            let newString = result.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
            let newString2 = newString.replacingOccurrences(of: "<", with: "", options: .literal, range: nil)
            let newString3 = newString2.replacingOccurrences(of: ">", with: "", options: .literal, range: nil)
            print("hash string : \(newString3)")
            print("para : \(parameters)")
            let header = ["apisign": newString3]
            Alamofire.request(url , method: .get, parameters: parameters, headers: header ).responseJSON{
                response in
                if response.result.isSuccess {
                    print("Crypto Success!")
                    let weatherJson : JSON = JSON(response.result.value!)
                    print(weatherJson)
                    //self.updateWeatherData(json : weatherJson)
                } else {
                    print("Error \(response.result.error)")
                    self.cityLabel.text = "Connection Issues"
                }
                
            }
        } catch {
            print(error)
        }

    }
    
    
    
    
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    func updateWeatherData(json : JSON) {
        if let temp = json["main"]["temp"].double {
            let city = json["name"].stringValue
            let condition = json["weather"][0]["id"].intValue
            weatherDataModel.temperature = Int(temp - 273.15)
            weatherDataModel.city = city
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition : condition)
            updateUIWithWeatherData()
        }
        else {
            cityLabel.text = "Weather Unavailable"
        }
        
    }

    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
    func updateUIWithWeatherData() {
        
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        
    }
    
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            print("Long = \(location.coordinate.longitude)  , lati = \(location.coordinate.latitude) ")
            let lat = String(location.coordinate.latitude)
            let lon = String(location.coordinate.longitude)
            let params : [String : String] = ["lat" : lat, "lon" : lon, "appid" : APP_ID]
            getWeatherData(url: WEATHER_URL, parameters: params)
            
            let url: String = "https://bittrex.com/api/v1.1/account/getbalances"
            let params1 : [String : String] = ["apikey" : "c1e72e29f8d64ba0a61a383f3794b612", "nonce" : String(NSDate().timeIntervalSince1970)]
            //let url: String = "https://bittrex.com/api/v1.1/account/getbalances?apikey=c1e72e29f8d64ba0a61a383f3794b612&nonce=\(String(NSDate().timeIntervalSince1970))"
            //let params1 : [String : String] = ["":""]
            getCryptoData(url: url, parameters: params1)
        }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/

    
    //Write the userEnteredANewCityName Delegate method here:
    func enteredCityName(city : String){
        print(city)
        let params : [String : String] = ["q" : city, "appid" : APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    
    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
    
    
    
    
}


