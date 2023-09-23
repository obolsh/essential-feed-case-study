//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 30.08.2023.
//

import XCTest
import EssentialFeeds

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
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))

  }

  func test_getFromURL_expectDataWithResponse() {
    let data = anyData()
    let response = anyHTTPURLResponse()

    let result = resultSuccessFor(data: data, response: response, error: nil)

    XCTAssertEqual(data, result?.data)
    XCTAssertEqual(response.statusCode, result?.response.statusCode)
    XCTAssertEqual(response.url, result?.response.url)
  }

  func test_getFromURL_expectEmptyDataWithResponse() {
    let response = anyHTTPURLResponse()
    let result = resultSuccessFor(data: nil, response: response, error: nil)

    let emptyData = Data()
    XCTAssertEqual(result?.data, emptyData)
    XCTAssertEqual(response.statusCode, result?.response.statusCode)
    XCTAssertEqual(response.url, result?.response.url)
  }

  //MARK: - helpers

  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
    let sut = URLSessionHTTPClient()
    trackMemoryLeak(sut, file: file, line: line)
    return sut
  }

  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }

  private func anyData() -> Data {
    return Data(_: "anyData".utf8)
  }

  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
  }

  private func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
  }

  private func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
  }

  private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
    var result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .failure(errorReceived):
      return errorReceived
    default:
      XCTFail("Expected failure, received \(result)", file: file, line: line)
      return nil
    }
  }

  private typealias SuccessResult = (data: Data, response: HTTPURLResponse)

  private func resultSuccessFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> SuccessResult? {
    var result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .success(data, response):
      return SuccessResult(data, response)
    default:
      XCTFail("Expected success, received \(result)", file: file, line: line)
      return nil
    }
  }

  private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
    URLProtocolStub.stub(data: data, response: response, error: error)

    let sut = makeSUT(file: file, line: line)
    let exp = expectation(description: "Wait for response")
    var result: HTTPClientResult!

    sut.get(from: anyURL()) { res in
      result = res
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return result

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
