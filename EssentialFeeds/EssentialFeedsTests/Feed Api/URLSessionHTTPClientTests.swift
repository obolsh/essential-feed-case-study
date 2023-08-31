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

  struct UnexpectedResponseValues: Error {}

  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { _, _, error in
      if let error = error {
        completion(.failure(error))
      } else {
        completion(.failure(UnexpectedResponseValues()))
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
    let expectedError = anyNSError()
    guard let error = resultErrorFor(data: nil, response: nil, error: expectedError) as? NSError else {
      XCTFail("Error expected \(expectedError)")
      return
    }

    XCTAssertEqual(error.domain, expectedError.domain)
    XCTAssertEqual(error.code, expectedError.code)
  }

  func test_getFromURL_failOnAllNonValidDataCases() {
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: nil))
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

  private func anyData() -> Data {
    return Data(bytes: "anyData".utf8)
  }

  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
  }

  private func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 1, httpVersion: nil, headerFields: nil)!
  }

  private func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
  }

  private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
    URLProtocolStub.stub(data: data, response: response, error: error)

    let sut = makeSUT(file: file, line: line)
    let exp = expectation(description: "Wait for response")
    var receivedError: Error?


    sut.get(from: anyURL()) { result in
      switch result {
      case let .failure(errorReceived):
        receivedError = errorReceived
      default:
        XCTFail("Error failure", file: file, line: line)
      }
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return receivedError
  }

  private class URLProtocolStub: URLProtocol {
    private static var stubs: Stub?
    private static var observer: ((URLRequest) -> Void)?

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
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
