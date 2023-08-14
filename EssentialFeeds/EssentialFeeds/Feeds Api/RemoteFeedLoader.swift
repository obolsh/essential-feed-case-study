//
//  RemoteFeedLoader.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 14.08.2023.
//

import Foundation

public class RemoteFeedLoader {

    private let client: HttpClient
    private let url: URL

    public init(client: HttpClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() {
        client.get(from: url)
    }
}

public protocol HttpClient {
    func get (from url: URL)
}
