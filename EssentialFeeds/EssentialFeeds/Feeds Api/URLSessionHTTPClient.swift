//
//  URLSessionHTTPClient.swift
//  EssentialFeeds
//
//  Created by Oleksii Bolshakov on 01.09.2023.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {

  private var session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  struct UnexpectedResponseValues: Error {}

  public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { data, response, error in
      if let error = error {
        completion(.failure(error))
      } else if let data = data, let response = response as? HTTPURLResponse {
        completion(.success(data, response))
      } else{
        completion(.failure(UnexpectedResponseValues()))
      }
    }.resume()
  }
}
