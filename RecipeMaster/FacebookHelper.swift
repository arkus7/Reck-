//
//  FacebookHelper.swift
//  RecipeMaster
//
//  Created by Arkadiusz Żmudzin on 21.10.2016.
//  Copyright © 2016 Arkadiusz Żmudzin. All rights reserved.
//

import FBSDKLoginKit
import ObjectMapper

class FacebookHelper {
    
    // MARK: Properties
    
    private static var instance: FacebookHelper?
    private static let profileDefaultsKey = "facebook_user_profile"
    
    private let facebookReadPermissions = ["public_profile", "email", "user_friends"]
    private let profileInfoRequestPath = "me?fields=first_name,last_name,picture"
    
    lazy var loginManager: FBSDKLoginManager = {
        return FBSDKLoginManager()
    }()
    
    var currentProfile : FacebookUserProfile?
    
    // MARK: Initializers
    
    static func sharedInstance() -> FacebookHelper! {
        if instance == nil {
            instance = FacebookHelper()
        }
        return instance
    }
    
    // MARK: Public Facebook Methods
    
    func logIn(from: UIViewController, successBlock: @escaping (_ profile: FacebookUserProfile) -> (), andFailure failureBlock: @escaping (Error?) -> ()) {
        if isLoggedIn() {
            loadProfileInfo(callback: { (profile) in
                successBlock(profile)
            })
            return
        }
        
        loginManager.logIn(withReadPermissions: facebookReadPermissions, from: from) { (result, error) in
            if error != nil {
                failureBlock(error)
            } else if result!.isCancelled {
                self.logOut()
                failureBlock(nil)
            } else {
                if self.hasGrantedAllPermissions(result: result!) {
                    self.loadProfileInfo( callback: { (profile) in
                        successBlock(profile)
                    })
                }
            }
        }
    }
    
    func getAccessToken() -> String? {
        if(FBSDKAccessToken.current() == nil) {
            return nil
        }
        return FBSDKAccessToken.current().tokenString
    }
    
    func logOut() {
        loginManager.logOut()
        saveProfileToDefaults(profile: nil)
    }
    
    func isLoggedIn() -> Bool {
        getProfileFromDefaults()
        return FBSDKAccessToken.current() != nil && currentProfile != nil
    }
    
    func loadProfileInfo(callback: @escaping (FacebookUserProfile) -> ()) {
        FBSDKGraphRequest.init(graphPath: profileInfoRequestPath, parameters: nil).start { (conection, result, error) in
            if error != nil {
                // TODO: handle error
            } else {
                self.currentProfile = FacebookUserProfile(JSON: result as! [String:Any])!
                self.saveProfileToDefaults(profile: self.currentProfile!)
                callback(self.currentProfile!)
            }
        }
    }
    
    
    // MARK: Private methods
    
    private func hasGrantedAllPermissions(result: FBSDKLoginManagerLoginResult) -> Bool {
        let grantedPermissions = result.grantedPermissions.map({"\($0)"})
        for permission in self.facebookReadPermissions {
            if !grantedPermissions.contains(permission) {
                return false
            }
        }
        return true
    }
    
    private func getProfileFromDefaults() {
        let preferences = UserDefaults.standard
        if let profileString = preferences.string(forKey: FacebookHelper.profileDefaultsKey) {
            currentProfile = FacebookUserProfile(JSONString: profileString)
        }
    }
    
    private func saveProfileToDefaults(profile: FacebookUserProfile?) {
        let preferences = UserDefaults.standard
        preferences.set(profile != nil ? profile!.toJSONString() : nil, forKey: FacebookHelper.profileDefaultsKey)
        preferences.synchronize()
    }
    
    // MARK: Structures
    
    struct FacebookUserProfile: Mappable {
        var id: String?
        var profilePictureUrl: String?
        var firstName: String?
        var lastName: String?
        
        init?(map: Map) {
            
        }
        
        init() {
            
        }
        
        mutating func mapping(map: Map) {
            id <- map["id"]
            profilePictureUrl <- map["picture.data.url"]
            firstName <- map["first_name"]
            lastName <- map["last_name"]
        }
    }
    
}
