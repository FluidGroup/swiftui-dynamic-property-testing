import SwiftUI
import Testing

@Suite
@MainActor
struct DependencyTrackingTests {

  @Test
  func unrelatedStateDoesNotInvalidateTheConsumer() throws {
    var installed: SeparateState?
    var evaluations = 0
    let renderer = ImageRenderer(
      content: SeparateConsumer { state in
        installed = state
        evaluations += 1
      }
    )
    renderer.render { _, _ in }
    let state = try #require(installed)
    let initialEvaluations = evaluations
    #expect(initialEvaluations > 0)

    state.unrelated += 1
    renderer.render { _, _ in }
    #expect(evaluations == initialEvaluations)

    state.count += 1
    renderer.render { _, _ in }
    #expect(evaluations > initialEvaluations)
  }

  @Test
  func aggregateStateInvalidatesTheConsumerWhenAnUnrelatedFieldChanges() throws {
    var installed: AggregateConsumer?
    var evaluations = 0
    let renderer = ImageRenderer(
      content: AggregateConsumer { view in
        installed = view
        evaluations += 1
      }
    )
    renderer.render { _, _ in }
    let view = try #require(installed)
    let initialEvaluations = evaluations

    view.model.unrelated += 1
    renderer.render { _, _ in }
    #expect(evaluations > initialEvaluations)
  }

}

private struct SeparateState: DynamicProperty {

  @State var count = 0
  @State var unrelated = 0

}

private struct SeparateConsumer: View {

  var state = SeparateState()
  let inspect: (SeparateState) -> Void

  var body: some View {
    inspect(state)
    return Color.clear
      .frame(width: CGFloat(state.count + 1), height: 1)
  }

}

private struct AggregateConsumer: View {

  struct Model {
    var count = 0
    var unrelated = 0
  }

  @State var model = Model()
  let inspect: (AggregateConsumer) -> Void

  var body: some View {
    inspect(self)
    return Color.clear
      .frame(width: CGFloat(model.count + 1), height: 1)
  }

}
