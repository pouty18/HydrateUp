//
//  ViewController.swift
//  HydrateUp
//
//  Created by Richard Poutier on 11/30/18.
//  Copyright © 2018 Richard Poutier. All rights reserved.
//

import UIKit
import HealthKit

let kTotalOuncesKey: String = "totalOunces"

class ViewController: UIViewController {

    var healthStore : HKHealthStore?
    
    var totalOunces : Int = 0 {
        didSet {
            ouncesLabel.text = "\(totalOunces) ounces Today"
        }
    }
    
    // the HKSampleType to send to health Store
    var typesToShare : Set<HKSampleType> {
        let waterType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!
        return [waterType]
    }
    
    @IBOutlet weak var ouncesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // view loads, update last access date to now
        UserDefaults.lastAccessDate = Date()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Request permission from user to write to health store
        if HKHealthStore.isHealthDataAvailable() {
            healthStore?.requestAuthorization(toShare: typesToShare, read: nil, completion: { (success, error) in
                if let error = error {
                    print(error.localizedDescription)
                    print("User elected to not allow access to write to the Health App. User will still be able to monitor user's daily intake on this app, however, nothing will be shared to the Health app.")
                }
            })
        }
        
        // load ounces for today
        if let totalOuncesToday = UserDefaults.standard.value(forKey: kTotalOuncesKey) as? Int {
            //  setting total ounces to previous amount
            totalOunces = totalOuncesToday
        } else {
            //  UserDefaults has not yet been set
            UserDefaults.standard.set(0, forKey: kTotalOuncesKey)
        }
    }
    
    @IBAction func incrementOunces(_ sender: Any) {
        totalOunces += 1
        
        //  set totalOunces value to UserDefaults only if (key,value) entry is found
        if (UserDefaults.standard.value(forKey: kTotalOuncesKey) as? Int) != nil {
            UserDefaults.standard.set(totalOunces, forKey: kTotalOuncesKey)
        } else {
            NSLog("ERROR: Unable to get user defaults: \"kTotalOuncesForKey")
        }
        
        //  only add health data to healthStore if user has granted app permission to write
        if HKHealthStore.isHealthDataAvailable() {
            addWaterAmountToHealthStore(ounces: 1)
        }
    }

    func addWaterAmountToHealthStore(ounces : Double) {
        
        let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        
        // string value represents US fluid ounces...available in HKUnit Documentation
        let quantityUnit = HKUnit(from: "fl_oz_us")
        
        let quantityAmount = HKQuantity(unit: quantityUnit, doubleValue: ounces)
        
        let now = Date()
        
        let sample = HKQuantitySample(type: quantityType, quantity: quantityAmount, start: now, end: now)
        
        let correlationType = HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        
        let waterCorrelationForWaterAmount = HKCorrelation(type: correlationType, start: now, end: now, objects: [sample])
        
        healthStore?.save(waterCorrelationForWaterAmount, withCompletion: { (success, error) in
            if error != nil {
                print("Error saving to health store: \(error!.localizedDescription)")
            } else {
                print("Saved \(ounces) ounces successfully.")
            }
        })
        
    }
}


extension UserDefaults {
    
    static let defaults = UserDefaults.standard
    
    static var delegate : ViewController? = nil
    
    static var lastAccessDate: Date? {
        get {
            return defaults.object(forKey: "lastAccessDate") as? Date
        }
        set {
            guard let newValue = newValue else { return }
            guard let lastAccessDate = lastAccessDate else {
                defaults.set(newValue, forKey: "lastAccessDate")
                return
            }
            if !Calendar.current.isDateInToday(lastAccessDate) {
                UserDefaults.reset()
            }
            defaults.set(newValue, forKey: "lastAccessDate")
        }
    }
    
    static func reset() {
        // resets user defaults
        NSLog("user Default reset")
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        delegate?.totalOunces = 0
    }
}
