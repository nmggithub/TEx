import Foundation
import SWBCore
import SWBUtil

struct EmptyCoreDelegate: CoreDelegate, Sendable {
    var hasErrors: Bool = false
    var diagnosticsEngine: DiagnosticProducingDelegateProtocolPrivate<DiagnosticsEngine> =
        DiagnosticProducingDelegateProtocolPrivate<DiagnosticsEngine>(
            DiagnosticsEngine())
}

func getCore() async throws -> Core? {
    await Core.getInitializedCore(
        EmptyCoreDelegate(),
        pluginManager: PluginManager(skipLoadingPluginIdentifiers: []),
        developerPath: .xcode(try await Xcode.getActiveDeveloperDirectoryPath()),
        buildServiceModTime: Date(),
        connectionMode: .inProcess
    )
}

func getSDKRegistry() async throws -> SDKRegistry? {
    let core = try await getCore()
    return core?.sdkRegistry  // This line crashes the language server for some reason
}
