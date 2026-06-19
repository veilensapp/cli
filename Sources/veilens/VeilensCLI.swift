import Foundation
import Darwin
import ArgumentParser
import VeilensCore

// The `veilens` CLI — the personal-data-vault umbrella. It drives the same engine
// lifecycle as the millrace app's Bootstrapper, into the shared install tree
// (~/Library/Application Support/Millrace) + the me.millrace.server launchd job, so
// `veilens` and the `millrace` CLI interoperate on one inference server. `install`
// provisions the server + headgate + the veilens vault; `start` brings them all up
// (the vault site at http://localhost:10000); `stop` tears them down.

@main
struct Veilens: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "veilens",
        abstract: "The veilens personal data vault — install, start, stop, index, and ask.",
        subcommands: [Install.self, Update.self, Start.self, Stop.self, Status.self, Index.self, Ask.self]
    )
}

// ── veilens install ──────────────────────────────────────────────────────────
struct Install: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Install the millrace inference server, headgate, and the veilens local site.",
        discussion: """
        Idempotent — reuses anything already installed. Provisions the combined \
        inference server (chat + embeddings, including both models' weights), the \
        headgate privacy harness + its vault web site, and the veilens vault tools.
        """)
    @MainActor func run() async throws {
        let boot = streaming()
        try await boot.installVault()
        print("✓ veilens installed (inference server + headgate + veilens site)")
    }
}

// ── veilens update ─────────────────────────────────────────────────────────────
struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Update veilens and its components to the latest release.",
        discussion: """
        Upgrades the `veilens` CLI via Homebrew, then refreshes the downloadable \
        components (inference-server engine, headgate, veilens engine) to their \
        latest releases. The Mojo toolchains and the model weights are kept, so it \
        only re-fetches + rebuilds the source bundles. Progress is logged to \
        ~/Library/Logs/Veilens/<date>.log.
        """)
    @Flag(name: .long, help: "Refresh the components only; don't upgrade the CLI via Homebrew.")
    var skipCli = false

    @MainActor func run() async throws {
        let boot = streaming()
        try await boot.selfUpdate(updateCLI: !skipCli)
        print("✓ veilens up to date")
    }
}

// ── veilens start ────────────────────────────────────────────────────────────
struct Start: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start everything — the inference server and the veilens app at http://localhost:10000.",
        discussion: """
        Ensures the combined inference server is running (launchd), then starts the \
        veilens app servers (UI on :10000, streaming on :10001) in the background — \
        no Terminal — and opens http://localhost:10000. Server logs:
        ~/Library/Logs/Veilens/server.log.
        """)
    @MainActor func run() async throws {
        let boot = Bootstrapper()
        try await boot.startVaultChat(vaultDir: boot.ensureVaultDir())
        print("✓ veilens running in the background — http://localhost:10000")
        print("  logs: \(boot.veilensLogDir.appendingPathComponent("server.log").path)")
    }
}

// ── veilens stop ─────────────────────────────────────────────────────────────
struct Stop: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Stop the inference server and the veilens local site.")
    @MainActor func run() async throws {
        let boot = Bootstrapper()
        boot.refreshServerRunning()
        let wasRunning = boot.serverRunning
        try boot.stopServer()
        print(wasRunning ? "✓ inference server stopped" : "• inference server was not running")
        let stoppedApp = boot.stopAppServer()
        let stoppedWeb = boot.stopHeadgateWeb()
        print(stoppedApp || stoppedWeb
              ? "✓ veilens app stopped" : "• veilens app was not running")
    }
}

// ── veilens status ───────────────────────────────────────────────────────────
struct Status: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Show what's installed.")
    @MainActor func run() async throws {
        let boot = Bootstrapper()
        print("server:     \(mark(boot.isServerInstalled))")
        print("weights:    \(mark(boot.weightsPresent))")
        print("embeddings: \(mark(boot.embedWeightsPresent))")
        print("headgate:   \(mark(boot.isHeadgateInstalled))")
        print("veilens:    \(mark(boot.isVeilensInstalled))")
        print("app server: \(mark(boot.isAppServerInstalled))")
    }
}

// ── veilens index <folder> ───────────────────────────────────────────────────
struct Index: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Build the vault index over a folder (`veilens index <folder>`).",
        discussion: """
        Forwards to the veilens binary's `index` command, which embeds every file's \
        chunks via the combined inference server's /v1/embeddings and stores them in \
        the on-device LanceDB index. Needs the server running (`veilens start`).
        """)
    @Argument(help: "The folder to index (your vault dir).")
    var folder: String

    @MainActor func run() async throws {
        let boot = Bootstrapper()
        // Run the veilens launcher (`index <folder>`) as a logged child so its
        // output — and any failure — is captured in the veilens log.
        let code = try boot.runVaultIndex(folder: folder)
        try finish(code, boot, "veilens index")
    }
}

// ── veilens ask "<question>" ─────────────────────────────────────────────────
struct Ask: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "One-shot vault answer (`veilens ask \"<question>\"`).",
        discussion: """
        Runs the headgate vault loop over your vault dir: a model writes a Mojo \
        program that uses the veilens vault tools over your real data locally, and \
        the answer is printed here. The vault dir is $VEILENS_VAULT, else ~/.config/veilens/vault. \
        Needs the inference server running.
        """)
    @Argument(parsing: .remaining, help: "The question to ask your vault.")
    var question: [String] = []

    @MainActor func run() async throws {
        guard !question.isEmpty else {
            throw BootstrapError.step("veilens ask", "no question given")
        }
        let boot = streaming()   // stream progress to the console
        let q = question.joined(separator: " ")
        let dir = boot.ensureVaultDir()
        // The vault loop calls the model via the inference server — make sure it's
        // up, else `ask` blocks on a dead endpoint with no feedback.
        try boot.ensureInferenceServer()
        print("Thinking — progress below (first run can take a minute):")
        // Run the headgate vault loop (`vault "<q>" <dir>`) as a logged child so its
        // streamed progress + the answer (and any failure) surface here and in the log.
        let code = try boot.runVaultAsk(question: q, vaultDir: dir)
        try finish(code, boot, "veilens ask")
    }
}

/// Map a child's exit status to the CLI's: on failure, point at the diagnostic
/// log, then propagate the same code via ArgumentParser's ExitCode.
@MainActor private func finish(_ code: Int32, _ boot: Bootstrapper, _ what: String) throws {
    if code != 0 {
        FileHandle.standardError.write(Data(
            "\n\(what) failed (exit \(code)). Diagnostics: \(boot.veilensLogURL.path)\n".utf8))
    }
    throw ExitCode(code)
}

// ── helpers ──────────────────────────────────────────────────────────────────
/// A Bootstrapper that streams progress lines to stdout (for `install`).
@MainActor private func streaming() -> Bootstrapper {
    let boot = Bootstrapper()
    boot.onProgress = { print($0) }
    return boot
}

private func mark(_ ok: Bool) -> String { ok ? "yes" : "no" }
