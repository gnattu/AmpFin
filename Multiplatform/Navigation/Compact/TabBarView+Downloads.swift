//
//  Navigation+Artists.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBase

extension TabBarView {
    struct DownloadsTab: View {
        @State var navigationPath = NavigationPath()
        
        var body: some View {
            NavigationStack(path: $navigationPath) {
                LibraryView()
                    .navigationDestination(for: Navigation.AlbumLoadDestination.self) { data in
                        AlbumLoadView(albumId: data.albumId)
                    }
            }
            .environment(\.libraryDataProvider, OfflineLibraryDataProvider())
            .modifier(CompactNowPlayingBarModifier())
            .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateNotification)) { notification in
                if let albumId = notification.userInfo?["offlineAlbumId"] as? String {
                    navigationPath.append(Navigation.AlbumLoadDestination(albumId: albumId))
                }
            }
            .tabItem {
                Label("tab.downloads", systemImage: "arrow.down")
            }
        }
    }
}