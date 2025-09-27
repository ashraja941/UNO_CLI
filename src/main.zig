const std = @import("std");
const ui = @import("ui.zig");
const card = @import("card.zig");
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

    try ui.clearScreen(stdout);

    const testCard1 = try card.Card.init(.RED, .{ .NUMBER = 7 });
    const testCard2 = try card.Card.init(.BLUE, .SKIP);
    const testCard3 = try card.Card.init(.WILDCOLOR, .WILD4);

    try ui.renderCard(stdout, testCard1, 10, 10);
    try ui.renderCard(stdout, testCard2, 10, 15);
    try ui.renderCard(stdout, testCard3, 10, 20);

    try stdout.flush();
}
