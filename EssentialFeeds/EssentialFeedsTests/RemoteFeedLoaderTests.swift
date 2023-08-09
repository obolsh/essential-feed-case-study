//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 09.08.2023.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HttpClient.shared.get(from: URL(string: "https://fake.com")!)
    }
}

class HttpClient {
    static var shared: HttpClient = HttpClient()

    func get (from url: URL) { }
}

class HttpClientSpy : HttpClient {

    var requestURL: URL?

    override func get(from url: URL) {
        requestURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_noInvocation() {

        let client = HttpClientSpy()
        HttpClient.shared = client

        let sut = RemoteFeedLoader()

        XCTAssertNil(client.requestURL)

    }

    func test_load_invoced() {
        let client = HttpClientSpy()
        HttpClient.shared = client

        let sut = RemoteFeedLoader()
        sut.load()

        XCTAssertNotNil(client.requestURL)
    }

}
