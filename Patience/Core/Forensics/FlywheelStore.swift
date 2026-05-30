// FlywheelStore.swift
// Patience — forensics calibration & fine-tuning flywheel.
//
// Persists every verdict + every local-vs-authoritative pairing, then exports
// curated, redacted, deduped JSONL to fine-tune the LOCAL forensics judge so it
// agrees with the frontier judge over time (and needs fewer escalations).
// Reuses Verdict / EpisodeVerdict / Severity / Outcome / Source from prior files.
//
// Two guardrails on the loop (see docs/CONVERSATION_FORENSICS_TRIAGE_GUIDE.md):
//  - the calibration holdout must be partly human-labeled, or frontier bias gets
//    trained into the local judge AND hidden from the metric;
//  - redaction runs before export, always — no transcript PII ever reaches a training set.
//
// Sample exported row (one line of the JSONL):
//   {"messages":[
//     {"role":"system","content":"<rubric...>"},
//     {"role":"user","content":"<context>...</context><turn>...</turn>"},
//     {"role":"assistant","content":"{\"outcome\":\"partial\",\"severity\":3,...}"}]}

import Foundation
import CryptoKit

// MARK: - Provenance

/// Who to trust as ground truth, lowest to highest authority.
enum LabelAuthority: Int, Comparable, Codable {
    case localJudge = 0, frontier, human
    static func < (l: Self, r: Self) -> Bool { l.rawValue < r.rawValue }
}

/// One turn with every verdict that scored it, plus the redacted context/output stored for
/// training. `rubricVersion` is carried so incompatible labelings never mix into one fine-tune.
struct LabeledTurn: Codable {
    let episodeId: UUID
    let turnIndex: Int
    let promptContext: [String]        // prior turns the judge saw (stored already-redacted)
    let targetOutput: String           // the turn under analysis (stored already-redacted)
    var verdicts: [Verdict]            // every judge that scored this turn
    var rubricVersion: String          // never blend incompatible rubrics into one fine-tune

    private func authority(of v: Verdict) -> LabelAuthority {
        switch v.source {
        case .human:    return .human
        case .frontier: return .frontier
        default:        return .localJudge
        }
    }
    /// The verdict with the highest-authority source.
    var authoritative: Verdict? { verdicts.max { authority(of: $0) < authority(of: $1) } }
    var authorityLevel: LabelAuthority { authoritative.map { authority(of: $0) } ?? .localJudge }

    // The high-value signal: the local judge contradicted the authoritative label.
    var isDisagreement: Bool {
        guard let auth = authoritative, auth.source != .localJudge,
              let local = verdicts.first(where: { $0.source == .localJudge }) else { return false }
        return local.outcome != auth.outcome
            || abs(local.severity.rawValue - auth.severity.rawValue) >= 1
    }
}

// MARK: - Store

/// Persistence contract for verdicts and the frozen calibration holdout.
/// Concrete implementations live behind this protocol so storage can be swapped
/// (the trained judge and accumulated data are a private asset; see
/// docs/FORENSICS_CONTRIBUTION_BOUNDARY.md).
protocol FlywheelStore {
    func record(_ turn: LabeledTurn) throws
    func recordEpisode(id: UUID, verdict: EpisodeVerdict, rubricVersion: String) throws
    func all(rubricVersion: String) throws -> [LabeledTurn]
    func markHoldout(_ episodeId: UUID) throws         // frozen calibration set — never trained on
    func isHoldout(_ episodeId: UUID) -> Bool
}

// MARK: - Export

/// Knobs for emitting the fine-tune set.
struct ExportConfig {
    var rubricVersion: String
    var minAuthority: LabelAuthority = .frontier        // only frontier/human labels become targets
    var disagreementBoost = 3                           // oversample the cases local got wrong
    var systemPrompt: String                            // the judge's rubric / instruction text
}

/// One chat-SFT example, with a content hash for dedup.
struct TrainingRow {
    let system: String
    let context: [String]
    let output: String
    let label: Verdict
    let isDisagreement: Bool

    var contentHash: String {                           // dedup key — identical transcripts collapse
        let key = (context + [output]).joined(separator: "\u{1}")
        return SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func jsonl() -> String {                            // one chat-SFT example
        let user = "<context>\n\(context.joined(separator: "\n"))\n</context>\n<turn>\n\(output)\n</turn>"
        let labelJSON = (try? JSONEncoder().encode(label))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let obj: [String: Any] = ["messages": [
            ["role": "system",    "content": system],
            ["role": "user",      "content": user],
            ["role": "assistant", "content": labelJSON],
        ]]
        let data = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

/// Emits chat-format JSONL — system = the rubric, user = the transcript, assistant = the
/// authoritative verdict — oversampling disagreements (hard-example mining), deduping
/// identical transcripts, and excluding the frozen holdout.
struct FineTuneExporter {
    let store: FlywheelStore
    let config: ExportConfig

    func exportJSONL() throws -> String {
        let rows = try store.all(rubricVersion: config.rubricVersion)
            .filter { !store.isHoldout($0.episodeId) }              // never leak the eval set
            .filter { $0.authorityLevel >= config.minAuthority }    // trustworthy targets only
            .compactMap { t -> TrainingRow? in
                guard let label = t.authoritative else { return nil }
                return TrainingRow(system: config.systemPrompt,
                                   context: t.promptContext, output: t.targetOutput,
                                   label: label, isDisagreement: t.isDisagreement)
            }
            .reduce(into: [String: TrainingRow]()) { $0[$1.contentHash] = $1 }  // dedup
            .values
            .flatMap { row in                                       // hard-example mining
                row.isDisagreement ? Array(repeating: row, count: config.disagreementBoost) : [row]
            }
        return rows.map { $0.jsonl() }.joined(separator: "\n")
    }
}
