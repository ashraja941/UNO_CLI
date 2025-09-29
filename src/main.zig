const std = @import("std");
const ui = @import("ui.zig");
const card = @import("card.zig");
const builtin = @import("builtin");
const game = @import("game.zig");

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

    var stdinBuffer: [1024]u8 = undefined;
    var getStdIn = std.fs.File.stdin().reader(&stdinBuffer);
    const stdin = &getStdIn.interface;

    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    // Start the Game
    // try ui.startScreen(stdout, stdin);
    try ui.clearScreen(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var gamestate = try game.GameState.init(allocator, rand);
    try gamestate.initPlayers(allocator, rand, stdin, stdout);

    const testCard1 = try card.Card.init(.RED, .{ .NUMBER = 7 });
    const testCard2 = try card.Card.init(.BLUE, .SKIP);
    const testCard3 = try card.Card.init(.YELLOW, .{ .NUMBER = 0 });

    try ui.renderCard(stdout, testCard1, 10, 10);
    try ui.renderCard(stdout, testCard2, 10, 15);
    try ui.renderCard(stdout, testCard3, 10, 20);

    try stdout.flush();
}
