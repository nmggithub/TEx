import ArgumentParser

@main
@available(macOS 10.15, *)
struct TEx: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "TEx",
        abstract: "A wrapper for the Clang-powered TypeExtractor header parser.",
        subcommands: [
            Darwin.self
        ]
    )
}
