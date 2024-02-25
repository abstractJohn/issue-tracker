//
//  ContentViewModel.swift
//  Portfolio
//
//  Created by John Nelson on 2/11/24.
//

import Foundation

enum SortType: String {
    case dateCreated = "createdDate"
    case dateModified = "modifiedDate"
}

extension ContentView {
    @dynamicMemberLookup
    class ViewModel: ObservableObject {
        var dataController: DataController

        /// A property to store whether the additional filters are enabled
        @Published var filterEnabled = false

        /// A property to store which (if any) priority should be displayed
        /// -1 indicates that all priorities should be visible and is the default value
        @Published var filterPriority = -1

        /// A property to store which status should be displayed
        @Published var filterStatus = Status.all

        /// A property to store which date should be used for sorting
        @Published var sortType = SortType.dateCreated

        /// A property to store which direction the sorting should use
        @Published var sortNewestFirst = true

        init(dataController: DataController) {
            self.dataController = dataController
        }

        func delete(_ offsets: IndexSet) {
            let issues = self.issuesForSelectedFilter()
            for offset in offsets {
                let item = issues[offset]
                dataController.delete(item)
            }
        }

        /// Runs a fetch request with various predicates which filter the user's issues based on
        /// tag, title, and content text as well as search tokens, priority, and completetion status
        /// - Returns: an array of all matching Issues
        func issuesForSelectedFilter() -> [Issue] {
            let filter = dataController.selectedFilter ?? .all
            var predicates = [NSPredicate]()

            if let tag = filter.tag {
                let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
                predicates.append(tagPredicate)
            } else {
                let datePredicate = NSPredicate(format: "modifiedDate > %@", filter.minModificationDate as NSDate)
                predicates.append(datePredicate)
            }

            let trimmedFilterText = dataController.filterText.trimmingCharacters(in: .whitespaces)
            if trimmedFilterText.isEmpty == false {
                let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
                let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
                let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
                                                                [titlePredicate, contentPredicate])
                predicates.append(combinedPredicate)
            }

            if dataController.filterTokens.isEmpty == false {
                let tokenPredicate = NSPredicate(format: "ANY tags in %@", dataController.filterTokens)
                predicates.append(tokenPredicate)
            }

            if filterEnabled {
                if filterPriority >= 0 {
                    let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
                    predicates.append(priorityFilter)
                }

                if filterStatus != .all {
                    let lookForClosed = filterStatus == .closed
                    let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
                    predicates.append(statusFilter)
                }
            }

            let request = Issue.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue,
                                                        ascending: !sortNewestFirst)]
            let allIssues = (try? dataController.container.viewContext.fetch(request)) ?? []

            return allIssues
        }

        subscript<Value>(dynamicMember keyPath: KeyPath<DataController, Value>) -> Value {
            dataController[keyPath: keyPath]
        }

        subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<DataController, Value>) -> Value {
            get { dataController[keyPath: keyPath] }
            set { dataController[keyPath: keyPath] = newValue }
        }
    }
}
