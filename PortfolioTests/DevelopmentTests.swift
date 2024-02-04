//
//  DevelopmentTests.swift
//  PortfolioTests
//
//  Created by John Nelson on 2/4/24.
//

import CoreData
import XCTest
@testable import Portfolio

final class DevelopmentTests: BaseTestCase {

    func testSampleDataCreationWorks() {
        dataController.createSampleData()

        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 5, "There should be 5 sample tags.")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 50, "there should be 50 sample issues.")
    }

    func testDeleteAllWorks() {
        dataController.createSampleData()

        XCTAssertGreaterThan(dataController.count(for: Tag.fetchRequest()), 0, "There should be some tags.")
        XCTAssertGreaterThan(dataController.count(for: Issue.fetchRequest()), 0, "There should be some issues.")
        dataController.deleteAll()
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 0, "There should now be no tags.")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 0, "There should now be no issues.")
    }

    func testSampleTagHasNoIssues() {
        let tag = Tag.example

        XCTAssertEqual(tag.issues?.count, 0, "A sample tag should have no issues.")
    }

    func testSampleIssueHasHighPriority() {
        let issue = Issue.example

        XCTAssertTrue(issue.priority == Int16(2), "A sample issue should be high priority.")
    }

}
