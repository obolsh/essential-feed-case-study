//
//  FeedLoader.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 08.08.2023.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
