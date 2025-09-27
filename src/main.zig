const std = @import("std");
const ui = @import("ui.zig");
const builtin = @import("builtin");

pub const std_options = @import("logger.zig").options;
const WinKernel = std.os.windows.kernel32;

pub fn main() !void {
    // set windows to use UTF-8 Characters
    if (builtin.os.tag == .windows) {
        _ = WinKernel.SetConsoleOutputCP(65001);
    }

    var stdoutBuffer: [1024]u8 = undefined;
    var getStdOut = std.fs.File.stdout().writer(&stdoutBuffer);
    const stdout = &getStdOut.interface;

    // try stdout.print("{any}", .{@TypeOf(stdout)}); // *Io.Writer

    try ui.setColor(stdout, .RED, .GREEN);
    std.debug.print("test", .{});

    try ui.clearScreen(stdout);

    try ui.setColor(stdout, .YELLOW, .RED);
    try ui.moveCursor(stdout, 3, 200);
    std.debug.print("changed", .{});
    std.log.info("main", .{});

    try stdout.flush();
}
