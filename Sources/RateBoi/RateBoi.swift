//
//  RateBoi is an open-source dependency for iOS & MacOS designed to make it easy to trigger reviews at the right time, built for BatteryBoi & SprintDock made by Joe Barbour
//  Please Credit this Library
//

import Foundation
import Combine
import StoreKit

#if os(macOS)
    import AppKit
#endif

extension Date {
    var minutes:Int? {
        let units = Calendar.current.dateComponents([.minute], from: Date(), to: self)
        return units.minute
        
    }
    
}

extension UserDefaults {
    static let updated = PassthroughSubject<RateDefaultsKeys, Never>()

    static var boi:UserDefaults {
        return UserDefaults()
        
    }

    static func rbstore(_ key:RateDefaultsKeys, value:Any?) {
        if let value = value {
            boi.set(value, forKey: key.rawValue)
            boi.set(Date(), forKey: "\(key.rawValue)_timestamp")
            boi.synchronize()
            
            updated.send(key)
                        
        }
        else {
            boi.removeObject(forKey: key.rawValue)
            boi.set(Date(), forKey: "\(key.rawValue)_timestamp")
            boi.synchronize()

            updated.send(key)

        }
        
    }
    
    static func rbvalue(_ key:RateDefaultsKeys) -> Any? {
        return boi.value(forKey: key.rawValue)
        
    }
    
    static func rbtimestamp(_ key:RateDefaultsKeys) -> Date? {
        return boi.value(forKey: "\(key.rawValue)_timestamp") as? Date
        
    }
    
}


enum RateDefaultsKeys:String {
    case installed = "ratetboi.installed.timestamp"
    case required = "ratetboi.points.required"
    case aquired = "ratetboi.points.aquired"
    case prompted = "ratetboi.prompted.timestamp"
    case error = "ratetboi.error.type"

}

enum RateErrorType:Int {
    case minor = 3
    case major = 5
    case fatal = 10
    
}

class RateBoi:ObservableObject {
    static var main = RateBoi()
        
    @Published var triggered:Bool = false
    @Published var score:Int = 0

    private var debug:Bool = false
    private var disabled:Bool = false
    private var cancellable = Set<AnyCancellable>()

    init() {
        UserDefaults.updated.receive(on: DispatchQueue.main).sink { key in
            let points:Int = UserDefaults.rbvalue(.aquired) as? Int ?? 0
            
            self.score = 0
            self.rateLog("Delight Score Updated - \(points)/", status: 200)

        }.store(in: &cancellable)
        
        UserDefaults.updated.delay(for: .seconds(20), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { key in
            let points:Int = UserDefaults.rbvalue(.aquired) as? Int ?? 0
            let required:Int = UserDefaults.rbvalue(.required) as? Int ?? 20

            if points > required {
                self.triggered = true
                
            }

        }.store(in: &cancellable)
                        
        self.reset(false)
        
    }
    
    public func setup(points:Int? = nil, debug:Bool = true) {
        if debug == true {
            self.debug = debug
            self.rateLog("Debugging Enabled", status: 200)

        }

        if let points = points {
            if points > 0 {
                UserDefaults.rbstore(.required, value: points)
                
            }
            else {
                UserDefaults.rbstore(.required, value: 20)

            }
            
        }
        
        if UserDefaults.rbvalue(.installed) as? Date == nil {
            UserDefaults.rbstore(.installed, value: Date())
            
        }
        
    }

    public func increment(_ points:Int? = nil) {
        if let existing = UserDefaults.rbvalue(.aquired) as? Int {
            if let points = points {
                UserDefaults.rbstore(.aquired, value: existing + points)

            }
            else {
                var score:Int = 1
                guard let positive = UserDefaults.rbtimestamp(.aquired)?.minutes else {
                    return
                    
                }
                
                switch positive {
                    case let x where x == 3 : score = 2
                    case let x where x == 2 : score = 4
                    case let x where x == 1 : score = 8
                    case let x where x == 0 : score = 10
                    default : score = 1
                    
                }
               
                if let negative = UserDefaults.rbtimestamp(.error)?.minutes {
                    if negative < 20 {
                        score = (score / 2)
                        return

                    }
                    
                }
                
                UserDefaults.rbstore(.aquired, value: existing + score)

            }

        }

    }
    
    public func reset(_ force:Bool = true) {
        if force == true {
            UserDefaults.rbstore(.aquired, value: nil)

        }
        else {
            if let since = UserDefaults.rbtimestamp(.aquired)?.minutes {
                var value:Int? = UserDefaults.rbvalue(.aquired) as? Int
                switch since {
                    case let x where x > 5760 : value = nil
                    case let x where x > 2880 : value = (value ?? 2) / 2
                    default : break
                    
                }
                
                UserDefaults.rbstore(.aquired, value: value)
                    
            }
            
        }
        
    }
    
    public func errorReport(_ error:RateErrorType = .minor) {
        if let existing = UserDefaults.rbvalue(.aquired) as? Int {
            UserDefaults.rbstore(.aquired, value: existing - error.rawValue)
            UserDefaults.rbstore(.error, value: error.rawValue)
            
        }
        
    }
    
    public func ratingPrompted(completion: (Int) -> Void) {
        UserDefaults.rbstore(.prompted, value: Date())
            
        completion(UserDefaults.rbvalue(.aquired) as? Int ?? 0)

    }
    
    private func rateLog(_ text:String, status:Int) {
        if self.debug == true {
            switch status {
                case 200 : print("\n\n✅ RateBoi Client - \(text)\n\n")
                case 201 : print("\n\n✅ RateBoi Client - \(text)\n\n")
                default : print("\n\n🚨 RateBoi Client - \(status) \(text)\n\n")
                
            }
            
        }
        
    }
        
}
