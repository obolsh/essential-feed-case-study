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

  init(session: URLSession = .shared) {
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

  override func setUp() {
    super.setUp()
    URLProtocolStub.interceptRequests()
  }

  override func tearDown() {
    super.tearDown()
    URLProtocolStub.cancelRequestInterception()
  }

  func test_getFromURL_expectURLMatch() {
    let url = anyURL()
    let exp = expectation(description: "Wait for url")

    URLProtocolStub.observeURLRequest { request in
      XCTAssertEqual(request.url, url)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }
    makeSUT().get(from: url) { _ in }

    wait(for: [exp], timeout: 1.0)
  }


  func test_getFromURL_failWithError() {
    let expectedError = NSError(domain: "network error", code: 1)

    URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

    let exp = expectation(description: "Wait for error")
    makeSUT().get(from: anyURL()) { result in
      switch result {
      case let .failure(error as NSError):
        XCTAssertEqual(error.domain, expectedError.domain)
        XCTAssertEqual(error.code, expectedError.code)
      default:
        XCTFail("Error expected")
      }
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
  }

  //MARK: - helpers

  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackMemoryLeak(sut, file: file, line: line)
    return sut
  }

  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }

  private class URLProtocolStub: URLProtocol {
    private static var stubs: Stub?
    private static var observer: ((URLRequest) -> Void)?

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: NSError?
    }

    static func stub(data: Data?, response: URLResponse?, error: NSError?) {
      stubs = Stub(data: data, response: response, error: error)
    }

    static func observeURLRequest(completion: @escaping (URLRequest) -> Void) {
      observer = completion
    }

    static func interceptRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func cancelRequestInterception() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stubs = nil
      observer = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
      observer?(request)
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      if let data = URLProtocolStub.stubs?.data {
        client?.urlProtocol(self, didLoad: data)
      }
      if let response = URLProtocolStub.stubs?.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      if let error = URLProtocolStub.stubs?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }
}
