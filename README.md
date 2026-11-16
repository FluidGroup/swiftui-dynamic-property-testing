# Dynamic Property Testing

Test a `DynamicProperty` struct with real SwiftUI state storage and ordinary property access.

## Motivation

A `DynamicProperty` struct can group state and behavior while keeping independently changing values in separate `@State` properties. SwiftUI tracks which state properties a view reads, so changing an unread state property need not reevaluate the view's `body`.

A plain struct stored in a single `@State` shares one state dependency: reading `model.count` can make a change to `model.query` reevaluate the view's `body` too. Testing should not require changing that dependency structure.

Simply constructing a `DynamicProperty` in a test does not connect its `@State` properties to SwiftUI's managed storage. This library makes that connection so tests can use ordinary property access while preserving the production state design.

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
