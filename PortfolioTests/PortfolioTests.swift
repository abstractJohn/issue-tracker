//
//  PortfolioTests.swift
//  PortfolioTests
//
//  Created by John Nelson on 1/27/24.
//

import CoreData
import XCTest
@testable import Portfolio

class BaseTestCase: XCTestCase {
    var dataController: DataController!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        managedObjectContext = dataController.container.viewContext
    }
}
