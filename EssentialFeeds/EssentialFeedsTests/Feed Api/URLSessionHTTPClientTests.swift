//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 30.08.2023.
//

import XCTest
import EssentialFeeds

class URLSessionHTTPClient {

  private var session: URLSession

  init(session: URLSession) {
    self.session = session
  }

  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { _, _, error in
      if let error = error {
        completion(.failure(error))
      }
    }.resume()
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
    sut.get(from: url) { _ in }

    XCTAssertEqual(task.resumeCallCount, 1)
  }

  func test_getFromURL_failWithError() {
    let url = URL(string: "https://any-url.com")!

    let expectedRrror = NSError(domain: "network error", code: 1)
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()

    session.stub(url: url, error: expectedRrror)

    let sut = URLSessionHTTPClient(session: session)

    let exp = expectation(description: "Wait for error")
    sut.get(from: url) { result in
      switch result {
      case let .failure(error as NSError):
        XCTAssertEqual(error, expectedRrror)
      default:
        XCTFail("Error expected")
      }
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
  }

  private class URLSessionSpy: URLSession {
    private var stubs = [URL : Stub] ()

    private struct Stub {
      let task: URLSessionDataTask
      let error: NSError?
    }

    func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: NSError? = nil) {
      stubs[url] = Stub(task: task, error: error)
    }

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
      guard let stub = stubs[url] else {
        fatalError("Can't find stub for \(url)")
      }
      completionHandler(nil, nil, stub.error)
      return stub.task
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
