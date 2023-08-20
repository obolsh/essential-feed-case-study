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
                client.complete(withStatusCode: code, at: index)
            })
        }
    }

    func test_load_deliverErrorOn200WithInvalidJson() {

        let (client, sut) = makeSUT()

        expect(sut, completeWithResult: .failure(.invalidData), when: {
            let invalidJson = Data(bytes: "Invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson, at: 0)
        })
    }

    func test_load_deliverNoDataWhen200WithEmptyJson() {
        let (client, sut) = makeSUT()

        expect(sut, completeWithResult: .success([]), when: {
            let emptyItemsJson = Data(bytes: "{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyItemsJson, at: 0)
        })
    }

    // MARK: - Helpers

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

    private class HttpClientSpy : HttpClient {

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

        func complete (withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
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
