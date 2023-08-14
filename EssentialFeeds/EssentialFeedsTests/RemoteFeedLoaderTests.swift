//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 09.08.2023.
//

import XCTest
import EssentialFeeds

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_noInvocation() {
        let (client, _) = makeSUT()

        XCTAssertTrue(client.messages.isEmpty)

    }

    func test_load_invoced() {
        let url = URL(string: "https://fake.com")!
        let (client, sut) = makeSUT(url: url)
        sut.load()

        XCTAssertEqual(client.messages.map{ url, _ in url}, [url])
    }

    func test_loadTwice_invocedTwice() {
        let url = URL(string: "https://fake.com")!
        let (client, sut) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.messages.map{ url, _ in url}, [url, url])
    }

    func test_load_deliverErrorOnClientError() {
        let (client, sut) = makeSUT()

        var clientErrors = [RemoteFeedLoader.Error] ()
        sut.load { clientErrors.append($0)}

        client.complete(with: NSError(domain: "Test", code: 1))

        XCTAssertEqual(clientErrors, [.connectivity])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://fake.com")!) -> (client: HttpClientSpy, sut: RemoteFeedLoader) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (client, sut)
    }

    private class HttpClientSpy : HttpClient {

        var messages = [(url: URL, completion: (Error) -> Void)]()

        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error)
        }
    }

}
