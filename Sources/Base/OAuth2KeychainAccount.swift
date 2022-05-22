//
//  OAuth2KeychainAccount.swift
//  OAuth2
//
//  Created by David Kraus on 09/03/16.
//  Copyright © 2016 Pascal Pfiffner. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import KeychainAccess

/**
Keychain integration handler for OAuth2.
*/
struct OAuth2KeychainAccount {

	/// The service name to use.
	let serviceName: String

	/// The account name to use.
	let accountName: String

	/// The keychain access group.
	var accessGroup: String?

	/// Keychain access mode.
	let accessMode: String

    private let keychain: Keychain

    /// Designated initializer.
    /// - Parameters:
    ///   - oauth2: The OAuth2 instance from which to retrieve settings.
    ///   - account: The account name to use.
    ///   - inData: Data that we want to store to the keychain.
	init(oauth2: OAuth2Securable, account: String) {
		serviceName = oauth2.keychainServiceName()
		accountName = account
		accessMode = String(oauth2.keychainAccessMode)
		accessGroup = oauth2.keychainAccessGroup
        keychain = Keychain(service: account)
	}
}

extension OAuth2KeychainAccount {

    func save(_ items: [String: String]) throws {
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            let archivedData = try NSKeyedArchiver.archivedData(
                withRootObject: items,
                requiringSecureCoding: false
            )
            try keychain.set(archivedData, key: accountName)
        } else {
            let archivedData = NSKeyedArchiver.archivedData(withRootObject: items)
            try keychain.set(archivedData, key: accountName)
        }
    }

    func delete() throws {
        try keychain.remove(accountName)
    }

    /// Attempts to read data from the keychain, will ignore `errSecItemNotFound` but throw others.
    /// - Returns: A `[String: String]` dictionary of data fetched from the keychain.
    func saved() throws -> [String: String]? {
        guard let data = try keychain.getData(accountName) else { return nil }

        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            let dictionary = try NSKeyedUnarchiver.unarchivedDictionary(
                ofKeyClass: NSString.self,
                objectClass: NSString.self,
                from: data
            )
            return dictionary as? [String: String]
        } else if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            let dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data)
            return dictionary as? [String: String]
        } else {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: String]
        }
	}
}
