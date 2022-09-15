/*
 Modified MIT License

 Copyright 2022 OneSignal

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 1. The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 2. All copies of substantial portions of the Software may only be used in connection
 with services provided by OneSignal.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation
import OneSignalCore
import OneSignalOSCore

/**
 Public-facing API to access the User Manager.
 */
@objc protocol OneSignalUserManager {
    static var User: OSUser.Type { get }
    static func login(_ externalId: String) -> OSUserInternalImpl
    static func login(externalId: String, withToken: String) -> OSUserInternalImpl
    static func loginGuest() -> OSUserInternalImpl
}

/**
 This is the user interface exposed to the public.
 */
@objc public protocol OSUser {
    static var pushSubscription: OSPushSubscriptionInterface { get }
    // Aliases
    static func addAlias(label: String, id: String)
    static func addAliases(_ aliases: [String: String])
    static func removeAlias(_ label: String)
    static func removeAliases(_ labels: [String])
    // Tags
    static func setTag(key: String, value: String)
    static func setTags(_ tags: [String: String])
    static func removeTag(_ tag: String)
    static func removeTags(_ tags: [String])
    static func getTag(_ tag: String)
    // Outcomes
    static func setOutcome(_ name: String)
    static func setUniqueOutcome(_ name: String)
    static func setOutcome(name: String, value: Float)
    // Email
    static func addEmail(_ email: String)
    static func removeEmail(_ email: String)
    // SMS
    static func addSmsNumber(_ number: String)
    static func removeSmsNumber(_ number: String)
    // Triggers
    static func setTrigger(key: String, value: String)
    static func setTriggers(_ triggers: [String: String])
    static func removeTrigger(_ trigger: String)
    static func removeTriggers(_ triggers: [String])

    // TODO: UM This is a temporary function to create a push subscription for testing
    static func testCreatePushSubscription(subscriptionId: UUID, token: UUID, enabled: Bool)
}

@objc
public class OneSignalUserManagerImpl: NSObject, OneSignalUserManager {
    static var user: OSUserInternal {
        if let user = _user {
            return user
        }
    
        let user = _login(externalId: nil, withToken: nil)
        _user = user
        return user
    }
    
    private static var _user: OSUserInternal?
    
    // has Identity and Properties Model Stores
    static let identityModelStore = OSModelStore<OSIdentityModel>(changeSubscription: OSEventProducer(), storeKey: "OS_IDENTITY_MODEL_STORE") // TODO: Don't hardcode
    static let propertiesModelStore = OSModelStore<OSPropertiesModel>(changeSubscription: OSEventProducer(), storeKey: "OS_PROPERTIES_MODEL_STORE") // TODO: Don't hardcode

    // TODO: UM, and Model Store Listeners: where do they live? Here for now.
    static let identityModelStoreListener = OSIdentityModelStoreListener(store: identityModelStore)
    static let propertiesModelStoreListener = OSPropertiesModelStoreListener(store: propertiesModelStore)

    // has Property and Identity operation executors
    static let propertyExecutor = OSPropertyOperationExecutor()
    static let identityExecutor = OSIdentityOperationExecutor()

    static func start() {
        // TODO: Finish implementation
        // Read from cache, set stuff up
        // Read the models from User Defaults

        // startModelStoreListenersAndExecutors() moves here after this start() method is hooked up.
        self.user = loadUserFromCache() // TODO: Revisit when to load user from the cache.
    }

    static func startModelStoreListenersAndExecutors() {
        // Model store listeners subscribe to their models. TODO: Where should these live?
        OneSignalUserManagerImpl.identityModelStoreListener.start()
        OneSignalUserManagerImpl.propertiesModelStoreListener.start()

        // Setup the executors
        OSOperationRepo.sharedInstance.addExecutor(identityExecutor)
        OSOperationRepo.sharedInstance.addExecutor(propertyExecutor)
    }

    @objc
    public static func login(_ externalId: String) -> OSUserInternalImpl {
        print("🔥 OneSignalUserManager login() called")
        startModelStoreListenersAndExecutors()

        // Check if the existing user is the same one being logged in. If so, return.
        if let user = self.user {
            guard user.identityModel.externalId != externalId else {
                return user
            }
        }

        // 1. Attempt to retrieve user from backend?
        // 2. Attempt to retrieve user from cache or stores? (No, done in start() method for now)

        // 3. Create new user
        // TODO: Remove/take care of the old user's information.

        let identityModel = OSIdentityModel(changeNotifier: OSEventProducer())
        self.identityModelStore.add(id: externalId, model: identityModel)
        identityModel.externalId = externalId // TODO: Don't fire this change.

        let propertiesModel = OSPropertiesModel(changeNotifier: OSEventProducer())
        self.propertiesModelStore.add(id: externalId, model: propertiesModel)

        let pushSubscription = OSPushSubscriptionModel(token: nil, enabled: false)

        let user = createUser(identityModel: identityModel, propertiesModel: propertiesModel, pushSubscription: pushSubscription)
        self.user = user
        return user
    }

    @objc
    public static func login(externalId: String, withToken: String) -> OSUserInternalImpl {
        print("🔥 OneSignalUser loginwithBearerToken() called")
        // validate the token
        return login(externalId)
    }

    @objc
    public static func loginGuest() -> OSUserInternalImpl {
        print("🔥 OneSignalUserManager loginGuest() called")
        startModelStoreListenersAndExecutors()

        // TODO: Another user in cache? Remove old user's info?

        // TODO: model logic for guest users
        let identityModel = OSIdentityModel(changeNotifier: OSEventProducer())
        let propertiesModel = OSPropertiesModel(changeNotifier: OSEventProducer())
        let pushSubscription = OSPushSubscriptionModel(token: nil, enabled: false)

        let user = createUser(identityModel: identityModel, propertiesModel: propertiesModel, pushSubscription: pushSubscription)
        self.user = user
        return user
    }

    static func loadUserFromCache() -> OSUserInternalImpl? {
        // Corrupted state if one exists without the other.
        guard !identityModelStore.getModels().isEmpty &&
                !propertiesModelStore.getModels().isEmpty // TODO: Check pushSubscriptionModel as well.
        else {
            return nil
        }

        // TODO: Need to load any SMS and emails subs too

        // There is a user in the cache
        let identityModel = identityModelStore.getModels().first!.value
        let propertiesModel = propertiesModelStore.getModels().first!.value
        let pushSubscription = OSPushSubscriptionModel(token: nil, enabled: false) // Modify to get from cache.

        let user = OSUserInternalImpl(
            pushSubscription: pushSubscription,
            identityModel: identityModel,
            propertiesModel: propertiesModel)

        return user
    }

    static func createUser(identityModel: OSIdentityModel, propertiesModel: OSPropertiesModel, pushSubscription: OSPushSubscriptionModel) -> OSUserInternalImpl {
        let user = OSUserInternalImpl(
            pushSubscription: pushSubscription,
            identityModel: identityModel,
            propertiesModel: propertiesModel)
        return user
    }
}

extension OneSignalUserManagerImpl: OSUser {
    public static var User: OSUser.Type {
        return self
    }

    public static var pushSubscription: OSPushSubscriptionInterface {
        return user.pushSubscription
    }
        
    public static func addAlias(label: String, id: String) {
        user.addAlias(label: label, id: id)
    }
    
    public static func addAliases(_ aliases: [String : String]) {
        user.addAliases(aliases)
    }
    
    public static func removeAlias(_ label: String) {
        user.removeAlias(label)
    }
    
    public static func removeAliases(_ labels: [String]) {
        user.removeAliases(labels)
    }
    
    public static func setTag(key: String, value: String) {
        user.setTag(key: key, value: value)
    }
    
    public static func setTags(_ tags: [String : String]) {
        user.setTags(tags)
    }
    
    public static func removeTag(_ tag: String) {
        user.removeTag(tag)
    }
    
    public static func removeTags(_ tags: [String]) {
        user.removeTags(tags)
    }
    
    // TODO: No tag getter?
    public static func getTag(_ tag: String) {
        user.getTag(tag)
    }
    
    public static func setOutcome(_ name: String) {
        user.setOutcome(name)
    }
    
    public static func setUniqueOutcome(_ name: String) {
        user.setUniqueOutcome(name)
    }
    
    public static func setOutcome(name: String, value: Float) {
        user.setOutcome(name: name, value: value)
    }
    
    public static func addEmail(_ email: String) {
        user.addEmail(email)
    }
    
    public static func removeEmail(_ email: String) {
        user.removeEmail(email)
    }
    
    public static func addSmsNumber(_ number: String) {
        user.addSmsNumber(number)
    }
    
    public static func removeSmsNumber(_ number: String) {
        user.removeSmsNumber(number)
    }
    
    public static func setTrigger(key: String, value: String) {
        user.setTrigger(key: key, value: value)
    }
    
    public static func setTriggers(_ triggers: [String : String]) {
        user.setTriggers(triggers)
    }
    
    public static func removeTrigger(_ trigger: String) {
        user.removeTrigger(trigger)
    }
    
    public static func removeTriggers(_ triggers: [String]) {
        user.removeTriggers(triggers)
    }
    
    public static func testCreatePushSubscription(subscriptionId: UUID, token: UUID, enabled: Bool) {
        user.testCreatePushSubscription(subscriptionId: subscriptionId, token: token, enabled: enabled)
    }
}
