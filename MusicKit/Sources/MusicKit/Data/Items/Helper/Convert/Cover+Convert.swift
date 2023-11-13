//
//  ItemCover+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Item.Cover {
    static func convertFromJellyfin(imageTags: JellyfinClient.ImageTags, id: String) -> Item.Cover? {
        if let primaryImageTag = imageTags.Primary {
            return Item.Cover(type: .jellyfin, url: constructItemCoverUrl(itemId: id, imageTag: primaryImageTag))
        }
        
        return nil
    }
    
    static func constructItemCoverUrl(itemId: String, imageTag: String, size: Int = 800, quality: Int = 96) -> URL {
        JellyfinClient.shared.serverUrl.appending(path: "Items").appending(path: itemId).appending(path: "Images").appending(path: "Primary").appending(queryItems: [
            URLQueryItem(name: "fillHeight", value: String(size)),
            URLQueryItem(name: "fillWidth", value: String(size)),
            URLQueryItem(name: "quality", value: String(quality)),
            URLQueryItem(name: "tag", value: imageTag),
            // TODO: i hope this will become necessary: URLQueryItem(name: "token", value: JellyfinClient.shared.token),
        ])
    }
}