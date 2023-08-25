//
//  HTTPClient.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 26.08.2023.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HttpClient {
    func get (from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
