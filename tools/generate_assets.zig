const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    if (args.len != 5) {
        std.debug.print("Usage: {s} --input <dir> --output <dir>\n", .{args[0]});
        return error.InvalidArguments;
    }
    
    const input_dir = args[2];
    const output_dir = args[4];
    
    // Create output directory
    try std.fs.cwd().makePath(output_dir);
    
    // Asset files to process
    const assets = [_]struct { name: []const u8, compress: bool }{
        .{ .name = "index.html", .compress = true },
        .{ .name = "loading.html", .compress = false },
        .{ .name = "theme-beeninorder.css", .compress = true },
        .{ .name = "system-prompts.mjs", .compress = true },
        .{ .name = "prompt-formats.mjs", .compress = true },
        .{ .name = "json-schema-to-grammar.mjs", .compress = true },
    };
    
    for (assets) |asset| {
        try processAsset(allocator, input_dir, output_dir, asset.name, asset.compress);
    }
}

fn processAsset(allocator: std.mem.Allocator, input_dir: []const u8, output_dir: []const u8, name: []const u8, compress: bool) !void {
    const input_path = try std.fs.path.join(allocator, &.{ input_dir, name });
    defer allocator.free(input_path);
    
    const output_name = try std.fmt.allocPrint(allocator, "{s}.hpp", .{name});
    defer allocator.free(output_name);
    
    const output_path = try std.fs.path.join(allocator, &.{ output_dir, output_name });
    defer allocator.free(output_path);
    
    // Read input file
    const input_data = try std.fs.cwd().readFileAlloc(allocator, input_path, 10 * 1024 * 1024);
    defer allocator.free(input_data);
    
    // Compress if requested
    const data = if (compress) blk: {
        var compressed = std.ArrayList(u8).init(allocator);
        defer compressed.deinit();
        
        var compressor = try std.compress.gzip.compressor(compressed.writer(), .{});
        try compressor.writer().writeAll(input_data);
        try compressor.finish();
        
        break :blk try compressed.toOwnedSlice();
    } else input_data;
    defer if (compress) allocator.free(data);
    
    // Generate C++ header
    const var_name = try sanitizeVarName(allocator, name);
    defer allocator.free(var_name);
    
    var output_file = try std.fs.cwd().createFile(output_path, .{});
    defer output_file.close();
    
    const writer = output_file.writer();
    
    // Write header
    try writer.print("// Generated from {s}\n", .{name});
    try writer.print("#pragma once\n");
    try writer.print("#include <string>\n\n");
    
    if (compress) {
        try writer.print("static const std::string {s}_gz = ", .{var_name});
    } else {
        try writer.print("static const std::string {s} = ", .{var_name});
    }
    
    // Write data as hex string
    try writer.writeAll("std::string(\"");
    for (data) |byte| {
        try writer.print("\\x{x:0>2}", .{byte});
    }
    try writer.writeAll("\", ");
    try writer.print("{});\n", .{data.len});
}

fn sanitizeVarName(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var result = try allocator.alloc(u8, name.len);
    for (name, 0..) |char, i| {
        result[i] = switch (char) {
            '.', '-' => '_',
            else => char,
        };
    }
    return result;
}