// MARK: - Add ShellOut Dependency
// If using Swift Package Manager for your Dangerfile dependencies, add ShellOut:
// // package: https://github.com/JohnSundell/ShellOut.git == 2.3.0
import Danger
import Foundation
import ShellOut // <-- Add import

public struct RemoteDangerfile {

    private let danger: DangerDSL

    public init(dangerDSL: DangerDSL = Danger()) {
        danger = dangerDSL
    }

    public func checkForCopyrightHeaders() {

        danger.warn("Skipped checkForCopyrightHeaders tests.")

    }
}

