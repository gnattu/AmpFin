//
//  NowPlayingButtons.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.04.24.
//

import SwiftUI
import AmpFinKit
import AFPlayback
import AVKit

extension NowPlaying {
    struct Buttons: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        @Binding var currentTab: Tab
        
        #if targetEnvironment(macCatalyst)
        @State private var airPlayView = AirPlayView()
        #endif
        
        private var compactLayout: Bool {
            horizontalSizeClass == .compact
        }
        
        private var routeIcon: String {
            switch AudioPlayer.current.outputRoute.port {
                case .usbAudio:
                    "cable.connector"
                case .thunderbolt:
                    "bolt"
                case .lineOut:
                    "cable.coaxial"
                case .carAudio:
                    "car"
                case .airPlay:
                    "airplayaudio"
                case .HDMI, .displayPort:
                    "tv"
                case .bluetoothLE, .bluetoothHFP, .bluetoothA2DP:
                    "hifispeaker"
                case .headphones:
                    "headphones"
                default:
                    "airplayaudio"
            }
        }
        
        @ViewBuilder private var lyricsButton: some View {
            Button {
                setActiveTab(.lyrics)
            } label: {
                Label("lyrics", systemImage: currentTab == .lyrics ? "text.bubble.fill" : "text.bubble")
                    .labelStyle(.iconOnly)
            }
            .foregroundStyle(currentTab == .lyrics ? .thickMaterial : .thinMaterial)
            .animation(.none, value: currentTab)
            .buttonStyle(.plain)
            .modifier(HoverEffectModifier(padding: 4))
        }
        @ViewBuilder private var queueButton: some View {
            Menu {
                Toggle("shuffle", systemImage: "shuffle", isOn: .init(get: { AudioPlayer.current.shuffled }, set: { AudioPlayer.current.shuffled = $0 }))
                
                Menu {
                    Button {
                        AudioPlayer.current.repeatMode = .none
                    } label: {
                        Label("repeat.none", systemImage: "slash.circle")
                    }
                    
                    Button {
                        AudioPlayer.current.repeatMode = .queue
                    } label: {
                        Label("repeat.queue", systemImage: "repeat")
                    }
                    
                    Button {
                        AudioPlayer.current.repeatMode = .track
                    } label: {
                        Label("repeat.track", systemImage: "repeat.1")
                    }
                } label: {
                    Label("repeat", systemImage: "repeat")
                }
            } label: {
                Label("queue", systemImage: "list.dash")
                    .labelStyle(.iconOnly)
            } primaryAction: {
                setActiveTab(.queue)
            }
            .buttonStyle(SymbolButtonStyle(active: currentTab == .queue))
            .modifier(HoverEffectModifier(padding: 4))
        }
        
        var body: some View {
            HStack(alignment: .center) {
                if AudioPlayer.current.source == .local {
                    if compactLayout {
                        Spacer()
                        
                        lyricsButton
                            .frame(width: 75)
                        
                        Spacer()
                        
                        Button {
                            AirPlay.shared.presentPicker()
                        } label: {
                            Label("output", systemImage: routeIcon)
                                .labelStyle(.iconOnly)
                                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                        }
                        .buttonStyle(SymbolButtonStyle(active: false))
                        .modifier(HoverEffectModifier(padding: 4))
                        .frame(width: 75)
                        .overlay(alignment: .bottom) {
                            if AudioPlayer.current.outputRoute.showLabel {
                                Text(AudioPlayer.current.outputRoute.name)
                                    .lineLimit(1)
                                    .font(.caption2.smallCaps())
                                    .foregroundStyle(.thinMaterial)
                                    .offset(y: 12)
                                    .fixedSize()
                            }
                        }
                        
                        Spacer()
                        
                        queueButton
                            .frame(width: 75)
                        
                        Spacer()
                    } else if horizontalSizeClass == .regular {
                        HStack(spacing: 4) {
                            Button {
#if targetEnvironment(macCatalyst)
                                airPlayView.showAirPlayMenu()
#else
                                AirPlay.shared.presentPicker()
#endif
                            } label: {
                                Label("output", systemImage: routeIcon)
                                    .labelStyle(.iconOnly)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            }
                            .buttonStyle(SymbolButtonStyle(active: false))
                            .modifier(HoverEffectModifier(padding: 4))
                            
                            if AudioPlayer.current.outputRoute.showLabel {
                                Text(AudioPlayer.current.outputRoute.name)
                                    .lineLimit(1)
                                    .font(.caption.smallCaps())
                                    .foregroundStyle(.thinMaterial)
                            }
                        }
#if targetEnvironment(macCatalyst)
                        .overlay {
                            ZStack {
                                airPlayView.frame(width: 44, height: 44).offset(x: 17.0, y: 304.0)
                            }
                        }
#endif
                        
                        Spacer()
                        
                        lyricsButton
                            .padding(.horizontal, 16)
                        queueButton
                    }
                } else if AudioPlayer.current.source == .jellyfinRemote {
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.shuffled = !AudioPlayer.current.shuffled
                    } label: {
                        Label("shuffle", systemImage: "shuffle")
                            .labelStyle(.iconOnly)
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
                        Label("repeat", systemImage: "repeat\(AudioPlayer.current.repeatMode == .track ? ".1" : "")")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: AudioPlayer.current.repeatMode != .none))
                    
                    Spacer()
                    
                    Button {
                        AudioPlayer.current.stopPlayback()
                    } label: {
                        Label("remote.stop", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(SymbolButtonStyle(active: false))
                    
                    Spacer()
                }
            }
            .bold()
            .font(.system(size: 20))
            .frame(height: 44)
        }
        
        private func setActiveTab(_ tab: Tab) {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                if currentTab == tab {
                    currentTab = .cover
                } else {
                    currentTab = tab
                }
            }
        }
    }
}

private struct AirPlay {
    let routePickerView = AVRoutePickerView()
    
    private init() {}
    
    func presentPicker() {
        for view in routePickerView.subviews {
            guard let button = view as? UIButton else {
                continue
            }
            
            button.sendActions(for: .touchUpInside)
            break
        }
    }
    
    static let shared = AirPlay()
}

private struct AirPlayView: UIViewRepresentable {
    
    private let routePickerView = AVRoutePickerView()

    func makeUIView(context: UIViewRepresentableContext<AirPlayView>) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AirPlayView>) {
        routePickerView.isHidden = true
        routePickerView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(routePickerView)

        NSLayoutConstraint.activate([
            routePickerView.topAnchor.constraint(equalTo: uiView.topAnchor),
            routePickerView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            routePickerView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
            routePickerView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor)
        ])
    }
    
    func showAirPlayMenu() {
        for view: UIView in routePickerView.subviews {
            if let button = view as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
            }
        }
    }
}
