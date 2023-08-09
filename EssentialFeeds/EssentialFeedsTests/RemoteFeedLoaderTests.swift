//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 09.08.2023.
//

import XCTest

class RemoteFeedLoader {

    let client: HttpClient
    let url: URL

    init(client: HttpClient, url: URL) {
        self.client = client
        self.url = url
    }

    func load() {
        client.get(from: url)
    }
}

protocol HttpClient {
    func get (from url: URL)
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_noInvocation() {
        let (client, _) = makeSUT()

        XCTAssertNil(client.requestURL)

    }

    func test_load_invoced() {
        let url = URL(string: "https://fake.com")!
        let (client, sut) = makeSUT(url: url)
        sut.load()

        XCTAssertEqual(client.requestURL, url)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://fake.com")!) -> (client: HttpClientSpy, sut: RemoteFeedLoader) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (client, sut)
    }

    private class HttpClientSpy : HttpClient {

        var requestURL: URL?

        func get(from url: URL) {
            requestURL = url
        }
    }

}
