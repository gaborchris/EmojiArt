//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Christian Gabor on 5/9/20.
//  Copyright © 2020 Christian Gabor. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
    
}
