const std = @import("std");
const ui = @import("ui.zig");
const card = @import("card.zig");
const builtin = @import("builtin");
const game = @import("game.zig");

pub const std_options = @import("logger.zig").options;
const WinKernel = std.os.windows.kernel32;

pub fn startScreen(writer: *std.Io.Writer, reader: *std.Io.Reader) !void {
    const row = 20;
    const col = 80;
    try ui.clearScreen(writer);

    try ui.placeTextAt(writer, "██    ██  ██    ██   ██████ ", .{}, row, col);
    try ui.placeTextAt(writer, "██    ██  ███   ██  ██    ██", .{}, row + 1, col);
    try ui.placeTextAt(writer, "██    ██  ██ █  ██  ██    ██", .{}, row + 2, col);
    try ui.placeTextAt(writer, "██    ██  ██  █ ██  ██    ██", .{}, row + 3, col);
    try ui.placeTextAt(writer, "██    ██  ██   ███  ██    ██", .{}, row + 4, col);
    try ui.placeTextAt(writer, "██    ██  ██    ██  ██    ██", .{}, row + 5, col);
    try ui.placeTextAt(writer, " ██████   ██    ██   ██████ ", .{}, row + 6, col);

    try ui.placeTextAt(writer, "ON THE COMMAND LINE", .{}, row + 7, col + 5);
    try ui.placeTextAt(writer, "Press ENTER to continue", .{}, row + 9, col + 3);

    try ui.moveCursor(writer, 100, 900);
    const waitInput = try reader.takeDelimiterExclusive('\n');
    _ = waitInput;
}

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

    // Start the Game
    // try startScreen(stdout, stdin);
    try ui.clearScreen(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var gamestate = try game.GameState.init(allocator);
    try gamestate.getPlayers(allocator, stdin, stdout);

    const testCard1 = try card.Card.init(.RED, .{ .NUMBER = 7 });
    const testCard2 = try card.Card.init(.BLUE, .SKIP);
    const testCard3 = try card.Card.init(.YELLOW, .{ .NUMBER = 0 });

    try ui.renderCard(stdout, testCard1, 10, 10);
    try ui.renderCard(stdout, testCard2, 10, 15);
    try ui.renderCard(stdout, testCard3, 10, 20);

    try stdout.flush();
}
