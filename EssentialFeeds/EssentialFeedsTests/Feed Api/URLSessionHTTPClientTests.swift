//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 30.08.2023.
//

import XCTest
import EssentialFeeds

protocol HTTPSession {
  func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
  func resume()
}

class URLSessionHTTPClient {

  private var session: HTTPSession

  init(session: HTTPSession) {
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
    let session = HTTPSessionSpy()
    let task = HTTPSessionTaskSpy()

    session.stub(url: url, task: task)
    let sut = URLSessionHTTPClient(session: session)
    sut.get(from: url) { _ in }

    XCTAssertEqual(task.resumeCallCount, 1)
  }

  func test_getFromURL_failWithError() {
    let url = URL(string: "https://any-url.com")!

    let expectedRrror = NSError(domain: "network error", code: 1)
    let session = HTTPSessionSpy()
    let task = HTTPSessionTaskSpy()

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

  private class HTTPSessionSpy: HTTPSession {
    private var stubs = [URL : Stub] ()

    private struct Stub {
      let task: HTTPSessionTask
      let error: NSError?
    }

    func stub(url: URL, task: HTTPSessionTask = FakeHTTPSessionTask(), error: NSError? = nil) {
      stubs[url] = Stub(task: task, error: error)
    }

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
      guard let stub = stubs[url] else {
        fatalError("Can't find stub for \(url)")
      }
      completionHandler(nil, nil, stub.error)
      return stub.task
    }
  }

  private class FakeHTTPSessionTask: HTTPSessionTask {
    func resume() { }
  }

  private class HTTPSessionTaskSpy: HTTPSessionTask {
    var resumeCallCount = 0

    func resume() {
      resumeCallCount += 1
    }
  }

}
