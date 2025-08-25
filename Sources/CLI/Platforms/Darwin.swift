import ArgumentParser
import Foundation

#if os(macOS)
    import DarwinSDK
#endif

struct SDKOptions: ParsableArguments {
    /// The name of the SDK to use.
    @Option(name: .shortAndLong, help: "The name of the SDK to use.")
    var sdkName: String

    /// The variant of the SDK to use.
    @Option(name: .shortAndLong, help: "The variant of the SDK to use.")
    var variant: String

    /// The architecture of the headers to parse.
    @Option(name: .shortAndLong, help: "The architecture of the headers to parse.")
    var architecture: String = {
        #if arch(x86_64)
            return "x86_64"
        #elseif arch(arm64)
            return "arm64"
        #else
            fatalError("Unsupported architecture")
        #endif
    }()
}

struct Darwin: PlatformCommand {
    static let configuration = CommandConfiguration(
        commandName: "Darwin",
        abstract: "Parse Darwin headers.",
    )

    @OptionGroup var sdkOptions: SDKOptions

    @Option(name: .customShort("F"), help: "The framework(s) to parse headers for.")
    var frameworks: [String] = []

    @Option(name: .customShort("H"), help: "The header(s) to parse.")
    var headers: [String] = []

    @OptionGroup var teOptions: TEOptions

    @Argument(parsing: .remaining, help: "Additional arguments to pass to Clang.")
    var remainingArguments: [String] = []

    var input: String {
        let frameworkIncludes =
            frameworks.isEmpty
            ? ""
            : frameworks.map({ "#include <\($0)/\($0).h>" }).joined(separator: "\n") + "\n"
        let headerIncludes =
            headers.isEmpty
            ? ""
            : headers.map({ "#include <\($0)>" }).joined(separator: "\n") + "\n"
        return frameworkIncludes + headerIncludes
    }

    var baseArguments: [String] {
        get async throws {
            guard
                let (llvmTargetTriple, llvmSysroot) = await getInfoForSDK(
                    withName: sdkOptions.sdkName,
                    variant: sdkOptions.variant,
                    andArchitecture: sdkOptions.architecture
                )
            else {
                throw ValidationError(
                    "Could not determine info for SDK \(sdkOptions.sdkName), variant \(sdkOptions.variant), architecture \(sdkOptions.architecture)."
                )
            }
            // These existing arguments are ones I've determined, heuristically,
            //  to be the minimum required to parse Darwin headers.
            return [
                "-fgnuc-version=4.2.1",
                "-x", "objective-c++-header",
                "-target", llvmTargetTriple,
                "-isysroot", llvmSysroot,
            ]
        }
    }

    func prepare() async throws {
        #if !os(macOS)
            throw ValidationError("Darwin header parsing is only supported on macOS.")
        #endif
    }
}
