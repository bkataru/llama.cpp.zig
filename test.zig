const std = @import("std");

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}).init;
    defer std.debug.assert(gpa_impl.deinit() == .ok);
    const alloc = gpa_impl.allocator();

    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();

    const uri = try std.Uri.parse("http://127.0.0.1:1337/v1/chat/completions");
    var header_buffer: [4096]u8 = undefined;
    var req = try client.open(.POST, uri, .{ .server_header_buffer = &header_buffer });
    defer req.deinit();

    // JSON payload: non-streaming for simplicity
    const body =
        \\{
        \\    "model": "qwen3:4b-instruct",
        \\    "prompt": "You are a helpful assistant. Summarize: Hello world",
        \\    "stream": false
        \\}
    ;

    // If you know exact length, set req.transfer_encoding.content_length
    req.transfer_encoding = .{ .content_length = body.len };

    try req.send(); // send request headers
    try req.writer().writeAll(body); // send body
    try req.finish(); // finalize
    try req.wait(); // wait for response headers

    const reader = req.reader();
    const resp_body = try reader.readAllAlloc(alloc, 16384);
    defer alloc.free(resp_body);

    std.debug.print("response: {s}\n", .{resp_body});
}
