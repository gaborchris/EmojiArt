//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Christian Gabor on 5/8/20.
//  Copyright © 2020 Christian Gabor. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    let id: UUID
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
     
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let palette: String = "😍🥰😉😊😂😁👿👾🐯"
    
    @Published
    private var emojiArt: EmojiArt
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDoccument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        self.autosaveCancellable = $emojiArt.sink { emojiArt in
            print("\(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
            
        }
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    

    
    // MARK: Intents(s)
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize){
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat){
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
            fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
        }
    }
}


extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size)}
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}

struct EmojiArtDocument_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
