//
//  StrengthCalculationTests.swift
//  Gainz – AnalyticsDashboard Tests
//
//  Validates one-rep-max estimators and strength–normalisation scores
//  used throughout the Analytics module.  Formula references:
//
//  • Epley  (1985):  1RM = W × (1 + 0.033 × r)                 [oai_citation:0‡vcalc.com](https://www.vcalc.com/wiki/epley-formula-1-rep-max?utm_source=chatgpt.com) [oai_citation:1‡calculator.academy](https://calculator.academy/epley-formula-calculator/?utm_source=chatgpt.com)
/* • Brzycki (1993): 1RM = W × 36 ÷ (37 − r)                   [oai_citation:2‡brianmac.co.uk](https://www.brianmac.co.uk/maxload.htm?utm_source=chatgpt.com) [oai_citation:3‡vcalc.com](https://www.vcalc.com/wiki/brzycki?utm_source=chatgpt.com)
   • Lombardi (1989):1RM = W × r^0.10                          [oai_citation:4‡vcalc.com](https://www.vcalc.com/wiki/lombardi-one-1-rep-maximum?utm_source=chatgpt.com)
   • Wilks  (2017):  Score = coeff(bw) × total                 [oai_citation:5‡strengthlevel.com](https://strengthlevel.com/wilks-calculator?utm_source=chatgpt.com) [oai_citation:6‡omnicalculator.com](https://www.omnicalculator.com/sports/wilks?utm_source=chatgpt.com)
   • IPF-GL (2020):  Score per official IPF formula            [oai_citation:7‡ipfpointscalculator.com](https://www.ipfpointscalculator.com/?utm_source=chatgpt.com) [oai_citation:8‡powerlifting.sport](https://www.powerlifting.sport/rules/codes/info/ipf-formula?utm_source=chatgpt.com)
*/
//
//  Created: 2025-06-03
//

import XCTest
@testable import AnalyticsDashboard        // Production calculators
@testable import Domain                    // StrengthMetric, StrengthCalculator

final class StrengthCalculationTests: XCTestCase {
    
    // MARK: – 1 RM Estimator Accuracy
    
    func testEpleyEstimatorExactMatch() {
        // GIVEN 100 kg × 5 reps
        let expected = 100 * (1 + 0.033 * 5)  // 116.5 kg ground-truth
        let calc     = StrengthCalculator.estimate1RM(weight: 100,
                                                      reps: 5,
                                                      formula: .epley)
        XCTAssertEqual(calc, expected, accuracy: 0.001,
                       "Epley formula should return 116.5 kg for 100 kg×5")
    }
    
    func testBrzyckiEstimatorWithinTolerance() {
        // GIVEN 100 kg × 5 reps → 112.5 kg theoretical
        let expected = 100 * 36.0 / 32.0
        let calc     = StrengthCalculator.estimate1RM(weight: 100,
                                                      reps: 5,
                                                      formula: .brzycki)
        XCTAssertEqual(calc, expected, accuracy: 0.001)
    }
    
    func testLombardiEstimatorWithinTolerance() {
        // GIVEN 120 kg × 8 reps
        let expected = 120 * pow(8, 0.10)
        let calc     = StrengthCalculator.estimate1RM(weight: 120,
                                                      reps: 8,
                                                      formula: .lombardi)
        XCTAssertEqual(calc, expected, accuracy: 0.001)
    }
    
    // MARK: – Strength-Normalization Scores
    
    func testWilksScoreMatchesReference() {
        // GIVEN total 700 kg, body-weight 90 kg, male
        // Reference score ≈ 447.45 (old coeffs)   [oai_citation:9‡strengthlevel.com](https://strengthlevel.com/wilks-calculator?utm_source=chatgpt.com)
        let score = StrengthCalculator.wilks(total: 700, bodyWeight: 90, sex: .male)
        XCTAssertEqual(score, 447.45, accuracy: 0.1)
    }
    
    func testIPFGLPointsMatchesCalculator() {
        // GIVEN total 800 kg, body-weight 80 kg, raw male
        // Online calc returns ≈ 113.47 pts               [oai_citation:10‡ipfpointscalculator.com](https://www.ipfpointscalculator.com/?utm_source=chatgpt.com)
        let score = StrengthCalculator.ipfGL(total: 800, bodyWeight: 80, sex: .male, equipment: .raw)
        XCTAssertEqual(score, 113.47, accuracy: 0.1)
    }
}
