//
//  OAuth2ClientConfig.swift
//  OAuth2
//
//  Created by Pascal Pfiffner on 16/11/15.
//  Copyright © 2015 Pascal Pfiffner. All rights reserved.
//

import Foundation

/// Client configuration object that holds on to client-server specific configurations such as client id, -secret and server URLs.
open class OAuth2ClientConfig {

	/// The client id.
	public final var clientId: String?

	/// The client secret, usually only needed for code grant.
	public final var clientSecret: String?

	/// The name of the client, e.g. for use during dynamic client registration.
	public final var clientName: String?

	/// The URL to authorize against.
	public final let authorizeURL: URL

	/// The URL where we can exchange a code for a token.
	public final var tokenURL: URL?

	/// The URL where we can refresh an access token using a refresh token.
	public final var refreshURL: URL?

	/// Where a logo/icon for the app can be found.
	public final var logoURL: URL?

	/// The scope currently in use.
	open var scope: String?

	/// The redirect URL string currently in use.
	open var redirect: String?

	/// All redirect URLs passed to the initializer.
	open var redirectURLs: [String]?

	/// The receiver's access token.
	open var accessToken: String?

	/// The receiver's id token.  Used by Google + and AWS Cognito
	open var idToken: String?

	/// The access token's expiry date.
	open var accessTokenExpiry: Date?

	/// If set to true (the default), uses a keychain-supplied access token even if no "expires\_in" parameter was supplied.
    open var accessTokenAssumeUnexpired: Bool = true

	/// The receiver's long-time refresh token.
	open var refreshToken: String?

	/// The `URL` to register a client against.
	public final var registrationURL: URL?

	/// Whether the receiver should use the request body instead of the Authorization header for the client secret.
    /// Defaults to `false`.
    public var secretInBody: Bool = false

	/// How the client communicates the client secret with the server. Defaults to ``OAuth2EndpointAuthMethod/none``
    /// if there is no secret, ``OAuth2EndpointAuthMethod/clientSecretPost`` if "secret\_in\_body" is `true` and
    /// ``OAuth2EndpointAuthMethod/clientSecretBasic`` otherwise. Interacts with the ``secretInBody`` setting.
	public final var endpointAuthMethod = OAuth2EndpointAuthMethod.none

	/// Contains special authorization request headers, can be used to override defaults.
	open var authHeaders: OAuth2Headers?

	/// Add custom parameters to the authorization request.
	public var customParameters: [String: String]?

    /// Encoding for auth string.
    ///
	/// - Note: Most servers use UTF-8 encoding for Authorization headers, but that's not 100% true,
    /// and we make it configurable (see https://github.com/p2/OAuth2/issues/165).
    open var authStringEncoding: String.Encoding = .utf8

	/// There's an issue with authenticating through 'system browser', where safari says:
	/// "Safari cannot open the page because the address is invalid."
    /// if you first selects 'Cancel' when asked to switch back to "your" app,
	/// and then you try authenticating again. To get rid of it you must restart Safari.
	///
	/// Read more about it here:
	/// http://stackoverflow.com/questions/27739442
	/// https://community.fitbit.com/t5/Web-API/oAuth2-authentication-page-gives-me-a-quot-Cannot-Open-Page-quot-error/td-p/1150391
	///
	/// Toggling the property to `true` will send an extra get-parameter to make the url unique,
    /// thus it will ask again for the new `URL`.
    open var safariCancelWorkaround: Bool = false

	/// Use Proof Key for Code Exchange (PKCE).
	///
	/// See: https://tools.ietf.org/html/rfc7636 .
    open var useProofKeyForCodeExchange: Bool = false

    /// Initializer to initialize properties from a settings dictionary.
    /// - Parameter settings: OAuth settings.
	public init(settings: OAuth2JSON) {
		clientId = settings["client_id"] as? String
		clientSecret = settings["client_secret"] as? String
		clientName = settings["client_name"] as? String

		// authorize URL
		var aURL: URL?
		if let auth = settings["authorize_uri"] as? String {
			aURL = URL(string: auth)
		}
		authorizeURL = aURL ?? URL(string: "https://localhost/p2.OAuth2.defaultAuthorizeURI")!

		// token, registration and logo URLs
		if let token = settings["token_uri"] as? String {
			tokenURL = URL(string: token)
		}
		if let refresh = settings["refresh_uri"] as? String {
			refreshURL = URL(string: refresh)
		}
		if let registration = settings["registration_uri"] as? String {
			registrationURL = URL(string: registration)
		}
		if let logo = settings["logo_uri"] as? String {
			logoURL = URL(string: logo)
		}

		// client authorization options
		scope = settings["scope"] as? String
		if let redirs = settings["redirect_uris"] as? [String] {
			redirectURLs = redirs
			redirect = redirs.first
		}
		if let inBody = settings["secret_in_body"] as? Bool {
			secretInBody = inBody
		}
		if secretInBody {
			endpointAuthMethod = .clientSecretPost
		} else if nil != clientSecret {
			endpointAuthMethod = .clientSecretBasic
		}
		if let headers = settings["headers"] as? OAuth2Headers {
			authHeaders = headers
		}
		if let params = settings["parameters"] as? OAuth2StringDict {
			customParameters = params
		}

		// access token options
		if let assume = settings["token_assume_unexpired"] as? Bool {
			accessTokenAssumeUnexpired = assume
		}

		if let usePKCE = settings["use_pkce"] as? Bool {
			useProofKeyForCodeExchange = usePKCE
		}
	}

    /// Update properties from response data.
    ///
    /// - Note: The method assumes values are present with the standard names, such as `access_token`,
    /// and assigns them to its properties.
    /// - Parameter json: `JSON` data returned from a request.
	func updateFromResponse(_ json: OAuth2JSON) {
		if let access = json["access_token"] as? String {
			accessToken = access
		}
		if let idtoken = json["id_token"] as? String {
			idToken = idtoken
		}
		accessTokenExpiry = nil
		if let expires = json["expires_in"] as? TimeInterval {
			accessTokenExpiry = Date(timeIntervalSinceNow: expires)
		} else if let expires = json["expires_in"] as? Int {
			accessTokenExpiry = Date(timeIntervalSinceNow: Double(expires))
		} else if let expires = json["expires_in"] as? String {			// when parsing implicit grant from URL fragment
			accessTokenExpiry = Date(timeIntervalSinceNow: Double(expires) ?? 0.0)
		}
		if let refresh = json["refresh_token"] as? String {
			refreshToken = refresh
		}
	}

	/**
	Creates a dictionary of credential items that can be stored to the keychain.
	
	- returns: A storable dictionary with credentials
	*/
	func storableCredentialItems() -> [String: String]? {
		guard let clientId = clientId, !clientId.isEmpty else { return nil }

		var items: [String: String] = ["id": clientId]
		if let secret = clientSecret {
			items["secret"] = secret
		}
		items["endpointAuthMethod"] = endpointAuthMethod.rawValue
		return items
	}

    /// Creates a dictionary of token items that can be stored to the keychain.
    /// - Returns: A storable dictionary with token data.
	func storableTokenItems() -> [String: String]? {
		guard let access = accessToken, !access.isEmpty else { return nil }

		var items: [String: String] = ["accessToken": access]
		if let date = accessTokenExpiry, date > Date() {
            items["accessTokenDate"] = ISO8601DateFormatter().string(from: date)
		}
		if let refresh = refreshToken, !refresh.isEmpty {
			items["refreshToken"] = refresh
		}
		if let idtoken = idToken, !idtoken.isEmpty {
			items["idToken"] = idtoken
		}
		return items
	}

    /// Updates receiver's instance variables with values found in the dictionary.
    /// Returns a list of messages that can be logged on debug.
    /// - Parameter items: The dictionary representation of the data to store to keychain.
    /// - Returns: A list of strings containing log messages.
	func updateFromStorableItems(_ items: [String: String]) -> [String] {
		var messages = [String]()
		if let id = items["id"] {
			clientId = id
			messages.append("Found client id")
		}
		if let secret = items["secret"] {
			clientSecret = secret
			messages.append("Found client secret")
		}
		if
            let methodName = items["endpointAuthMethod"],
            let method = OAuth2EndpointAuthMethod(rawValue: methodName)
        {
			endpointAuthMethod = method
		}
		if let token = items["accessToken"], !token.isEmpty {
            if let date = items["accessTokenDate"].flatMap(ISO8601DateFormatter().date(from: )) {
				if date > Date() {
					messages.append("Found access token, valid until \(date)")
					accessTokenExpiry = date
					accessToken = token
				} else {
					messages.append("Found access token but it seems to have expired")
				}
			} else if accessTokenAssumeUnexpired {
				messages.append("Found access token but no expiration date, assuming unexpired (set `accessTokenAssumeUnexpired` to false to discard)")
				accessToken = token
			} else {
				messages.append("Found access token but no expiration date, discarding (set `accessTokenAssumeUnexpired` to true to still use it)")
			}
		}
		if let token = items["refreshToken"], !token.isEmpty {
			messages.append("Found refresh token")
			refreshToken = token
		}
		if let idtoken = items["idToken"], !idtoken.isEmpty {
			messages.append("Found id token")
			idToken = idtoken
		}
		return messages
	}

	/** Forgets the configuration's client id and secret. */
	open func forgetCredentials() {
		clientId = nil
		clientSecret = nil
	}

	/** Forgets the configuration's current tokens. */
	open func forgetTokens() {
		accessToken = nil
		accessTokenExpiry = nil
		refreshToken = nil
		idToken = nil
	}
}
