import Foundation
import SWBCore
import SWBUtil

struct EmptyCoreDelegate: CoreDelegate, Sendable {
    var hasErrors: Bool = false
    var diagnosticsEngine: DiagnosticProducingDelegateProtocolPrivate<DiagnosticsEngine> =
        DiagnosticProducingDelegateProtocolPrivate<DiagnosticsEngine>(
            DiagnosticsEngine())
}

func getCore(xcodeDeveloperPath: Path? = nil) async throws -> Core? {
    let xcodeDeveloperPath =
        if let xcodeDeveloperPath {
            xcodeDeveloperPath
        } else {
            try await Xcode.getActiveDeveloperDirectoryPath()
        }
    return await Core.getInitializedCore(
        EmptyCoreDelegate(),
        pluginManager: PluginManager(skipLoadingPluginIdentifiers: []),
        developerPath: .xcode(xcodeDeveloperPath),
        buildServiceModTime: Date(),
        connectionMode: .inProcess
    )
}

func getSDKRegistry(xcodeDeveloperPathString: String? = nil) async throws -> SDKRegistry? {
    let core = try await getCore(xcodeDeveloperPath: xcodeDeveloperPathString.flatMap({ Path($0) }))
    return core?.sdkRegistry  // This line crashes the language server for some reason
}
