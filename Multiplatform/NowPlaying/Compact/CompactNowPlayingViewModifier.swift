//
//  NowPlayingView.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import SwiftUI
import UIImageColors
import AFBase
import AFPlayback

struct CompactNowPlayingViewModifier: ViewModifier {
    @Namespace private var namespace
    
    @State private var viewState = NowPlayingViewState.init()
    
    @State private var controlsVisible = true
    @State private var currentTab = NowPlayingTab.cover
    
    @State private var controlsDragging = false
    @State private var dragOffset: CGFloat = .zero
    
    private var presentedTrack: Track? {
        if viewState.presented, let track = AudioPlayer.current.nowPlaying {
            return track
        }
        
        return nil
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!viewState.presented)
                .onAppear {
                    viewState.namespace = namespace
                }
                .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateNotification)) { _ in
                    viewState.setNowPlayingViewPresented(false)
                }
            
            Group {
                if let track = presentedTrack {
                    NowPlayingBackground(cover: track.cover)
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true), identity: BackgroundInsertTransitionModifier(active: false)),
                            removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true), identity: BackgroundRemoveTransitionModifier(active: false)))
                        )
                        .onAppear {
                            // In rare cases, this value is not set to 0 on closing.
                            // Forcing a reset to 0 on appearance to prevent strange animations
                            // where the container appears halfway on the screen.
                            dragOffset = 0
                        }
                }
                
                if viewState.containerPresented {
                    VStack {
                        if let track = presentedTrack {
                            if currentTab == .cover {
                                NowPlayingCover(track: track, currentTab: currentTab, namespace: namespace)
                            } else {
                                NowPlayingSmallTitle(track: track, namespace: namespace, currentTab: $currentTab)
                                    .transition(.opacity.animation(.linear(duration: 0.1)))
                                
                                Group {
                                    if currentTab == .lyrics {
                                        NowPlayingLyricsContainer(controlsVisible: $controlsVisible)
                                    } else if currentTab == .queue {
                                        NowPlayingQueue()
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion:
                                            .push(from: .bottom).animation(.spring.delay(0.2))
                                            .combined(with: .opacity),
                                    removal:
                                            .push(from: .top).animation(.spring.logicallyComplete(after: 0.1))
                                            .combined(with: .opacity)
                                ))
                            }
                            
                            if controlsVisible {
                                Group {
                                    NowPlayingControls(compact: false, controlsDragging: $controlsDragging)
                                    NowPlayingButtons(currentTab: $currentTab)
                                        .padding(.top, 20)
                                        .padding(.bottom, 30)
                                }
                                .transition(.opacity.animation(.linear(duration: 0.2)))
                            }
                        }
                    }
                    .zIndex(2)
                    .foregroundStyle(.white)
                    .overlay(alignment: .top) {
                        if presentedTrack != nil {
                            Button {
                                viewState.setNowPlayingViewPresented(false)
                            } label: {
                                Rectangle()
                                    .foregroundStyle(.white.secondary.opacity(0.75))
                                    .frame(width: 50, height: 7)
                                    .clipShape(RoundedRectangle(cornerRadius: 10000))
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.linear(duration: 0.1).delay(0.3)),
                                removal: .opacity.animation(.linear(duration: 0.05))))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onChanged {
                                if controlsDragging || currentTab == .lyrics {
                                    return
                                }
                                
                                if $0.velocity.height > 3000 {
                                    viewState.setNowPlayingViewPresented(false) {
                                        dragOffset = 0
                                    }
                                } else if $0.velocity.height < -3000 {
                                    dragOffset = 0
                                } else {
                                    dragOffset = max(0, $0.translation.height)
                                }
                            }
                            .onEnded {
                                if $0.translation.height > 200 && dragOffset != 0 {
                                    viewState.setNowPlayingViewPresented(false) {
                                        dragOffset = 0
                                    }
                                } else {
                                    dragOffset = 0
                                }
                            }
                    )
                    .onChange(of: currentTab) {
                        dragOffset = 0
                        
                        if currentTab == .cover {
                            controlsVisible = true
                        }
                    }
                }
            }
            .allowsHitTesting(presentedTrack != nil)
            // This is very reasonable and sane
            .offset(y: dragOffset)
            .animation(.spring, value: dragOffset)
        }
        .ignoresSafeArea(edges: .all)
        .environment(viewState)
        .onChange(of: viewState.presented) {
            controlsVisible = true
        }
        .onChange(of: currentTab) {
            controlsVisible = true
        }
    }
}

struct BackgroundInsertTransitionModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var viewState
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(maxHeight: active ? 0 : .infinity)
                    .padding(.horizontal, active ? 12 : 0)
            }
            .offset(y: active ? -146 : 0)
    }
}

// This is more a "collapse" than a move thing
struct BackgroundRemoveTransitionModifier: ViewModifier {
    @Environment(NowPlayingViewState.self) private var viewState
    
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(maxHeight: active ? 0 : .infinity)
                    .padding(.horizontal, active ? 12 : 0)
                    .animation(Animation.smooth(duration: 0.4, extraBounce: 0.1), value: active)
            }
            .offset(y: active ? -92 : 0)
    }
}

@Observable
final class NowPlayingViewState {
    var namespace: Namespace.ID!
    
    private(set) var presented = false
    private(set) var containerPresented = false
    
    private(set) var active = false
    private(set) var lastActive = Date()
    
    func setNowPlayingViewPresented(_ presented: Bool, completion: (() -> Void)? = nil) {
        if active && lastActive.timeIntervalSince(Date()) > -1 {
            return
        }
        
        active = true
        lastActive = Date()
        
        if presented {
            containerPresented = true
        }
        
        withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
            self.presented = presented
        } completion: {
            self.active = false
            
            if !self.presented {
                self.containerPresented = false
            }
            
            completion?()
        }
    }
}
