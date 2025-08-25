import ArgumentParser
import Foundation

#if os(macOS)
    import DarwinSDK
#endif

enum ClangMode: String, ExpressibleByArgument, CaseIterable {
    // Use a Clang plugin and hook into the Clang driver.
    case driver

    // Use a standalone executable and hook into the C11 frontend.
    case frontend

    static let allValueDescriptions: [String: String] = [
        "driver": "Hook into the Clang driver through a plugin.",
        "frontend": "Hook into the C11 frontend through a standalone executable.",
    ]
}

/// A path to a Clang executable, which can be specified as a string argument.
struct ClangExecutable: ExpressibleByArgument {
    /// The original argument string passed to the initializer.
    private var originalArgument: String

    /// The string representation of this option (shown in help text for the default value).
    var defaultValueDescription: String {
        return originalArgument
    }

    /// The derived path to the Clang executable based on the original argument.
    private var derivedPath: String

    /// A placeholder "derived path" indicating that the Xcode path should be used.
    /// - Note: This is used because the Xcode Clang path can only be resolved asynchronously.
    private let XcodePathSentinel: String = "XCODE_CLANG_PATH"

    /// The path to the Clang executable to use.
    var path: String {
        get async throws {
            let fullPath =
                derivedPath == XcodePathSentinel
                ? try await xcodeDeveloperDir
                    + "/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
                : derivedPath
            guard FileManager.default.fileExists(atPath: fullPath) else {
                throw ValidationError("Clang executable not found at path: \(fullPath)")
            }
            return fullPath
        }
    }

    /// An enumeration of platforms to categorize the available values for this option.
    private enum Platform {
        /// Value(s) to always show at the beginning of the list.
        case all_Head

        /// macOS-specific values.
        case macOS

        /// Value(s) to always show at the end of the list.
        case all_Tail
    }

    /// A dictionary mapping of platforms to their respective values and descriptions.
    private static let valuesByPlatform: [Platform: [String: String]] = [
        .all_Head: [
            "system": "Use the system Clang at /usr/bin/clang."
        ],
        .macOS: [
            "homebrew": "Use the Homebrew-installed Clang at /opt/homebrew/opt/llvm/bin/clang.",
            "xcode": "Use the Clang from the active Xcode developer directory.",
        ],
        .all_Tail: [
            "<path>": "Use the Clang executable at the specified path."
        ],
    ]

    static var allValueStrings: [String] {
        var values = self.valuesByPlatform[.all_Head]?.keys.map { $0 } ?? []
        #if os(macOS)
            values += self.valuesByPlatform[.macOS]?.keys.map { $0 } ?? []
        #endif
        values += self.valuesByPlatform[.all_Tail]?.keys.map { $0 } ?? []
        return values
    }

    static var allValueDescriptions: [String: String] {
        var descriptions = self.valuesByPlatform[.all_Head] ?? [:]
        #if os(macOS)
            descriptions.merge(self.valuesByPlatform[.macOS] ?? [:]) { $1 }
        #endif
        descriptions.merge(self.valuesByPlatform[.all_Tail] ?? [:]) { $1 }
        return descriptions
    }

    /// Initializes a `ClangExecutable` from a command-line argument.
    init?(argument: String) {
        guard !argument.isEmpty else { return nil }
        self.originalArgument = argument
        switch argument {
        case "system":
            self.derivedPath = "/usr/bin/clang"
        #if os(macOS)
            case "homebrew":
                self.derivedPath = "/opt/homebrew/opt/llvm/bin/clang"
            case "xcode":
                self.derivedPath = XcodePathSentinel  // This must be resolved by the command at runtime.
        #endif
        default:
            self.derivedPath = argument
        }
    }
}

// Arguments for how to run the wrapped TypeExtractor tool.
struct TEOptions: ParsableArguments {
    /// The Clang executable to use.
    @Option(
        name: .customLong("clang"),
        help:
            "The (path to the) Clang executable to use. In driver mode, this is the Clang driver. In frontend mode, this is only used to get the resource directory.",
    )
    var clangExecutable: ClangExecutable

    /// The mode in which to run the tool.
    @Option(name: .long, help: "The mode in which to run the tool.")
    var clangMode: ClangMode

    @Option(
        name: .customLong("te-build-path"),
        help: "The build path for the TypeExtractor tool."
    )
    var teBuildPath: String
}
