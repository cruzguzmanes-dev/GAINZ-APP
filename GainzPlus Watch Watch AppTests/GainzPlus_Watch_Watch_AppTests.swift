//
//  GainzPlus_Watch_Watch_AppTests.swift
//  GainzPlus Watch Watch AppTests
//
//  Created by Eric Sebastián on 16/03/26.
//

import XCTest
@testable import GainzPlus

@MainActor
final class SessionStoreTests: XCTestCase {

    private var store: SessionStore!
    private let udKey = "gainzplus.sessions"

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: udKey)
        store = SessionStore()
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: udKey)
    }

    // MARK: - Helpers

    private func makeSession(daysAgo: Int = 0, results: [CardResult] = []) -> RestSession {
        let base = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: base)!
        return RestSession(date: date, restDuration: 60, packID: nil, cardResults: results)
    }

    private func makeResult(cardID: UUID = UUID(), phrase: String = "test", knew: Bool) -> CardResult {
        CardResult(cardID: cardID, phrase: phrase, knew: knew)
    }

    // MARK: - streakDays

    func testStreakDays_emptyStore_returnsZero() {
        XCTAssertEqual(store.streakDays, 0)
    }

    func testStreakDays_onlyToday_returnsOne() {
        store.sessions = [makeSession(daysAgo: 0)]
        XCTAssertEqual(store.streakDays, 1)
    }

    func testStreakDays_todayAndYesterday_returnsTwo() {
        store.sessions = [makeSession(daysAgo: 0), makeSession(daysAgo: 1)]
        XCTAssertEqual(store.streakDays, 2)
    }

    func testStreakDays_gapBreaksStreak_returnsOne() {
        // hoy + hace 2 días (sin ayer) → solo cuenta hoy
        store.sessions = [makeSession(daysAgo: 0), makeSession(daysAgo: 2)]
        XCTAssertEqual(store.streakDays, 1)
    }

    func testStreakDays_onlyYesterday_returnsZero() {
        // la racha parte desde HOY hacia atrás — si hoy no hay sesión, es 0
        store.sessions = [makeSession(daysAgo: 1)]
        XCTAssertEqual(store.streakDays, 0)
    }

    func testStreakDays_multipleSessionsSameDay_countAsOne() {
        store.sessions = [makeSession(daysAgo: 0), makeSession(daysAgo: 0), makeSession(daysAgo: 1)]
        XCTAssertEqual(store.streakDays, 2)
    }

    // MARK: - cardStatsToday

    func testCardStatsToday_emptyStore_returnsEmpty() {
        XCTAssertTrue(store.cardStatsToday.isEmpty)
    }

    func testCardStatsToday_sameCardInTwoSessions_mergesIntoOneStat() {
        let cardID = UUID()
        let s1 = makeSession(daysAgo: 0, results: [makeResult(cardID: cardID, phrase: "break up", knew: true)])
        let s2 = makeSession(daysAgo: 0, results: [makeResult(cardID: cardID, phrase: "break up", knew: false)])
        store.sessions = [s1, s2]

        XCTAssertEqual(store.cardStatsToday.count, 1)
        XCTAssertEqual(store.cardStatsToday[0].timesShown, 2)
    }

    func testCardStatsToday_preservesFirstAppearanceOrder() {
        let id1 = UUID()
        let id2 = UUID()
        let s = makeSession(daysAgo: 0, results: [
            makeResult(cardID: id1, phrase: "first", knew: true),
            makeResult(cardID: id2, phrase: "second", knew: true)
        ])
        store.sessions = [s]

        XCTAssertEqual(store.cardStatsToday[0].phrase, "first")
        XCTAssertEqual(store.cardStatsToday[1].phrase, "second")
    }

    func testCardStatsToday_excludesYesterdaySessions() {
        store.sessions = [makeSession(daysAgo: 1, results: [makeResult(knew: true)])]
        XCTAssertTrue(store.cardStatsToday.isEmpty)
    }

    func testCardStatsToday_lastKnew_reflectsLastResult() {
        let cardID = UUID()
        let s = makeSession(daysAgo: 0, results: [
            makeResult(cardID: cardID, phrase: "run out", knew: true),
            makeResult(cardID: cardID, phrase: "run out", knew: false)  // último: no supo
        ])
        store.sessions = [s]

        XCTAssertFalse(store.cardStatsToday[0].lastKnew)
    }

    // MARK: - accuracyToday

    func testAccuracyToday_noSessions_returnsZero() {
        XCTAssertEqual(store.accuracyToday, 0.0)
    }

    func testAccuracyToday_allKnown_returnsOne() {
        let s = makeSession(daysAgo: 0, results: [makeResult(knew: true), makeResult(knew: true)])
        store.sessions = [s]
        XCTAssertEqual(store.accuracyToday, 1.0)
    }

    func testAccuracyToday_mixedResults_returnsCorrectRatio() {
        let s = makeSession(daysAgo: 0, results: [
            makeResult(knew: true), makeResult(knew: true),
            makeResult(knew: true), makeResult(knew: false)
        ])
        store.sessions = [s]
        XCTAssertEqual(store.accuracyToday, 0.75, accuracy: 0.001)
    }

    func testAccuracyToday_excludesYesterdayResults() {
        let today     = makeSession(daysAgo: 0, results: [makeResult(knew: true), makeResult(knew: true)])
        let yesterday = makeSession(daysAgo: 1, results: [makeResult(knew: false), makeResult(knew: false)])
        store.sessions = [today, yesterday]
        XCTAssertEqual(store.accuracyToday, 1.0)
    }

    // MARK: - repeatedCardsToday

    func testRepeatedCardsToday_cardSeenOnce_notIncluded() {
        let s = makeSession(daysAgo: 0, results: [makeResult(knew: true)])
        store.sessions = [s]
        XCTAssertTrue(store.repeatedCardsToday.isEmpty)
    }

    func testRepeatedCardsToday_sameCardInTwoSessions_isRepeated() {
        let cardID = UUID()
        let s1 = makeSession(daysAgo: 0, results: [makeResult(cardID: cardID, knew: true)])
        let s2 = makeSession(daysAgo: 0, results: [makeResult(cardID: cardID, knew: false)])
        store.sessions = [s1, s2]
        XCTAssertEqual(store.repeatedCardsToday.count, 1)
    }

    // MARK: - Persistencia

    func testSave_insertsAtIndexZero() {
        let first  = makeSession(daysAgo: 1)
        let second = makeSession(daysAgo: 0)
        store.save(first)
        store.save(second)
        XCTAssertEqual(store.sessions[0].id, second.id)
    }

    func testSave_persistsAcrossInstances() {
        let s = makeSession(daysAgo: 0, results: [makeResult(knew: true)])
        store.save(s)

        let newStore = SessionStore()
        XCTAssertEqual(newStore.sessions.count, 1)
        XCTAssertEqual(newStore.sessions[0].id, s.id)
    }

    func testSave_duplicateID_appearstwice() {
        // Documenta comportamiento actual: save() no deduplica.
        // Si el Watch manda la misma sesión dos veces, se guarda duplicada.
        let s = makeSession(daysAgo: 0)
        store.save(s)
        store.save(s)
        XCTAssertEqual(store.sessions.count, 2)
    }
}
