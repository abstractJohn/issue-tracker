//
//  ExtensionTests.swift
//  PortfolioTests
//
//  Created by John Nelson on 2/4/24.
//
import CoreData
import XCTest
@testable import Portfolio

final class ExtensionTests: BaseTestCase {

    func testIssueTitleUnwrap() {
        // Given
        let issue = Issue(context: managedObjectContext)
        // When
        issue.title = "Example issue"
        // Then
        XCTAssertEqual(issue.issueTitle, "Example issue", "Changing title should also change issueTitle.")

        // When
        issue.issueTitle = "Updated issue"
        // Then
        XCTAssertEqual(issue.title, "Updated issue", "Changing issueTitle should also change title.")
    }

    func testIssueContentUnwrap() {
        // Given
        let issue = Issue(context: managedObjectContext)

        // When
        issue.content = "Example issue"
        // Then
        XCTAssertEqual(issue.issueContent, "Example issue", "Changing content should also change issueContent.")

        // When
        issue.issueContent = "Updated issue"
        // Then
        XCTAssertEqual(issue.content, "Updated issue", "Changing issueContent should also change content.")
    }

    func testIssueCreationDateUnwrap() {
        // Given
        let issue = Issue(context: managedObjectContext)
        let testDate = Date.now

        // When
        issue.createdDate = testDate
        // Then
        XCTAssertEqual(issue.issueCreationDate, testDate, "Changing createdDate should also change issueCreationDate.")
    }

    func testIssueTagsUnwrap() {
        // Given
        let tag = Tag(context: managedObjectContext)
        let issue = Issue(context: managedObjectContext)
        // Then
        XCTAssertEqual(issue.issueTags.count, 0, "A new issue should have no tags")
        // When
        issue.addToTags(tag)
        // Then
        XCTAssertEqual(issue.issueTags.count, 1, "Adding 1 tag to an issue should result in issueTags count being 1.")
    }

    func testIssueTagsList() {
        // Given
        let tag = Tag(context: managedObjectContext)
        let issue = Issue(context: managedObjectContext)
        // When
        tag.name = "My Tag"
        issue.addToTags(tag)
        // Then
        XCTAssertEqual(issue.issueTagsList, "My Tag", "Adding 1 tag to an issue should make issueTagsList be My Tag.")
    }

    func testIssueSortingIsStable() {
        // Given
        let issue1 = Issue(context: managedObjectContext)
        let issue2 = Issue(context: managedObjectContext)
        let issue3 = Issue(context: managedObjectContext)
        // Two issues with the same title, but different created dates
        issue1.title = "B Issue"
        issue1.createdDate = .now
        issue2.title = "B Issue"
        issue2.createdDate = .now.addingTimeInterval(1)
        // And a third issue with a title coming earlier in the sort, but a created date much later
        issue3.title = "A Issue"
        issue3.createdDate = .now.addingTimeInterval(100)
        // When we put the issues in an array and sort it
        let allIssues = [issue1, issue2, issue3]
        let sorted = allIssues.sorted()
        // Then we get this order:
        XCTAssertEqual([issue3, issue1, issue2], sorted, "Sorting issues should use title then creation date.")

    }

    func testTagIdUnwrap() {
        // Given
        let tag = Tag(context: managedObjectContext)
        // When
        tag.id = UUID()
        // Then
        XCTAssertEqual(tag.tagID, tag.id, "Tag id and tagID should be the same.")
    }

    func testTagNameUnwrap() {
        // Given
        let tag = Tag(context: managedObjectContext)

        // When
        tag.name = "My Tag"

        // Then
        XCTAssertEqual(tag.tagName, "My Tag", "Changing name should also change tagName.")
    }

    func testTagActiveIssuesWrapper() {
        // Given
        let tag = Tag(context: managedObjectContext)
        let issue = Issue(context: managedObjectContext)
        // Then
        XCTAssertEqual(tag.tagActiveIssues.count, 0, "A new tag should have no active issues.")
        // When
        tag.addToIssues(issue)
        // Then
        XCTAssertEqual(tag.tagActiveIssues.count, 1, "A new tag with 1 new issue should have 1 active issue.")

        // And when
        issue.completed = true
        // Then
        XCTAssertEqual(tag.tagActiveIssues.count, 0, "A new tag with one completed issue should have no active issues.")
    }

    func testTagSortingIsStable() {
        // Given
        let tag1 = Tag(context: managedObjectContext)
        let tag2 = Tag(context: managedObjectContext)
        let tag3 = Tag(context: managedObjectContext)
        // Two tags with the same name, but one has an id which comes first in the sort
        tag1.name = "B tag"
        tag1.id = UUID(uuidString: "FFFFFFFF-06F7-4AC1-A1C2-BCE8274F0E9A")
        tag2.name = "B tag"
        tag2.id = UUID()
        tag3.name = "A tag"
        tag3.id = UUID()
        // when
        let allTags = [tag1, tag2, tag3]
        let sorted = allTags.sorted()
        // Then
        XCTAssertEqual([tag3, tag2, tag1], sorted, "Sorting Tags should use name then ID.")
    }

    func testBundleDecodingAwards() {
        // Given
        let awards = Bundle.main.decode("Awards.json", as: [Award].self)
        // Then
        XCTAssertFalse(awards.isEmpty, "Awards.json should decode to a non-empty array.")
    }

    func testDecodingString() {
        // Given
        let bundle = Bundle(for: ExtensionTests.self)
        // And
        let data = bundle.decode("DecodableString.json", as: String.self)
        // Then
        XCTAssertEqual(data, "Never ask a starfish for directions.", "The string must match DecodableString.json.")
    }

    func testDecodingDictionary() {
        // Given
        let bundle = Bundle(for: ExtensionTests.self)
        // And
        let data = bundle.decode("DecodableDictionary.json", as: [String: Int].self)
        // Then
        XCTAssertEqual(data.keys.count, 3, "DecodableDictionary.json has 3 keys.")
        // And
        XCTAssertEqual(data["Three"], 3, "item Three has a value of 3.")
    }

}
