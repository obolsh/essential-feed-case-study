//
//  RemoteFeedLoader.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 14.08.2023.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get (from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public class RemoteFeedLoader {

    private let client: HttpClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HttpClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }
}
