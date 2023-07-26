//
//  SidebarViewToolbar.swift
//  Portfolio
//
//  Created by John Nelson on 7/26/23.
//

import SwiftUI

struct SidebarViewToolbar: View {
    @EnvironmentObject var dataController: DataController
    @Binding var showingAwards: Bool
    var body: some View {
        Button(action: dataController.newTag) {
            Label("Add Tag", systemImage: "plus")
        }
        
        Button {
            showingAwards.toggle()
        } label: {
            Label("Show Awards", systemImage: "rosette")
        }
        
        #if DEBUG
        Button {
            dataController.deleteAll()
            dataController.createSampleData()
        } label: {
            Label("ADD SAMPLES", systemImage: "command.square.fill")
        }
        #endif
    }
}

struct SidebarViewToolbar_Previews: PreviewProvider {
    static var previews: some View {
        SidebarViewToolbar(showingAwards: .constant(true))
    }
}
