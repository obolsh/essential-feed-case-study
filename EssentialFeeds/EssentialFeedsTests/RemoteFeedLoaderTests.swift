//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 09.08.2023.
//

import XCTest

class RemoteFeedLoader {

    let client: HttpClient

    init(client: HttpClient) {
        self.client = client
    }

    func load() {
        client.get(from: URL(string: "https://fake.com")!)
    }
}

protocol HttpClient {
    func get (from url: URL)
}

class HttpClientSpy : HttpClient {

    var requestURL: URL?

    func get(from url: URL) {
        requestURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_noInvocation() {

        let client = HttpClientSpy()

        let sut = RemoteFeedLoader(client: client)

        XCTAssertNil(client.requestURL)

    }

    func test_load_invoced() {
        let client = HttpClientSpy()

        let sut = RemoteFeedLoader(client: client)
        sut.load()

        XCTAssertNotNil(client.requestURL)
    }

}
