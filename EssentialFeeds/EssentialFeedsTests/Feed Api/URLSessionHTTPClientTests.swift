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
    session.dataTask(with: url) { _, _, _ in }.resume()
  }
}

 // MARK: - Helpers

final class URLSessionHTTPClientTests: XCTestCase {

  func test_getFromURL_resumesDataTaskWithURL() {
    let url = URL(string: "https://any-url.com")!
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()

    session.stub(url: url, task: task)
    let sut = URLSessionHTTPClient(session: session)
    sut.get(from: url)

    XCTAssertEqual(task.resumeCallCount, 1)
  }

  private class URLSessionSpy: URLSession {
    private var stubs = [URL : URLSessionDataTask] ()

    func stub(url: URL, task: URLSessionDataTask) {
      stubs[url] = task
    }

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
      return stubs[url] ?? FakeURLSessionDataTask()
    }
  }

  private class FakeURLSessionDataTask: URLSessionDataTask {
    override func resume() { }
  }

  private class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCallCount = 0

    override func resume() {
      resumeCallCount += 1
    }
  }

}
