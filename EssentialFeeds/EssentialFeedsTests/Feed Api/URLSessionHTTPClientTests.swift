//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 30.08.2023.
//

import XCTest

class URLSessionHTTPClient {

  private var session: URLSession

  init(session: URLSession) {
    self.session = session
  }

  func get(from url: URL) {
    session.dataTask(with: url) { _, _, _ in }
  }
}

 // MARK: - Helpers

final class URLSessionHTTPClientTests: XCTestCase {

  func test_getFromURL_receiveDataTaskWithURL() {
    let url = URL(string: "https://any-url.com")!

    let session = URLSessionSpy()

    let sut = URLSessionHTTPClient(session: session)
    sut.get(from: url)

    XCTAssertEqual(session.receivedURLs, [url])
  }

  private class URLSessionSpy: URLSession {
    var receivedURLs = [URL]()

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
      receivedURLs.append(url)
      return FakeURLSessionDataTask()
    }
  }

  private class FakeURLSessionDataTask: URLSessionDataTask {}

}
