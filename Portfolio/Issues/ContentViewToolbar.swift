//
//  ContentViewToolbar.swift
//  Portfolio
//
//  Created by John Nelson on 7/26/23.
//

import SwiftUI

struct ContentViewToolbar: View {
    @StateObject private var viewModel: ContentView.ViewModel

    init(viewModel: ContentView.ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        Menu {
            Button(viewModel.filterEnabled ? "Turn Filter Off" : "Turn Filter On") {
                viewModel.filterEnabled.toggle()
            }

            Divider()

            Menu("Sort By") {
                Picker("Sort By", selection: $viewModel.sortType) {
                    Text("Date Created").tag(SortType.dateCreated)
                    Text("Date Modified").tag(SortType.dateModified)
                }

                Divider()

                Picker("Sort Order", selection: $viewModel.sortNewestFirst) {
                    Text("Newest to Oldest").tag(true)
                    Text("Oldest to Newest").tag(false)
                }
            }

            Picker("Status", selection: $viewModel.filterStatus) {
                Text("All").tag(Status.all)
                Text("Open").tag(Status.open)
                Text("Closed").tag(Status.closed)
            }
            .disabled(viewModel.filterEnabled == false)

            Picker("Priority", selection: $viewModel.filterPriority) {
                Text("All").tag(-1)
                Text("Low").tag(0)
                Text("Medium").tag(1)
                Text("High").tag(2)
            }
            .disabled(viewModel.filterEnabled == false)
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .symbolVariant(viewModel.filterEnabled ? .fill : .none)
        }

        Button(action: viewModel.dataController.newIssue) {
            Label("New Issue", systemImage: "plus")
        }
    }
}

struct ContentViewToolbar_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ContentView.ViewModel(dataController: .preview)
        ContentViewToolbar(viewModel: viewModel)
    }
}
