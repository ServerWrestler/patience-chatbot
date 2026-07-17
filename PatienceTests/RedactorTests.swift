// RedactorTests.swift
// Verifies the default PII/secret redactor in Core/Forensics/ForensicsTriage.swift.
//
// The redactor is the gate that protects raw transcripts from ever reaching a
// frontier model or a fine-tune export. A regression here is a privacy bug, so
// tests cover both the positive (was the pattern caught?) and the negative
// (did we *not* mangle obviously safe text?) sides.

import XCTest
@testable import Patience

final class RedactorTests: XCTestCase {

    // MARK: - Positive cases (sensitive token must be removed and tagged)

    func testEmailIsRedacted() {
        let out = Redactor.redact("Reach me at user@example.com please")
        XCTAssertTrue(out.contains("<EMAIL>"))
        XCTAssertFalse(out.contains("user@example.com"))
    }

    func testSSNIsRedacted() {
        let out = Redactor.redact("His SSN is 123-45-6789.")
        XCTAssertTrue(out.contains("<SSN>"))
        XCTAssertFalse(out.contains("123-45-6789"))
    }

    func testPhoneIsRedacted() {
        let out = Redactor.redact("Call +1 (415) 555-1234 tomorrow")
        XCTAssertTrue(out.contains("<PHONE>"))
        XCTAssertFalse(out.contains("555-1234"))
    }

    func testIPIsRedacted() {
        let out = Redactor.redact("Server is at 192.168.1.42")
        XCTAssertTrue(out.contains("<IP>"))
        XCTAssertFalse(out.contains("192.168.1.42"))
    }

    func testOpenAIKeyIsRedacted() {
        let out = Redactor.redact("Token: sk-ABCDEFGHIJKLMNOPQRSTUV")
        XCTAssertTrue(out.contains("<API_KEY>"))
        XCTAssertFalse(out.contains("sk-ABCDEFGHIJ"))
    }

    func testAnthropicKeyIsRedacted() {
        let out = Redactor.redact("Token: sk-ant-ABCDEFGHIJKLMNOPQRSTUV")
        XCTAssertTrue(out.contains("<API_KEY>"))
        XCTAssertFalse(out.contains("sk-ant-"))
    }

    func testAWSKeyIsRedacted() {
        let out = Redactor.redact("key=AKIAIOSFODNN7EXAMPLE rest")
        XCTAssertTrue(out.contains("<AWS_KEY>"))
        XCTAssertFalse(out.contains("AKIAIOSFODNN7EXAMPLE"))
    }

    func testBearerTokenIsRedacted() {
        let out = Redactor.redact("Authorization: Bearer abcdef1234567890XYZ")
        XCTAssertTrue(out.contains("<TOKEN>"))
        XCTAssertFalse(out.contains("Bearer abcdef"))
    }

    func testJWTIsRedacted() {
        let out = Redactor.redact("Got eyJhbGciOi.eyJzdWIi.SflKxwRJSMeKKF0 back")
        XCTAssertTrue(out.contains("<JWT>"))
        XCTAssertFalse(out.contains("eyJhbGc"))
    }

    func testCreditCardIsRedacted() {
        let out = Redactor.redact("Card 4111 1111 1111 1111 charged")
        XCTAssertTrue(out.contains("<CC>"))
        XCTAssertFalse(out.contains("4111 1111"))
    }

    func testURLQueryStringIsRedacted() {
        let out = Redactor.redact("See https://api.example.com/v1?token=abc123")
        XCTAssertTrue(out.contains("<QUERY>"))
        XCTAssertFalse(out.contains("token=abc123"))
        // Host + path should survive — they're useful context for the judge.
        XCTAssertTrue(out.contains("api.example.com/v1"))
    }

    // MARK: - Negative cases (clean text must round-trip unchanged)

    func testCleanProseIsUnchanged() {
        let input = "The capital of France is Paris."
        XCTAssertEqual(Redactor.redact(input), input)
    }

    /// 2026-06-05-style dates must NOT match the phone or credit-card patterns.
    /// They were a common collision risk during pattern tuning, so we pin it.
    func testISODateIsNotRedacted() {
        let input = "Today is 2026-06-05."
        XCTAssertEqual(Redactor.redact(input), input)
    }

    // MARK: - Turn overload

    func testTurnOverloadPreservesRoleAndIndex() {
        let turn = Turn(role: "user", text: "email me at a@b.com", index: 7)
        let red = Redactor.redact(turn)
        XCTAssertEqual(red.role, "user")
        XCTAssertEqual(red.index, 7)
        XCTAssertTrue(red.text.contains("<EMAIL>"))
        XCTAssertFalse(red.text.contains("a@b.com"))
    }

    // MARK: - Determinism

    /// Calibration sampling relies on the redactor producing identical output for
    /// identical input — otherwise local/frontier verdicts compare different strings.
    func testRedactionIsDeterministic() {
        let input = "Ping me at user@example.com or 415-555-1234"
        let first = Redactor.redact(input)
        let second = Redactor.redact(input)
        XCTAssertEqual(first, second)
    }
}
