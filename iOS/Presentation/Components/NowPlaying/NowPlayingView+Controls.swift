//
//  NowPlayingView+Controls.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import AVKit
import MediaPlayer
import AFBase
import AFPlayback

extension NowPlayingViewModifier {
    struct Controls: View {
        @Binding var currentTab: Tab {
            didSet {
                queueTabActive = currentTab == .queue
            }
        }
        
        @State private var quality: String?
        
        @State private var dragging = false
        @State private var draggedPercentage = 0.0
        
        @State private var queueTabActive = false
        
        private var playedPercentage: Double {
            (AudioPlayer.current.currentTime / AudioPlayer.current.duration) * 100
        }
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: .init(get: { dragging ? draggedPercentage : playedPercentage }, set: { draggedPercentage = $0 }), dragging: $dragging, onEnded: {
                        AudioPlayer.current.currentTime = AudioPlayer.current.duration * (playedPercentage / 100)
                    })
                    .frame(height: 10)
                    .padding(.bottom, 10)
                    
                    HStack {
                        Group {
                            if AudioPlayer.current.buffering {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Text(Duration.seconds(AudioPlayer.current.currentTime).formatted(.time(pattern: .minuteSecond)))
                            }
                        }
                        .frame(width: 65, alignment: .leading)
                        
                        if let quality = quality {
                            Spacer()
                            
                            Text(quality)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        Spacer()
                        
                        Text(Duration.seconds(AudioPlayer.current.currentTime).formatted(.time(pattern: .minuteSecond)))
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                HStack {
                    Group {
                        Button {
                            withAnimation {
                                AudioPlayer.current.backToPreviousItem()
                            }
                        } label: {
                            Image(systemName: "backward.fill")
                        }
                        Button {
                            AudioPlayer.current.playing = !AudioPlayer.current.playing
                        } label: {
                            Image(systemName: AudioPlayer.current.playing ? "pause.fill" : "play.fill")
                                .frame(height: 50)
                                .font(.system(size: 47))
                                .padding(.horizontal, 50)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        Button {
                            withAnimation {
                                AudioPlayer.current.advanceToNextTrack()
                            }
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                }
                .padding(.top, 35)
                .padding(.bottom, 65)
                
                // The first view is the visible slider, the second one is there to hide the iOS indicator (10/10 hack)
                VolumeSlider()
                VolumeView()
                    .frame(width: 0, height: 0)
                
                HStack {
                    Spacer()
                    
                    if AudioPlayer.current.source == .local {
                        // disabled until lyrics are fully supported by the stable server
                        #if DEBUG
                        Button {
                            setActiveTab(.lyrics)
                        } label: {
                            Image(systemName: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                        }
                        .foregroundStyle(currentTab == .lyrics ? .primary : .secondary)
                        
                        Spacer()
                        #endif
                        
                        AirPlayView()
                            .frame(width: 45)
                        
                        Spacer()
                        
                        Button {
                            setActiveTab(.queue)
                        } label: {
                            Image(systemName: "list.dash")
                        }
                        .buttonStyle(SymbolButtonStyle(active: queueTabActive))
                    } else if AudioPlayer.current.source == .jellyfinRemote {
                        Button {
                            AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                        } label: {
                            Image(systemName: "shuffle")
                        }
                        .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.shuffled))
                        
                        Spacer()
                        
                        Button {
                            if AudioPlayer.current.repeatMode == .none {
                                AudioPlayer.current.repeatMode = .queue
                            } else if AudioPlayer.current.repeatMode == .queue {
                                AudioPlayer.current.repeatMode = .track
                            } else if AudioPlayer.current.repeatMode == .track {
                                AudioPlayer.current.repeatMode = .none
                            }
                        } label: {
                            if AudioPlayer.current.repeatMode == .track {
                                Image(systemName: "repeat.1")
                            } else if AudioPlayer.current.repeatMode == .none || AudioPlayer.current.repeatMode == .queue {
                                Image(systemName: "repeat")
                            }
                        }
                        .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
                        
                        Spacer()
                        
                        Button {
                            AudioPlayer.current.destroy()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(SymbolButtonStyle(active: false))
                    } else {
                        Button {
                            setActiveTab(currentTab == .cover ? .queue : .cover)
                        } label: {
                            Image(systemName: "command")
                        }
                        .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
                    }
                    
                    Spacer()
                }
                .bold()
                .font(.system(size: 20))
                .frame(height: 45)
                .padding(.top, 35)
                .padding(.bottom, 40)
            }
            .onChange(of: AudioPlayer.current.nowPlaying) { fetchQuality() }
            .onAppear(perform: fetchQuality)
        }
        
        // this has to be here for reasons that are beyond me
        func setActiveTab(_ tab: Tab) {
            withAnimation(.spring(duration: 0.3, bounce: 0.25, blendDuration: 1)) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
        }
    }
}

// MARK: Helper

extension NowPlayingViewModifier.Controls {
    func fetchQuality() {
        Task.detached {
            if let data = await AudioPlayer.current.getTrackData() {
                withAnimation {
                    if data.1 == 0 {
                        quality = data.0.uppercased()
                    } else {
                        quality = "\(data.0.uppercased()) \(data.1)"
                    }
                }
            } else {
                quality = nil
            }
        }
    }
}

// MARK: Airplay view

extension NowPlayingViewModifier {
    struct AirPlayView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let routePickerView = AVRoutePickerView()
            routePickerView.backgroundColor = UIColor.clear
            routePickerView.activeTintColor = UIColor(Color.accentColor)
            routePickerView.tintColor = UIColor(Color.white.opacity(0.6))
            
            return routePickerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}
