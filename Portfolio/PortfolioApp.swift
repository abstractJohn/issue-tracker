//
//  PortfolioApp.swift
//  Portfolio
//
//  Created by John Nelson on 7/18/23.
//

import SwiftUI

@main
struct PortfolioApp: App {
    @StateObject var dataController = DataController()
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
            } content: {
                ContentView()
            } detail: {
                DetailView()
            }
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
        }
    }
}
