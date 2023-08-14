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
        sut.load { _ in }

        XCTAssertEqual(client.capturedUrls, [url])
    }

    func test_loadTwice_invocedTwice() {
        let url = URL(string: "https://fake.com")!
        let (client, sut) = makeSUT(url: url)

        sut.load{ _ in }
        sut.load{ _ in }

        XCTAssertEqual(client.capturedUrls, [url, url])
    }

    func test_load_deliverErrorOnClientError() {
        let (client, sut) = makeSUT()

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0)}

        let clientError =  NSError(domain: "Test", code: 1)
        client.complete(with: clientError)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_deliverErrorOn400HTTPError() {
        let (client, sut) = makeSUT()

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0)}

        client.complete(withStatusCode: 404)

        XCTAssertEqual(capturedErrors, [.invalidData])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://fake.com")!) -> (client: HttpClientSpy, sut: RemoteFeedLoader) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (client, sut)
    }

    private class HttpClientSpy : HttpClient {

        var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        var capturedUrls: [URL] {
            return messages.map{ $0.url }
        }

        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }

        func complete (withStatusCode code: Int, at index: Int = 0) {
            let urlResponse = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )
            messages[index].completion(nil, urlResponse)
        }

    }

}
