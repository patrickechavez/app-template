//
//  CertificatePinner.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import CryptoKit
import Foundation
import Security
import os

// Validates that the server's certificate is trusted before allowing connections.
final class CertificatePinner: NSObject, URLSessionDelegate, @unchecked Sendable {

    private let pinnedHashes: Set<String>

    init(pinnedHashes: [String]) {
        self.pinnedHashes = Set(pinnedHashes.filter { !$0.isEmpty })
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            !pinnedHashes.isEmpty,
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if Self.validate(serverTrust: serverTrust, against: pinnedHashes) {
            completionHandler(.performDefaultHandling, nil)
        } else {
            AppLogger.network.error("Certificate pinning rejected the server's identity.")

            // Fails the task as cancelled, which the client tells apart from its
            // own cancellation. `.rejectProtectionSpace` gave no usable signal.
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// The base64 SHA-256 hash of the leaf certificate's SPKI, matching
    /// `openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`.
    static func spkiHash(for serverTrust: SecTrust) -> String? {
        guard
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
            let publicKey = SecCertificateCopyKey(certificate),
            let spki = spkiDER(for: publicKey)
        else {
            return nil
        }
        return Data(SHA256.hash(data: spki)).base64EncodedString()
    }

    private static func validate(serverTrust: SecTrust, against pinnedHashes: Set<String>) -> Bool {
        guard let hash = spkiHash(for: serverTrust) else { return false }
        return pinnedHashes.contains(hash)
    }

    /// Rebuilds the SubjectPublicKeyInfo DER for RSA and EC keys so the hash
    /// matches the SPKI produced by OpenSSL, rather than the raw key bytes.
    ///
    /// The key type is inferred from the bytes: an EC public key is an
    /// uncompressed point starting with `0x04`, while an RSA public key is a
    /// DER SEQUENCE starting with `0x30`.
    private static func spkiDER(for publicKey: SecKey) -> Data? {
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        let algorithmIdentifier: Data
        if keyData.first == 0x04 {
            // EC — ecPublicKey (1.2.840.10045.2.1) plus the curve OID.
            let ecOID: [UInt8] = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01]
            let curveOID: [UInt8]
            switch keyData.count {
            case 65:  // prime256v1 / P-256 (1.2.840.10045.3.1.7)
                curveOID = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07]
            case 97:  // secp384r1 / P-384 (1.3.132.0.34)
                curveOID = [0x2B, 0x81, 0x04, 0x00, 0x22]
            default:
                return nil
            }
            algorithmIdentifier = DER.sequence(DER.oid(ecOID) + DER.oid(curveOID))
        } else {
            // RSA — rsaEncryption (1.2.840.113549.1.1.1)
            let rsaOID: [UInt8] = [0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01]
            algorithmIdentifier = DER.sequence(DER.oid(rsaOID) + DER.null())
        }

        return DER.sequence(algorithmIdentifier + DER.bitString(keyData))
    }
}

// Encodes data in the format needed for certificate validation.
private enum DER {

    static func sequence(_ contents: Data) -> Data {
        Data([0x30]) + length(contents.count) + contents
    }

    static func oid(_ bytes: [UInt8]) -> Data {
        Data([0x06]) + length(bytes.count) + Data(bytes)
    }

    static func null() -> Data {
        Data([0x05, 0x00])
    }

    static func bitString(_ contents: Data) -> Data {
        Data([0x03]) + length(contents.count + 1) + Data([0x00]) + contents
    }

    private static func length(_ value: Int) -> Data {
        if value < 0x80 {
            return Data([UInt8(value)])
        }
        var bytes: [UInt8] = []
        var remaining = value
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0xFF), at: 0)
            remaining >>= 8
        }
        return Data([UInt8(0x80 | bytes.count)] + bytes)
    }
}
