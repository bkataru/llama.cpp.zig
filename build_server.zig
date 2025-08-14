// const std = @import("std");
// const Builder = std.Build;
// const Target = std.Build.ResolvedTarget;
// const Mode = std.builtin.Mode;
// const CompileStep = std.Build.Step.Compile;
// const LazyPath = std.Build.LazyPath;

// const llama = @import("build_llama.zig");

// pub const ServerOptions = struct {
//     enable_ssl: bool = false,
//     enable_cors: bool = true,
//     enable_metrics: bool = true,
//     embed_assets: bool = true,
// };

// /// Build server executable
// pub fn buildServer(ctx: *llama.Context, options: ServerOptions) *CompileStep {
//     const b = ctx.b;

//     // Create server executable
//     const server_exe = b.addExecutable(.{
//         .name = "llama-server",
//         .target = ctx.options.target,
//         .optimize = ctx.options.optimize,
//     });

//     // Configure include paths
//     server_exe.addIncludePath(ctx.path(&.{"include"}));
//     server_exe.addIncludePath(ctx.path(&.{"common"}));
//     server_exe.addIncludePath(ctx.path(&.{ "ggml", "include" }));
//     server_exe.addIncludePath(ctx.path(&.{ "ggml", "src" }));
//     server_exe.addIncludePath(ctx.path(&.{ "examples", "server" }));

//     // Link against libllama
//     ctx.link(server_exe);

//     // Add server source files
//     const server_sources = [_][]const u8{
//         "server.cpp",
//         "utils.hpp",
//     };

//     for (server_sources) |src| {
//         const file_path = ctx.path(&.{ "examples", "server", src });
//         if (std.mem.endsWith(u8, src, ".cpp")) {
//             server_exe.addCSourceFile(.{
//                 .file = file_path,
//                 .flags = ctx.flags() ++ &[_][]const u8{
//                     "-std=c++17",
//                     "-fexceptions",
//                 },
//             });
//         }
//     }

//     // Handle embedded assets

// }

// /// Generate embedded HTML assets
// fn generateAssets(b: *Builder, ctx: *llama.Context) []LazyPath {
//     const asset_gen = b.addExecutable(.{
//         .name = "asset-generator",
//         .root_source_file = b.path("tools/generate_assets.zig"),
//         .target = b.host,

//     });
// }
