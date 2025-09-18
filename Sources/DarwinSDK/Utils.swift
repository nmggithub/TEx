import Dispatch
import SWBCore
import SWBUtil

public func getInfoForSDK(
    withName name: String,
    variant: String,
    andArchitecture architecture: String,
    usingXcodeDeveloperPath xcodeDeveloperPath: String? = nil
) async -> (llvmTargetTriple: String, llvmSysroot: String)? {
    guard
        let sdkRegistry = try? await getSDKRegistry(xcodeDeveloperPathString: xcodeDeveloperPath),
        let targetSDK = sdkRegistry.allSDKs.first(where: { $0.canonicalName == name }),
        let targetVariant = targetSDK.variant(for: variant),
        targetVariant.archs?.contains(architecture) == true,
        let deploymentTarget = targetVariant.defaultDeploymentTarget,
        let llvmTargetTripleVendor = targetVariant.llvmTargetTripleVendor,
        let llvmTargetTripleSys = targetVariant.llvmTargetTripleSys,
        let llvmTargetTripleEnvironment = targetVariant.llvmTargetTripleEnvironment
    else { return nil }
    let llvmTargetTriple = [
        architecture,  // e.g., "x86_64"
        llvmTargetTripleVendor,  // e.g., "apple"
        "\(llvmTargetTripleSys)\(deploymentTarget.canonicalDeploymentTargetForm.description)",  // e.g., "macosx10.15"
        llvmTargetTripleEnvironment,  // e.g., "simulator"
    ]
    .filter({ !$0.isEmpty })
    .joined(separator: "-")
    let llvmSysroot = targetSDK.path.str
    return (llvmTargetTriple, llvmSysroot)
}

public var xcodeDeveloperDir: String {
    get async throws {
        try await Xcode.getActiveDeveloperDirectoryPath().str
    }
}
