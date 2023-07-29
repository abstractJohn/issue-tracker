//
//  DataController.swift
//  Portfolio
//
//  Created by John Nelson on 7/18/23.
//

import CoreData

enum SortType: String {
    case dateCreated = "createdDate"
    case dateModified = "modifiedDate"
}

enum Status {
    case all, open, closed
}

/// An environment singleton responsible for maintaining our CoreData stack
/// Includes saving, deleting, and even counting fetch requests
class DataController: ObservableObject {

    /// The CloudKit container to hold all the data in this app
    let container: NSPersistentCloudKitContainer

    /// A property to store the currently selecteded Filter
    /// (whether a user tag or smart filter) which defaults to the "All Issues" smart filter
    @Published var selectedFilter: Filter? = Filter.all

    /// A property to store which issue in the issues list is currently selected
    /// this issue is displayed in the detail view
    @Published var selectedIssue: Issue?

    @Published var filterText = ""

    @Published var filterTokens = [Tag]()

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

    // This Task is used to prevent spamming the CoreData context with save calls
    // a 3 second delay is used when queuing saves
    private var saveTask: Task<Void, Error>?

    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()

    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {
            return []
        }

        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()

        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }

        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }

    /// Initializes a Data Controller with an option to make temporary for use in previews and tests
    ///
    /// Defaults to permanent storage
    /// - Parameter inMemory: whether to store data temporarily or not
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Main")

        // For testing and previewing purposes, we create a
        // temporary, in-memory database by writing to /dev/null
        // so our data is destroyed after the app finishes running.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // Make sure that we watch iCloud for all changes to make
        // absolutely sure we keep our local UI in sync when a
        // remote change happens.
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                     forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
                                               object: container.persistentStoreCoordinator,
                                               queue: .main,
                                               using: remoteStoreChanged)

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }

    func remoteStoreChanged(_ notification: Notification) {
        objectWillChange.send()
    }

    func createSampleData() {
        let viewContext = container.viewContext

        for tagCounter in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(tagCounter)"

            for issueCounter in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(tagCounter)-\(issueCounter)"
                issue.content = "Description goes here"
                issue.createdDate = .now
                issue.completed = Bool.random()
                issue.priority = Int16.random(in: 0...2)
                tag.addToIssues(issue)
            }
        }

        try? viewContext.save()
    }

    /// Runs a fetch request with various predicates which filter the user's issues based on
    /// tag, title, and content text as well as search tokens, priority, and completetion status
    /// - Returns: an array of all matching Issues
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all
        var predicates = [NSPredicate]()

        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(format: "modifiedDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }

        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)
        if trimmedFilterText.isEmpty == false {
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
                                                            [titlePredicate, contentPredicate])
            predicates.append(combinedPredicate)
        }

        if filterTokens.isEmpty == false {
            let tokenPredicate = NSPredicate(format: "ANY tags in %@", filterTokens)
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
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: !sortNewestFirst)]
        let allIssues = (try? container.viewContext.fetch(request)) ?? []

        return allIssues
    }

    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = NSLocalizedString("New issue", comment: "create a new issue")
        issue.createdDate = .now
        issue.priority = 1

        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }

        save()

        selectedIssue = issue
    }

    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = NSLocalizedString("New tag", comment: "create a new tag")
        save()
    }

    /// Counts the records in the provided FetchRequest regardless of data type
    /// - Parameter fetchRequest: a FetchRequest to count
    /// - Returns: the number of records which would be returned by the FetchRequest
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
            let fetchRequest = Issue.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        case "closed":
            let fetchRequest = Issue.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        case "tags":
            let fetchRequest = Tag.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        default:
            // fatalError()
            return false
        }
    }

    /// Saves our CoreData context iff there are changes.
    /// This silently ignores any errors caused by saving which
    /// should be fine since all attributes are optional.
    func save() {
        saveTask?.cancel()

        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    /// queues a save to be performed by the MainActor in 3 seconds.
    /// Cancels any previously scheduled saves first.
    func queueSave() {
        saveTask?.cancel()

        saveTask = Task { @MainActor in
            try await Task.sleep(for: .seconds(3))
            save()
        }
    }

    /// A general function to delete any object managed in the current container
    /// - Parameter object: The managed object to delete
    func delete(_ object: NSManagedObject) {
        objectWillChange.send()
        container.viewContext.delete(object)
        save()
    }

    // A function created to allow for deleting whole batches of objects
    // such as all the stored data
    // Do not confuse this for the previous delete function
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        // ⚠️ When performing a batch delete we need to make sure we read the result back
        // then merge all the changes from that result back into our live view context
        // so that the two stay in sync.
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }

    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1)

        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2)

        save()
    }

    /// Finds the tags in the CoreData container which are not currently associated with the provided Issue
    /// These are used as a list of tags the user may choose to add to the issue
    /// - Parameter issue: an Issue whose tags to filter out
    /// - Returns: an array of unassociated Tags
    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []

        let allTagsSet = Set(allTags)
        let difference = allTagsSet.symmetricDifference(issue.issueTags)

        return difference.sorted()
    }

}
