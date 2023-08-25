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

        expect(sut, completeWithResult: .failure(.connectivity), when: {
            let clientError =  NSError(domain: "Test", code: 1)
            client.complete(with: clientError)
        })
    }

    func test_load_deliverErrorOn4Not200Response() {
        let (client, sut) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach{ index, code in

            expect(sut, completeWithResult: .failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_load_deliverErrorOn200WithInvalidJson() {

        let (client, sut) = makeSUT()

        expect(sut, completeWithResult: .failure(.invalidData), when: {
            let invalidJson = Data(bytes: "Invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }

    func test_load_deliverNoDataWhen200WithEmptyJson() {
        let (client, sut) = makeSUT()

        expect(sut, completeWithResult: .success([]), when: {
            let emptyItemsJson = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyItemsJson)
        })
    }

    func test_load_deliverItemsWhen200WithItemsJson() {
        let (client, sut) = makeSUT()

        let item1 = makeItem(id: UUID(),
                                          imageURL: URL(string: "https://a-valid-url.com")!)


        let item2 = makeItem(id: UUID(),
                                          description: "a desctription",
                                          location: "a location",
                                          imageURL: URL(string: "https://another-url.com")!)

        let items = [item1.model, item2.model]
        let jsonItems = [item1.json, item2.json]

        expect(sut, completeWithResult: .success(items), when: {
            client.complete(withStatusCode: 200, data: makeItemsJSON(jsonItems))
        })
    }

    // MARK: - Helpers

    private func makeItem(id: UUID,
                          description: String? = nil,
                          location: String? = nil,
                          imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id,
                             description: description,
                             location: location,
                             imageURL: imageURL)

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let jsonItems = ["items": items]
        return try! JSONSerialization.data(withJSONObject: jsonItems)
    }

    private func expect (_ sut: RemoteFeedLoader, completeWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0)}

        action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private func makeSUT(url: URL = URL(string: "https://fake.com")!) -> (client: HttpClientSpy, sut: RemoteFeedLoader) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (client, sut)
    }

    private class HttpClientSpy : HTTPClient {

        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var capturedUrls: [URL] {
            return messages.map{ $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete (withStatusCode code: Int, data: Data, at index: Int = 0) {
            let urlResponse = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, urlResponse))
        }

    }

}
