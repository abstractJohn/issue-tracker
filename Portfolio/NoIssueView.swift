//
//  NoIssueView.swift
//  Portfolio
//
//  Created by John Nelson on 7/19/23.
//

import SwiftUI

struct NoIssueView: View {
    @EnvironmentObject var dataController: DataController
    var body: some View {
        Text("No Issue Selected")
            .font(.title)
            .foregroundStyle(.secondary)
        
        Button("New Issue") {
            //make a new Issue
        }
    }
}

struct NoIssueView_Previews: PreviewProvider {
    static var previews: some View {
        NoIssueView()
    }
}
