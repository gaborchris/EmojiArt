//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Christian Gabor on 5/8/20.
//  Copyright © 2020 Christian Gabor. All rights reserved.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    static let palette: String = "😍🥰😉😊😂😁👿👾🐯"
    @Published private(set) var selectedEmojis = Set<EmojiArt.Emoji>()
    
    // @Published // workaround with property wrappers
    private var emojiArt: EmojiArt = EmojiArt() {
        willSet {
            objectWillChange.send()
        }
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    

    
    // MARK: Intents(s)
    
    func reset() {
        emojiArt = EmojiArt()
        fetchBackgroundImageData()
        selectedEmojis = Set<EmojiArt.Emoji>()
    }
    
    func deleteSelection(){
        for emoji in selectedEmojis {
            emojiArt.removeEmoji(emoji)
        }
    }
    
    func selectEmoji(_ emoji: EmojiArt.Emoji) {
        selectedEmojis.toggleMatching(emoji)
    }
    
    func deselectEmojis() {
        for emoji in selectedEmojis {
            selectedEmojis.toggleMatching(emoji)
        }
    }
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize){
        selectedEmojis.remove(emoji)
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
            selectedEmojis.insert(emojiArt.emojis[index])
        }
    }
    
    //func setEmojiSize(_ emoji: EmojiArt.Emoji, by scale: CGFloat) 
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat){
        selectedEmojis.remove(emoji)
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
            selectedEmojis.insert(emojiArt.emojis[index])
        }
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
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
