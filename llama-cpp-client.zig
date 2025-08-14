const std = @import("std");

// pub fn formatPromptTemplate(allocator: std.mem.Allocator, template: *const [*:0]u8, ) void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
//     // const alloc = gpa.allocator();
//     defer _ = gpa.deinit();

//     // *const [*:0]u8

//     const alloc_buf = try std.fmt.allocPrint(alloc, template, .{ "a", "b" }); // I want this list (passed as third arg) to be able to vary in number
// }

/// Formats a multiline prompt template with a varying number of dynamic string arguments as substitutions
///
/// The template is expected to contain "{s}" placeholders where the dynamic arguments
/// should be inserted. Each line of the template is treated as a potential insertion point.
///
/// Returns an allocated string containing the formatted prompt.
/// Caller owns the returned memory.
pub fn formatPromptTemplate(allocator: std.mem.Allocator, template: []const u8, substitutions: []const []const u8) ![]u8 {
    var list = std.ArrayList(u8).init(allocator);
    errdefer list.deinit();

    var arg_index: usize = 0;
    var it = std.mem.splitScalar(u8, template, '\n'); // Split the template by newline characters

    while (it.next()) |line| {
        // Iterate through each line of the template
        var line_it = std.mem.splitSequence(u8, line, "{s}"); // Split each line by the "{s}" placeholder
        try list.writer().print("{s}", .{line_it.next().?}); // Print the first part of the line

        while (line_it.next()) |part| {
            // If there's a dynamic argument available, print it
            if (arg_index < substitutions.len) {
                try list.writer().print("{s}", .{substitutions[arg_index]});
                arg_index += 1;
            }
            try list.writer().print("{s}", .{part}); // Print the next part of the line
        }
        try list.writer().writeByte('\n'); // Add a newline after each line is processed
    }
    _ = list.pop(); // Remove the last (unnecessary) newline added by the loop

    return list.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var debug_allocator = gpa.allocator();

    defer {
        if (gpa.deinit() == .leak) {
            std.debug.print("Memory leak detected\n", .{});
            std.process.exit(1);
        }
    }

    const template =
        \\foo is apparently {s}
        \\and bar is {s} lol
    ;

    const result = try formatPromptTemplate(debug_allocator, template, &[_][]const u8{ "hello", "world" });
    defer debug_allocator.free(result);
    std.debug.print("{s}\n", .{result});
}
