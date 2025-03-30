// MARK: - Add ShellOut Dependency
// If using Swift Package Manager for your Dangerfile dependencies, add ShellOut:
// // package: https://github.com/JohnSundell/ShellOut.git == 2.3.0
import Danger
import Foundation
import ShellOut // <-- Add import

public struct DangerSwiftRemoteDangerfile {

    private let danger: DangerDSL

    public init(dangerDSL: DangerDSL = Danger()) {
        danger = dangerDSL
    }

    public func checkForCopyrightHeaders() {

        danger.warn("Skipped checkForCopyrightHeaders tests.")

    }
}

/*
// MARK: - Plugin Definition

/// A Danger plugin that enables importing and executing remote Dangerfile.swift files
/// by running them in a separate `danger-swift runner` subprocess.
///
/// **WARNING:**
/// - Executing arbitrary remote code has significant security implications. Ensure you **fully trust** the source URL.
/// - The remote Dangerfile runs in a **separate context**. Its results (fails, warnings, messages)
///   are printed to the console but **do not** affect the status (success/failure) of the main Danger run.
/// - Requires the `ShellOut` dependency.
public final class RemoteDangerfilePlugin {

    public static let id = "RemoteDangerfilePlugin"
    public var dsl: DangerDSL! // Injected by Danger Swift

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches a remote Dangerfile, saves it temporarily, and executes it using `danger-swift runner` in a subprocess.
    /// This function blocks until the subprocess completes.
    ///
    /// - Parameter url: The URL of the remote Dangerfile.swift.
    /// - Throws: An error if fetching, file creation, or subprocess execution fails. Note that errors *within* the
    ///           executed remote Dangerfile itself will be printed by the subprocess but not thrown here.
    public func importAndExecuteRemoteDangerfile(from url: URL) throws {
        guard let dsl = self.dsl else {
             throw NSError(domain: RemoteDangerfilePlugin.id, code: -11, userInfo: [NSLocalizedDescriptionKey: "DangerDSL context not available."])
        }

        print("Attempting to import remote Dangerfile from: \(url.absoluteString)")

//        let semaphore = DispatchSemaphore(value: 0)
        let operationResult = fetchRemoteDangerfileContent(filePath: url.absoluteString)

//        fetchRemoteDangerfileContent(url: url) { result in
//            operationResult = result
//            semaphore.signal()
//        }

//        _ = semaphore.wait(timeout: .distantFuture) // Wait for download

        switch operationResult {
        case .success(let content):
            var tempURL: URL? = nil
            do {
                tempURL = try createTempFile(with: content)
                guard let executionURL = tempURL else {
                    throw NSError(domain: RemoteDangerfilePlugin.id, code: -10, userInfo: [NSLocalizedDescriptionKey: "Temporary file URL was nil after creation."])
                }

                defer { // Cleanup
                    if let urlToRemove = tempURL {
                        do {
                            try FileManager.default.removeItem(at: urlToRemove)
                            print("Removed temporary remote Dangerfile at: \(urlToRemove.path)")
                        } catch {
                            let message = "Warning: Failed to remove temporary remote Dangerfile at \(urlToRemove.path): \(error.localizedDescription)"
                            dsl.warn(message) // Use injected dsl for reporting cleanup issues
                        }
                    }
                }

                // --- Execute using danger-swift runner subprocess ---
                print("Executing remote Dangerfile via subprocess: \(executionURL.path)")
                print("--- Subprocess Output Start ---")
                // Throws ShellOutError if command fails (e.g., danger-swift not found, non-zero exit code)
                // Note: A non-zero exit from the *remote* Dangerfile's logic (e.g., dsl.fail) will cause shellOut to throw.
                let output = try shellOut(
                    to: "danger-swift runner",
                    arguments: ["--dangerfile", executionURL.path]
                )
                print(output) // Print the subprocess stdout
                print("--- Subprocess Output End ---")
                print("Subprocess execution finished for remote Dangerfile from: \(url.absoluteString)")
                // --- End Subprocess Execution ---

            } catch let error as ShellOutError {
                 // Capture and print stderr from the subprocess if available
                 print("Error executing remote Dangerfile subprocess: \(error.message)")
                 print("Subprocess stderr: \(error.output)")
                 // Re-throw the specific error if needed, or a custom one
                 throw NSError(domain: RemoteDangerfilePlugin.id, code: -20, userInfo: [
                     NSLocalizedDescriptionKey: "Remote Dangerfile subprocess failed. Check output above. Error: \(error.message)",
                     "stderr": error.output
                 ])
            } catch {
                // Catch errors from createTempFile or other synchronous operations
                print("Error processing or executing remote Dangerfile: \(error)")
                // Attempt cleanup even if execution threw an error
                if let urlToRemove = tempURL {
                    try? FileManager.default.removeItem(at: urlToRemove)
                }
                throw error // Re-throw original error
            }

        case .failure(let error):
            print("Failed to fetch remote Dangerfile: \(error)")
            throw error

//        case .none:
//            throw NSError(domain: RemoteDangerfilePlugin.id, code: -1, userInfo: [
//                NSLocalizedDescriptionKey: "Remote Dangerfile fetch operation failed to complete."
//            ])
        }
    }

    // MARK: - Private Helpers (Mostly Unchanged)


    func fetchRemoteDangerfileContent(filePath: String) -> Result<String, Error> {
        do {
            // Read the file contents directly as a String
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            return .success(contents)
        } catch {
            print("Error reading file: \(error.localizedDescription)")
            let err = NSError(domain: RemoteDangerfilePlugin.id, code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch remote Dangerfile from \(filePath). \(error.localizedDescription)"])
            return .failure(err)
        }
    }

//    /// Fetches the content of a remote Dangerfile asynchronously.
//    private func fetchRemoteDangerfileContent(url: URL, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
//        let task = session.dataTask(with: url) { data, response, error in
//            // (Error handling for network, status code, data decoding - same as before)
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            guard let httpResponse = response as? HTTPURLResponse else {
//                let error = NSError(domain: RemoteDangerfilePlugin.id, code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response received (not HTTP) from \(url)"])
//                completion(.failure(error))
//                return
//            }
//            guard (200...299).contains(httpResponse.statusCode) else {
//                let error = NSError(domain: RemoteDangerfilePlugin.id, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch remote Dangerfile from \(url). Status code: \(httpResponse.statusCode)"])
//                completion(.failure(error))
//                return
//            }
//            guard let data = data, let content = String(data: data, encoding: .utf8) else {
//                 let error = NSError(domain: RemoteDangerfilePlugin.id, code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response data from \(url) as UTF-8 string."])
//                completion(.failure(error))
//                return
//            }
//            completion(.success(content))
//        }
//        task.resume()
//    }

    /// Creates a temporary Swift file with the provided content.
    private func createTempFile(with content: String) throws -> URL {
       // (Same implementation as before)
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "RemoteDangerfile-\(UUID().uuidString).swift"
        let tempURL = tempDir.appendingPathComponent(fileName)
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            print("Created temporary remote Dangerfile at: \(tempURL.path)")
            return tempURL
        } catch {
            throw NSError(domain: RemoteDangerfilePlugin.id, code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to write remote Dangerfile content to temporary file at \(tempURL.path): \(error.localizedDescription)", NSUnderlyingErrorKey: error])
        }
    }
}

// MARK: - No DangerDSL Extension Needed Now

// We removed the DangerDSL extension because direct access `danger.remoteDangerfilePlugin`
// is generally more reliable and avoids potential issues with dynamic member lookup timing
// within extensions.

// MARK: - How to Use

/*
 1.  **Add Dependency:** Make sure your Danger setup includes the ShellOut package.
     If using Swift Package Manager (`Dangerfile.swift`), add this comment near the top:
     ```swift
     // package: https://github.com/JohnSundell/ShellOut.git == 2.3.0 // Or latest compatible version
     ```

 2.  **Save Plugin:** Save the code above as `RemoteDangerfilePlugin.swift` (or similar)
     in your Danger plugins directory (e.g., `Danger/Plugins/RemoteDangerfilePlugin.swift`).
     Ensure this file is compiled as part of your Danger run.

 3.  **In your main `Dangerfile.swift`:**

     a. Import `Foundation` if creating `URL` objects.
     b. Register the plugin.
     c. Access the plugin instance directly via `danger.remoteDangerfilePlugin` (Danger synthesizes this property).
     d. Call the `importAndExecuteRemoteDangerfile` method within a `do/catch` block.

     ```swift
     import Danger
     import Foundation // Needed for URL

     // Make sure ShellOut is imported if you use it directly elsewhere,
     // the plugin imports it internally.
     // import ShellOut

     // Register the plugin (ensure the plugin file is compiled)
     Danger.registerPlugin(RemoteDangerfilePlugin.self)

     let danger = Danger()

     // --- Usage Example ---
     let remoteURLString = "https://raw.githubusercontent.com/your-org/your-repo/main/.github/danger/SharedDangerfile.swift"

     print("Attempting to import and execute remote Dangerfile: \(remoteURLString)")
     print("WARNING: Remote execution has security risks and runs in a subprocess.")
     print("         Check the subprocess output below for its results.")

     if let remoteURL = URL(string: remoteURLString) {
         do {
             // Access the plugin instance directly (lowerCamelCase of class name)
             // and call its method.
             try danger.remoteDangerfilePlugin.importAndExecuteRemoteDangerfile(from: remoteURL)

             // IMPORTANT: This message only indicates the *subprocess finished*.
             // It does NOT guarantee the remote Dangerfile passed without 'fail' calls.
             // Check the console output above for the remote file's specific results.
             print("Remote Dangerfile subprocess finished successfully.")
             // You might add a `danger.message` here as a reminder.
             danger.message("Remote Dangerfile execution via subprocess completed. Review output above for details.")

         } catch {
             // This catches errors during fetch, file saving, or if the subprocess command itself failed
             // (e.g., non-zero exit code from the remote Dangerfile's `dsl.fail`)
             danger.fail("Failed to import or execute remote Dangerfile from \(remoteURLString): \(error.localizedDescription)")
             // You could potentially inspect the error userInfo for stderr if it's the custom NSError
             if let nsError = error as NSError?, let stderr = nsError.userInfo["stderr"] as? String, !stderr.isEmpty {
                 print("Subprocess stderr was:\n\(stderr)")
             }
         }
     } else {
         danger.fail("Invalid remote URL string: \(remoteURLString)")
     }

     // ... rest of your main Dangerfile logic ...
     ```
*/


*/
