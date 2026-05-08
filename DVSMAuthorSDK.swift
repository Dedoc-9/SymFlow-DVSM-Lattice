//
//  DVSMSDK.swift
//  DVSM v∞ — CLIENT SDK & AUTHORING LAYER
//
//  Status: REFERENCE STANDARD [Identity-Enforced]
//  Copyright © 2026. All Rights Reserved.
//
//  =====================================================
//  ADDENDUM: THE AUTHORING SDK
//  =====================================================
//  This module serves as the entry point for all DVSM clients. 
//  It enforces "Identity-First" ingestion by requiring an 
//  Author Key for every emitted signal.
//

import Foundation
import CryptoKit

/// Contextual identity of the signal originator.
public struct AuthorContext: Sendable {
    public let authorID: String
    public let zone: DVSMTrustZone
    public let keyID: String
    
    public init(authorID: String, zone: DVSMTrustZone = .ingest, keyID: String) {
        self.authorID = authorID
        self.zone = zone
        self.keyID = keyID
    }
}

public final class DVSMSDK: Sendable {
    
    private let crypto: DVSMCryptoEngine
    private let authorKey: Curve25519.Signing.PrivateKey
    private let context: AuthorContext
    
    /// Initializes the SDK with a unique Author Key for identity provenance.
    public init(context: AuthorContext, privateKeyData: Data) throws {
        self.context = context
        self.authorKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        self.crypto = DVSMStandardCrypto(keyID: context.keyID)
    }

    // =====================================================
    // MARK: - SIGNAL PREPARATION
    // =====================================================

    /// Prepares a signal for ingestion by signing it with the Author Key.
    /// This establishes the "Author" stage of the DVSM pipeline.
    public func prepareSignal(payload: Data) throws -> Data {
        // 1. Generate Author Signature (Provenance)
        let signature = try authorKey.signature(for: payload)
        
        // 2. Package into a Transfer Envelope
        let envelope: [String: Any] = [
            "authorID": context.authorID,
            "keyID": context.keyID,
            "zone": context.zone.rawValue,
            "payload": payload.base64EncodedString(),
            "authorSignature": signature.base64EncodedString(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return try JSONSerialization.data(withJSONObject: envelope)
    }
}
