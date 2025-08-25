import ArgumentParser
import Foundation

func wrapTE(
    options: TEOptions,
    input: String, arguments: [String]
) async throws {
    let projectBuildPath =
        options.teBuildPath.hasSuffix("/")
        ? options.teBuildPath
        // Add the trailing slash if it's not already there.
        : options.teBuildPath + "/"
    let executablePath = projectBuildPath + "te"
    let clangPluginPath = projectBuildPath + "libte.so"
    guard let inputData = input.data(using: .utf8) else {
        throw ValidationError("Input cannot be serialized as UTF-8.")
    }
    let processToRun = Process()

    // Handle the standard input for TypeExtractor.
    let inputPipe = Pipe()
    try inputPipe.fileHandleForWriting.write(contentsOf: inputData)
    inputPipe.fileHandleForWriting.closeFile()
    processToRun.standardInput = inputPipe.fileHandleForReading

    // Let the standard output and standard error pass through transparently.
    processToRun.standardOutput = FileHandle.standardOutput
    processToRun.standardError = FileHandle.standardError

    switch options.clangMode {
    case .driver:
        processToRun.executableURL = URL(fileURLWithPath: try await options.clangExecutable.path)
        processToRun.arguments =
            [
                "-fplugin=\(clangPluginPath)",
                "-Xclang", "-plugin", "-Xclang", "type-extractor",
            ] + arguments + [
                "-",  // Input will be piped in.
                "-o", "/dev/null",  // Output is discarded.
            ]
        break
    case .frontend:
        let getResourceDirProcess = Process()
        getResourceDirProcess.executableURL =
            URL(fileURLWithPath: try await options.clangExecutable.path)
        getResourceDirProcess.arguments = ["-print-resource-dir"]
        let resourceDirPipe = Pipe()
        getResourceDirProcess.standardOutput = resourceDirPipe.fileHandleForWriting
        try await getResourceDirProcess.run()
        resourceDirPipe.fileHandleForWriting.closeFile()
        let resourceDirData = resourceDirPipe.fileHandleForReading.readDataToEndOfFile()
        guard
            let resourceDir = String(data: resourceDirData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            throw ValidationError("Failed to get resource directory from Clang.")
        }
        processToRun.executableURL = URL(fileURLWithPath: executablePath)
        processToRun.arguments =
            [
                "-resource-dir", resourceDir,
            ] + arguments
        break
    }
    try await processToRun.run()
}
