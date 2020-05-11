//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Christian Gabor on 5/8/20.
//  Copyright © 2020 Christian Gabor. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            
            HStack {
                Button(action: { self.document.deleteSelection()}, label: {
                    Text("Delete Selection").foregroundColor(Color.primary).padding().background(Color.clear)
                        .border(Color.primary, width: buttonBorder)
                })
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(EmojiArtDocument.palette.map{ String($0)}, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { return NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                Button(action: { self.document.reset()}, label: {
                    Text("Reset Scene").foregroundColor(Color.primary).padding().background(Color.clear)
                        .border(Color.primary, width: buttonBorder)
                })

            }
            .padding()
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                        
                    ForEach(self.document.emojis) { emoji in
                        EmojiBody(content: emoji.text, isSelected: self.document.selectedEmojis.contains(emoji))
                            .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                            .position(self.position(for: emoji, in: geometry.size))
                            .onTapGesture {self.document.selectEmoji(emoji)}
                            .gesture(self.dragSelectionGesture(emoji))
                            
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.deselectGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
            }
        }
    }
    private let buttonBorder: CGFloat = 2.0
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var previousZoomScale: CGFloat = 1.0
    
    private func deselectGesture() -> some Gesture {
        TapGesture().onEnded {
            self.document.deselectEmojis()
        }
    }
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        if !self.document.selectedEmojis.isEmpty {
            return MagnificationGesture()
                .updating($previousZoomScale) { latestGestureScale, previousZoomScale, transition in
                    for emoji in self.document.selectedEmojis {
                        // Divide by previous scaling and update by current scaling to cancel out continuous mulitplication
                        self.document.scaleEmoji(emoji, by: latestGestureScale / self.previousZoomScale)
                        previousZoomScale = latestGestureScale
                    }
                }
            .onEnded() {_ in
                // No need to update any vars on end but need to conform to same type
            }
        } else {
            return MagnificationGesture()
                .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                    gestureZoomScale = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    self.steadyStateZoomScale *= finalGestureScale
            }
        }
    }

   
    
    @GestureState private var gestureSelectionOffset: CGSize = .zero
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    
    // Notes:
    // Went through several options and went with this design because it felt best
    // Pan gesture always works whether or not emojis are selected
    // If the user drags ontop of the selected emoji it pans the selection instead of scene
    // Did not want emojis to move if a drag occurs away from the selection because it felt unintuitive
    
    // Tried to make this cleaner, but swift complained about opague return types
    
    private func dragSelectionGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        // Pan document if dragged over emoji isn't selected
        // Copied code from panGesture, but would have preferred to return panGesture() in here
        // Wasn't sure how to avoid opaque return types
        if self.document.selectedEmojis.isEmpty || !self.document.selectedEmojis.contains(emoji){
            return DragGesture()
                .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                     gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
                }
                .onEnded { finalDragGestureValue in
                     self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
                }
        } else {
            return DragGesture()
              .updating($gestureSelectionOffset) { lastDragGestureValue, gestureSelectionOffset, transaction in
                for emoji in self.document.selectedEmojis {
                    self.document.moveEmoji(emoji, by: (lastDragGestureValue.translation - self.gestureSelectionOffset) / self.zoomScale)
                    gestureSelectionOffset = lastDragGestureValue.translation
                }
            }
            .onEnded() { finalDragGestureValue in }
        }
    }
    
    
    private func panGesture() -> some Gesture {
       DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }
    
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                self.zoomToFit(self.document.backgroundImage, in: size)
                }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func font(for emoji: EmojiArt.Emoji) -> Font {
        Font.system(size: emoji.fontSize * zoomScale)
    }
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + self.panOffset.width, y: location.y + self.panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}

struct EmojiBody: View {
    var content: String
    var isSelected: Bool

    var body: some View {
        Group {
            if isSelected {
                Text(content)
                    .border(Color.green, width: 5)
            }
            else {
                Text(content)
            }
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentView()
//    }
//}

//extension String: Identifiable {
//    public var id: String { return self }
//}
