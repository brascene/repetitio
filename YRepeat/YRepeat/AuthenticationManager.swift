//
//  AuthenticationManager.swift
//  YRepeat
//
//  Created for Sign in with Apple and Cloud Sync
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import FirebaseAuth

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userId: String?
    @Published var userPhotoURL: URL?

    @AppStorage("appleUserIdentifier") private var appleUserIdentifier: String?
    @AppStorage("userEmail") private var storedEmail: String?
    @AppStorage("userName") private var storedName: String?

    private var currentNonce: String?

    override init() {
        super.init()
        checkAuthenticationState()

        // Listen to Firebase Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let firebaseUser = user {
                    self?.isSignedIn = true
                    self?.userId = firebaseUser.uid
                    self?.userEmail = firebaseUser.email ?? self?.storedEmail
                    self?.userName = firebaseUser.displayName ?? self?.storedName
                    self?.userPhotoURL = firebaseUser.photoURL
                } else if self?.appleUserIdentifier == nil {
                    // Only sign out if Apple ID is also not present
                    self?.isSignedIn = false
                    self?.userId = nil
                    self?.userPhotoURL = nil
                }
            }
        }
    }

    // MARK: - Check Authentication State

    private func checkAuthenticationState() {
        // First check if Firebase user exists
        if let firebaseUser = Auth.auth().currentUser {
            isSignedIn = true
            userId = firebaseUser.uid
            userEmail = firebaseUser.email ?? storedEmail
            userName = firebaseUser.displayName ?? storedName
            userPhotoURL = firebaseUser.photoURL
            return
        }

        // If no Firebase user, check Apple ID
        guard let userIdentifier = appleUserIdentifier else {
            isSignedIn = false
            return
        }

        // Check if the user is still authenticated with Apple
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userIdentifier) { [weak self] state, error in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    // User is still authorized with Apple but not Firebase
                    // This shouldn't happen normally, but handle gracefully
                    self?.isSignedIn = false
                case .revoked, .notFound:
                    // User has revoked authorization or not found
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign In

    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Sign Out

    func signOut() {
        // Sign out from Firebase
        try? Auth.auth().signOut()

        // Clear local data
        isSignedIn = false
        userId = nil
        userEmail = nil
        userName = nil
        userPhotoURL = nil
        appleUserIdentifier = nil
        storedEmail = nil
        storedName = nil
    }

    // MARK: - Helper Functions

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                print("Invalid state: A login callback was received, but no login request was sent.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            // Save user identifier
            let userIdentifier = appleIDCredential.user
            appleUserIdentifier = userIdentifier

            // Save email (only provided on first sign in)
            if let email = appleIDCredential.email {
                storedEmail = email
                userEmail = email
            } else {
                userEmail = storedEmail
            }

            // Save name (only provided on first sign in)
            if let fullName = appleIDCredential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    storedName = name
                    userName = name
                }
            } else {
                userName = storedName
            }

            // Initialize the Firebase credential using Apple ID token
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                          rawNonce: nonce,
                                                          fullName: appleIDCredential.fullName)

            // Sign in to Firebase
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Firebase sign in with Apple failed: \(error.localizedDescription)")
                        self?.isSignedIn = false
                        return
                    }

                    // Successfully signed in to Firebase
                    if let user = authResult?.user {
                        self?.isSignedIn = true
                        self?.userId = user.uid
                        print("Firebase sign in successful. User ID: \(user.uid)")
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error
        print("Sign in with Apple failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            fatalError("No key window found")
        }
        return window
    }
}
