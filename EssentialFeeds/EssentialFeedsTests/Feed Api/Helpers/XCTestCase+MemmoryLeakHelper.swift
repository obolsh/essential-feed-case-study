//
//  XCTestCase+MemmoryLeakHelper.swift
//  EssentialFeedsTests
//
//  Created by Oleksii Bolshakov on 31.08.2023.
//

import XCTest

extension XCTestCase {
  func trackMemoryLeak(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
      addTeardownBlock { [weak instance] in
          XCTAssertNil(instance, "Instance should be dealocated. This is memory leak", file: file, line: line)
      }
  }
}
