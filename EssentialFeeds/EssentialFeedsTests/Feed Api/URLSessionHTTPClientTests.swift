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


  func test_getFromURL_failWithError() {
    URLProtocolStub.interceptRequests()

    let url = URL(string: "https://any-url.com")!
    let expectedError = NSError(domain: "network error", code: 1)

    URLProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)

    let sut = URLSessionHTTPClient()

    let exp = expectation(description: "Wait for error")
    sut.get(from: url) { result in
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

    URLProtocolStub.cancelRequestInterception()
  }

  private class URLProtocolStub: URLProtocol {
    private static var stubs = [URL : Stub] ()

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: NSError?
    }

    static func stub(url: URL, data: Data?, response: URLResponse?, error: NSError?) {
      stubs[url] = Stub(data: data, response: response, error: error)
    }

    static func interceptRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func cancelRequestInterception() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stubs = [:]
    }

    override class func canInit(with request: URLRequest) -> Bool {
      guard let url = request.url else { return false }

      return URLProtocolStub.stubs[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }

      if let data = stub.data {
        client?.urlProtocol(self, didLoad: data)
      }
      if let response = stub.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      if let error = stub.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }
}
