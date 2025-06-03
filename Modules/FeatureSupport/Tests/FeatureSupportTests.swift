//
//  FeatureSupportTests.swift
//  Gainz – FeatureSupport
//
//  Unit tests for helper utilities that live in FeatureSupport.
//  Currently covers UnitConversion; extend as new helpers land.
//
//  Created on 27 May 2025.
//

import XCTest
@testable import FeatureSupport

final class FeatureSupportTests: XCTestCase {

    // 1e-6 tolerance so rounding to 2 dp never fails the assertion.
    private let tol = 1e-6

    // MARK: - Weight

    func testKgToLbAndBack_roundTrip() {
        let kg: Double = 100          // powerlifter day
        let lb = UnitConversion.kgToLb(kg, roundedTo: 5)
        let kg2 = UnitConversion.lbToKg(lb, roundedTo: 5)
        XCTAssertEqual(kg, kg2, accuracy: tol)
    }

    // MARK: - Length

    func testCmToInAndBack_roundTrip() {
        let cm: Double = 180
        let inches = UnitConversion.cmToIn(cm, roundedTo: 5)
        let cm2 = UnitConversion.inToCm(inches, roundedTo: 5)
        XCTAssertEqual(cm, cm2, accuracy: tol)
    }

    func testMToFtAndBack_roundTrip() {
        let meters: Double = 2.0
        let ft = UnitConversion.mToFt(meters, roundedTo: 5)
        let m2 = UnitConversion.ftToM(ft, roundedTo: 5)
        XCTAssertEqual(meters, m2, accuracy: tol)
    }

    // MARK: - Distance

    func testKmToMiAndBack_roundTrip() {
        let km: Double = 5.0          // common running distance
        let miles = UnitConversion.kmToMi(km, roundedTo: 5)
        let km2 = UnitConversion.miToKm(miles, roundedTo: 5)
        XCTAssertEqual(km, km2, accuracy: tol)
    }

    func testYdToMAndBack_roundTrip() {
        let yards: Double = 100
        let meters = UnitConversion.ydToM(yards, roundedTo: 5)
        let yards2 = UnitConversion.mToYd(meters, roundedTo: 5)
        XCTAssertEqual(yards, yards2, accuracy: tol)
    }
}
