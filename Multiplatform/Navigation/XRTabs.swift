//
//  XRTabs.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.05.24.
//

import SwiftUI
import Defaults

struct XRTabs: View {
    @Default(.searchTab) private var searchTab
    
    @State private var search = ""
    
    var body: some View {
        TabView {
            Sidebar(provider: .online)
                .tabItem {
                    Label("tab.libarary", systemImage: "rectangle.stack.fill")
                }
            
            Sidebar(provider: .offline)
                .tabItem {
                    Label("tab.downloads", systemImage: "arrow.down")
                }
            
            NavigationStack {
                SearchView(search: $search, searchTab: $searchTab, selected: .constant(true))
                    .modifier(Navigation.DestinationModifier())
            }
            .environment(\.libraryDataProvider, searchTab.dataProvider)
            .tabItem {
                Label("tab.search", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview {
    XRTabs()
}
