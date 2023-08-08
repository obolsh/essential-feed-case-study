//
//  FeedLoader.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 08.08.2023.
//

import Foundation

enum FeedLoadResult {
    case succes([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: (FeedLoadResult) -> Void)
}
