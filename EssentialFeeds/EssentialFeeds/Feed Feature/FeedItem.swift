//
//  FeedItem.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 08.08.2023.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
