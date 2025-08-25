import ArgumentParser

protocol PlatformCommand: AsyncParsableCommand {
    var teOptions: TEOptions { get }
    var remainingArguments: [String] { get set }
    func prepare() async throws

    var input: String { get async throws }
    var baseArguments: [String] { get async throws }
}

extension PlatformCommand {
    mutating func run() async throws {
        try await prepare()
        try await wrapTE(
            options: teOptions,
            input: input,
            arguments: baseArguments + remainingArguments
        )
    }
}
