//
//  TrackListRow.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import SwiftUI
import AFBaseKit
import AFPlaybackKit

struct TrackListRow: View {
    let track: Track
    var album: Album? = nil
    
    var deleteCallback: TrackList.DeleteCallback = nil
    let startPlayback: () -> ()
    
    var disableMenu: Bool = false
    
    var body: some View {
        let showArtist = album == nil || !track.artists.elementsEqual(album!.artists) { $0.id == $1.id }
        
        HStack {
            Button {
                startPlayback()
            } label: {
                if album != nil {
                    Text(String(track.index.index))
                        .frame(width: 23)
                        .fontDesign(.rounded)
                    // .padding(.horizontal, 7)
                } else {
                    ItemImage(cover: track.cover)
                        .frame(width: 45)
                }
                
                VStack(alignment: .leading) {
                    Text(track.name)
                        .lineLimit(1)
                        .font(.body)
                        .padding(.vertical, showArtist ? 0 : 6)
                    
                    if showArtist, let artistName = track.artistName {
                        Text(artistName)
                            .lineLimit(1)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 5)
                
                Spacer()
            }
            .buttonStyle(.plain)
            
            DownloadIndicator(item: track)
            
            if !disableMenu {
                Menu {
                    TrackMenu(track: track, album: album, deleteCallback: deleteCallback)
                } label: {
                    Image(systemName: "ellipsis")
                        .renderingMode(.original)
                        .foregroundStyle(Color(UIColor.label))
                        .padding(.vertical, 10)
                        .padding(.leading, 0)
                }
                .popoverTip(InstantMixTip())
            }
        }
        .draggable(track) {
            TrackPreview(track: track)
                .padding(4)
        }
        .contextMenu {
            TrackMenu(track: track, album: album, deleteCallback: deleteCallback)
        } preview: {
            TrackPreview(track: track)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            PlayNextButton(track: track)
        }
        .swipeActions(edge: .leading) {
            PlayLastButton(track: track)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            FavoriteButton(track: track)
        }
    }
}

// MARK: Buttons

extension TrackListRow {
    struct TrackPreview: View {
        let track: Track
        
        var body: some View {
            HStack {
                ItemImage(cover: track.cover)
                    .frame(width: 45)
                
                VStack(alignment: .leading) {
                    Text(track.name)
                    
                    if let artistName = track.artistName {
                        Text(artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    struct TrackMenu: View {
        @Environment(\.libraryDataProvider) var dataProvider
        @Environment(\.libraryOnline) var libraryOnline
        
        let track: Track
        let album: Album?
        
        let deleteCallback: TrackList.DeleteCallback
        
        var body: some View {
            PlayNextButton(track: track)
            PlayLastButton(track: track)
            
            Divider()
            
            FavoriteButton(track: track)
            
            Button {
                Task {
                    try? await track.startInstantMix()
                }
            } label: {
                Label("queue.mix", systemImage: "compass.drawing")
            }
            .disabled(!libraryOnline)
            
            Divider()
            
            if album == nil {
                NavigationLink(destination: AlbumLoadView(albumId: track.album.id)) {
                    Label("album.view", systemImage: "square.stack")
                    
                    if let name = track.album.name {
                        Text(verbatim: name)
                    }
                }
            }
            
            if let artist = track.artists.first {
                NavigationLink(destination: ArtistLoadView(artistId: artist.id)) {
                    Label("artist.view", systemImage: "music.mic")
                        .disabled(!dataProvider.supportsArtistLookup)
                    Text(artist.name)
                }
            }
            
            if let deleteCallback = deleteCallback {
                Divider()
                
                Button(role: .destructive) {
                    deleteCallback(track)
                } label: {
                    Label("playlist.remove", systemImage: "trash.fill")
                }
            }
        }
    }
    
    struct PlayNextButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.current.queueTrack(track, index: 0)
            } label: {
                Label("queue.next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
    }
    struct PlayLastButton: View {
        let track: Track
        
        var body: some View {
            Button {
                AudioPlayer.current.queueTrack(track, index: AudioPlayer.current.queue.count)
            } label: {
                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            .tint(.blue)
        }
    }
    
    struct FavoriteButton: View {
        let track: Track
        
        var body: some View {
            Button {
                Task {
                    await track.setFavorite(favorite: !track.favorite)
                }
            } label: {
                Label("favorite", systemImage: track.favorite ? "heart.fill" : "heart")
            }
            .tint(.orange)
        }
    }
}
