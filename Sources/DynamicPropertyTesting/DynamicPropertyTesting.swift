import SwiftUI

/// Runs a test with a dynamic property installed in SwiftUI's runtime.
///
/// The closure receives the property's concrete type. Its nested state storage
/// stays alive across suspension points until the closure returns or throws.
/// Ordinary stored fields and environment-derived values are snapshots of the
/// initial update. This function does not wait for subsequent view updates.
@MainActor
public func withDynamicProperty<Property: DynamicProperty, Result>(
  _ property: Property,
  _ body: @MainActor (Property) async throws -> Result
) async throws -> Result {
  var installed: Property?
  let renderer = ImageRenderer(
    content: PropertyProbe(property: property) { property in
      installed = property
    }
  )
  renderer.render { _, _ in }

  guard let installed else {
    throw DynamicPropertyTestingError.installationFailed
  }
  defer { withExtendedLifetime(renderer) {} }

  return try await body(installed)
}

/// A failure to install a dynamic property in the rendering graph.
public enum DynamicPropertyTestingError: Error {

  case installationFailed

}

private struct PropertyProbe<Property: DynamicProperty>: View {

  var property: Property
  private let inspect: (Property) -> Void

  init(property: Property, inspect: @escaping (Property) -> Void) {
    self.property = property
    self.inspect = inspect
  }

  var body: some View {
    // This only captures the installed value; it must not mutate SwiftUI state.
    inspect(property)
    return Color.clear.frame(width: 1, height: 1)
  }

}
