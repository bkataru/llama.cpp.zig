const std = @import("std");
const Builder = std.Build;
const Target = std.Build.ResolvedTarget;
const Mode = std.builtin.Mode;
const CompileStep = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;
const llama = @import("build_llama.zig");

pub const ServerOptions = struct {
    enable_ssl: bool = false,
    enable_cors: bool = true,
    enable_metrics: bool = true,
    embed_assets: bool = true,
};

/// Build server executable
pub fn buildServer(ctx: *llama.Context, options: ServerOptions) *CompileStep {
    const b = ctx.b;
    
    // Create server executable
    const server_exe = b.addExecutable(.{
        .name = "llama-server",
        .target = ctx.options.target,
        .optimize = ctx.options.optimize,
    });
    
    // Configure include paths
    server_exe.addIncludePath(ctx.path(&.{"include"}));
    server_exe.addIncludePath(ctx.path(&.{"common"}));
    server_exe.addIncludePath(ctx.path(&.{ "ggml", "include" }));
    server_exe.addIncludePath(ctx.path(&.{ "ggml", "src" }));
    server_exe.addIncludePath(ctx.path(&.{ "examples", "server" }));
    
    // Link against libllama
    ctx.link(server_exe);
    
    // Add server source files
    const server_sources = [_][]const u8{
        "server.cpp",
        "utils.hpp",
    };
    
    for (server_sources) |src| {
        const file_path = ctx.path(&.{ "examples", "server", src });
        if (std.mem.endsWith(u8, src, ".cpp")) {
            server_exe.addCSourceFile(.{
                .file = file_path,
                .flags = ctx.flags() ++ &[_][]const u8{
                    "-std=c++17",
                    "-fexceptions",
                },
            });
        }
    }
    
    // Handle embedded assets
    if (options.embed_assets) {
        const assets = generateAssets(b, ctx);
        for (assets) |asset| {
            server_exe.addCSourceFile(.{
                .file = asset,
                .flags = ctx.flags(),
            });
        }
    }
    
    // Platform-specific configuration
    configurePlatform(server_exe, ctx.options.target, options);
    
    // Add preprocessor definitions
    if (options.enable_cors) {
        server_exe.root_module.addCMacro("CPPHTTPLIB_CORS_SUPPORT", "1");
    }
    
    if (options.enable_metrics) {
        server_exe.root_module.addCMacro("SERVER_ENABLE_METRICS", "1");
    }
    
    return server_exe;
}

/// Generate embedded HTML assets
fn generateAssets(b: *Builder, ctx: *llama.Context) []LazyPath {
    const asset_gen = b.addExecutable(.{
        .name = "asset-generator",
        .root_source_file = b.path("tools/generate_assets.zig"),
        .target = b.host,
    });
    
    const run_asset_gen = b.addRunArtifact(asset_gen);
    run_asset_gen.addArg("--input");
    run_asset_gen.addFileArg(ctx.path(&.{ "examples", "server", "public" }));
    run_asset_gen.addArg("--output");
    const output_dir = run_asset_gen.addOutputDirectoryArg("generated");
    
    return &[_]LazyPath{
        output_dir.path(b, "index.html.hpp"),
        output_dir.path(b, "loading.html.hpp"),
        output_dir.path(b, "theme-beeninorder.css.hpp"),
        output_dir.path(b, "system-prompts.mjs.hpp"),
        output_dir.path(b, "prompt-formats.mjs.hpp"),
        output_dir.path(b, "json-schema-to-grammar.mjs.hpp"),
    };
}

/// Configure platform-specific settings
fn configurePlatform(exe: *CompileStep, target: Target, options: ServerOptions) void {
    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("ws2_32"); // Windows sockets
            exe.linkSystemLibrary("mswsock"); // Microsoft Windows sockets
            exe.root_module.addCMacro("_WIN32_WINNT", "0x0601"); // Windows 7+
            exe.root_module.addCMacro("NOMINMAX", ""); // Prevent min/max macros
        },
        .linux => {
            exe.linkSystemLibrary("pthread");
            if (options.enable_ssl) {
                exe.linkSystemLibrary("ssl");
                exe.linkSystemLibrary("crypto");
            }
        },
        .macos => {
            exe.linkSystemLibrary("pthread");
            if (options.enable_ssl) {
                exe.linkFramework("Security");
            }
        },
        else => {},
    }
    
    // SSL support
    if (options.enable_ssl) {
        exe.root_module.addCMacro("CPPHTTPLIB_OPENSSL_SUPPORT", "");
    }
}

/// Create run command with common arguments
pub fn createRunCommand(b: *Builder, server_exe: *CompileStep) *std.Build.Step.Run {
    const run_cmd = b.addRunArtifact(server_exe);
    
    // Add default arguments
    run_cmd.addArg("--host");
    run_cmd.addArg("0.0.0.0");
    run_cmd.addArg("--port");
    run_cmd.addArg("8080");
    
    // Pass through user arguments
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    return run_cmd;
}