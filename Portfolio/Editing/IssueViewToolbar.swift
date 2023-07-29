//
//  IssueViewToolbar.swift
//  Portfolio
//
//  Created by John Nelson on 7/26/23.
//

import SwiftUI

struct IssueViewToolbar: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    var body: some View {
        Menu {
            Button {
                UIPasteboard.general.string = issue.title
            } label: {
                Label("Copy Issue Title", systemImage: "doc.on.doc")
            }

            Button {
                issue.completed.toggle()
                dataController.save()
            } label: {
                Label(issue.completed ? "Re-open Issue" : "Close Issue",
                      systemImage: issue.completed ? "ellipsis.bubble" : "ellipsis.bubble.fill")
            }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
        }
    }
}

struct IssueViewToolbar_Previews: PreviewProvider {
    static var previews: some View {
        IssueViewToolbar(issue: Issue.example)
    }
}
