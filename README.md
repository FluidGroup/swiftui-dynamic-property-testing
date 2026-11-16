# Dynamic Property Testing

Test a `DynamicProperty` struct with real SwiftUI state storage and ordinary property access.

## Motivation

A plain struct stored in a single `@State` is easy to test, but the whole value shares one state dependency. Reading `model.count` makes the view depend on that state slot, so changing an unrelated field can invalidate the view too. Mutating a large aggregate can also add copy costs, depending on its contents and compiler optimizations.

Instead, a `DynamicProperty` struct can hold small, independent `@State` values. SwiftUI tracks the state properties the view actually reads. Testing this design should not require moving the entire model into one large `@State` just to make it testable.

## Usage

Add the `DynamicPropertyTesting` product to your test target, then use it with Swift Testing or XCTest:

```swift
import DynamicPropertyTesting
import SwiftUI
import Testing

struct CounterState: DynamicProperty {

  @State var count = 0
  @State var query = ""

  func increment() {
    count += 1
  }

}

@Test @MainActor
func increment() async throws {
  try await withDynamicProperty(CounterState()) { state in
    #expect(state.count == 0)

    state.count += 1
    #expect(state.count == 1)

    state.increment()
    #expect(state.count == 2)
  }
}
```

The closure receives the original concrete type after SwiftUI installs it. Its nested state storage remains alive across `await` until the closure returns or throws. Keep the installed value inside this scope.

The helper uses an offscreen `ImageRenderer` and public SwiftUI APIs. It needs no window, host app, third-party dependency, or XCTest dependency in the library. It supports iOS/iPadOS 16+, macOS 13+, Mac Catalyst 16+, tvOS 16+, watchOS 9+, and visionOS 1+, with Swift 6.

The closure receives the initial installed copy. Ordinary stored fields and environment-derived values do not automatically refresh in that copy. The helper does not wait for later view updates or simulate view appearance, tasks, or scene lifecycle.

Run the macOS tests with `swift test`. CI also runs iOS Simulator tests and builds for the other Apple platforms.
