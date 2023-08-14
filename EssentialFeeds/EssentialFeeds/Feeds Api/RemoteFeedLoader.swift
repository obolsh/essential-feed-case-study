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

    public enum Error: Swift.Error {
        case connectivity
    }

    public init(client: HttpClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (Error) -> Void = { _ in }) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}

public protocol HttpClient {
    func get (from url: URL, completion: @escaping (Error) -> Void)
}
