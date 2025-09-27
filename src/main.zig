const std = @import("std");
const ui = @import("ui.zig");

pub const std_options = @import("logger.zig").options;
const WinKernel = std.os.windows.kernel32;

pub fn main() !void {
    _ = WinKernel.SetConsoleOutputCP(65001);
    var stdoutBuffer: [1024]u8 = undefined;
    var getStdOut = std.fs.File.stdout().writer(&stdoutBuffer);
    const stdout = &getStdOut.interface;

    // try stdout.print("{any}", .{@TypeOf(stdout)}); // *Io.Writer
    ui.main();
    std.log.info("main", .{});

    try stdout.flush();
}
