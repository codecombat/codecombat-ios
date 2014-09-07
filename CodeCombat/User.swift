import UIKit

class User: NSObject {
  var name:String?
  var email:String?
  var password:String?
  var rawData:NSDictionary?
  
  class var sharedInstance:User {
    return sharedUserInstance
  }
  
}
let sharedUserInstance = User()
