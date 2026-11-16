import DynamicPropertyTesting
import SwiftUI
import Testing

@Suite
@MainActor
struct DynamicPropertyTestingTests {

  @Test
  func readsAndWritesTheOriginalType() async throws {
    try await withDynamicProperty(CounterState()) { state in
      let _: CounterState = state
      #expect(state.count == 0)

      state.count += 1
      #expect(state.count == 1)

      state.increment()
      #expect(state.count == 2)

      state.unrelated = "Changed"
      #expect(state.count == 2)
      #expect(state.unrelated == "Changed")
    }
  }

  @Test
  func nestedPropertiesHaveIndependentStorage() async throws {
    struct Pair: DynamicProperty {
      var first = CounterState()
      var second = CounterState()
    }

    try await withDynamicProperty(Pair()) { pair in
      pair.first.increment()
      #expect(pair.first.count == 1)
      #expect(pair.second.count == 0)

      pair.second.count = 10
      #expect(pair.first.count == 1)
      #expect(pair.second.count == 10)
    }
  }

  @Test
  func freshScopesDoNotShareState() async throws {
    try await withDynamicProperty(CounterState()) { outer in
      outer.count = 5

      try await withDynamicProperty(CounterState()) { inner in
        #expect(inner.count == 0)
        inner.count = 10
        #expect(outer.count == 5)
      }

      #expect(outer.count == 5)
    }

    try await withDynamicProperty(CounterState()) { fresh in
      #expect(fresh.count == 0)
    }
  }

  @Test
  func installsEnvironmentAndRunsUpdate() async throws {
    struct Property: DynamicProperty {
      @Environment(\.isEnabled) var isEnabled
      var updateCount = 0

      mutating func update() {
        updateCount += 1
      }
    }

    try await withDynamicProperty(Property()) { property in
      #expect(property.isEnabled)
      #expect(property.updateCount > 0)
    }
  }

  @Test
  func ownsStateObjectsAcrossSuspensionAndReleasesThemAfterward() async throws {
    weak var object: Model?

    let result = try await withDynamicProperty(ObjectState()) { state in
      object = state.model
      state.model.count = 3

      await Task.yield()

      #expect(object === state.model)
      #expect(state.model.count == 3)
      return state.model.count
    }

    #expect(result == 3)
    #expect(object == nil)
  }

  @Test
  func throwingClosesTheScopeAndPropagatesTheError() async throws {
    struct ExpectedError: Error {}
    weak var object: Model?

    await #expect(throws: ExpectedError.self) {
      try await withDynamicProperty(ObjectState()) { state in
        object = state.model
        throw ExpectedError()
      }
    }

    #expect(object == nil)
  }

}

private struct CounterState: DynamicProperty {

  @State var count = 0
  @State var unrelated = ""

  func increment() {
    count += 1
  }

}

@MainActor
private final class Model: ObservableObject {

  var count = 0

}

@MainActor
private struct ObjectState: DynamicProperty {

  @StateObject var model = Model()

}
