const std = @import("std");
const log = std.log.scoped(.ui);
const cardColor = @import("card.zig").CardColor;
const cardType = @import("card.zig").CardType;
const Card = @import("card.zig").Card;
const GameState = @import("game.zig").GameState;

const uiColor = enum { RED, BLUE, GREEN, YELLOW, ORANGE, WHITE, RESET };

const Ansi = struct {
    pub const reset = "\x1B[0m";
    pub const clearScreen = "\x1B[2J";
    pub const cursorHome = "\x1B[H";
    pub const hideCursor = "\x1B[?25l";
    pub const showCursor = "\x1B[?25h";
};

fn fgColor(code: uiColor) []const u8 {
    return switch (code) {
        .RED => "\x1B[31m",
        .GREEN => "\x1B[32m",
        .YELLOW => "\x1B[33m",
        .BLUE => "\x1B[34m",
        .WHITE => "\x1B[37m",
        .ORANGE => "\x1B[38;5;208m",
        .RESET => "\x1B[39m",
    };
}

pub fn bgColor(code: uiColor) []const u8 {
    return switch (code) {
        .RED => "\x1B[41m",
        .GREEN => "\x1B[42m",
        .YELLOW => "\x1B[43m",
        .BLUE => "\x1B[44m",
        .WHITE => "\x1B[47m",
        .ORANGE => "\x1B[48;5;208m",
        .RESET => "\x1B[49m",
    };
}

pub fn CardToUiColor(code: cardColor) uiColor {
    return switch (code) {
        .RED => .RED,
        .BLUE => .BLUE,
        .GREEN => .GREEN,
        .YELLOW => .YELLOW,
        .WILDCOLOR => .ORANGE,
    };
}

pub fn clearScreen(writer: *std.Io.Writer) !void {
    //Clear the colors otherwise the previous background color will cover the screen
    try setColor(writer, null, null);
    try writer.print("{s}{s}", .{ Ansi.clearScreen, Ansi.cursorHome });
    try writer.flush();
}

pub fn setColor(writer: *std.Io.Writer, fg: ?uiColor, bg: ?uiColor) !void {
    if (fg) |f| {
        try writer.print("{s}", .{fgColor(f)});
    } else {
        try writer.print("{s}", .{fgColor(.RESET)});
    }

    if (bg) |b| {
        try writer.print("{s}", .{bgColor(b)});
    } else {
        try writer.print("{s}", .{bgColor(.RESET)});
    }

    try writer.flush();
}

pub fn homeCursor(writer: *std.Io.Writer) !void {
    try writer.print("{s}", .{Ansi.cursorHome});
    try writer.flush();
}

pub fn moveCursor(writer: *std.Io.Writer, row: usize, col: usize) !void {
    try writer.print("\x1B[{d};{d}H", .{ row, col });
    try writer.flush();
}

// TODO: add a check for out of bounds
pub fn placeTextAt(writer: *std.Io.Writer, comptime text: []const u8, args: anytype, row: usize, col: usize) !void {
    try writer.print("\x1B[{d};{d}H", .{ row, col });
    try writer.print(text, args);
    try writer.flush();
}

pub fn placeBox(writer: *std.Io.Writer, row: usize, col: usize, height: usize, width: usize) !void {
    try placeTextAt(writer, "┌\n", .{}, row, col);
    try placeTextAt(writer, "┐\n", .{}, row, col + width - 1);

    for (0..width - 2) |i| {
        try placeTextAt(writer, "─\n", .{}, row, col + i + 1);
        try placeTextAt(writer, "─\n", .{}, row + height - 1, col + i + 1);
    }

    for (0..height - 2) |i| {
        try placeTextAt(writer, "│\n", .{}, row + i + 1, col);
        try placeTextAt(writer, "│\n", .{}, row + i + 1, col + width - 1);
    }

    try placeTextAt(writer, "└\n", .{}, row + height - 1, col);
    try placeTextAt(writer, "┘\n", .{}, row + height - 1, col + width - 1);
}

pub fn renderCard(writer: *std.Io.Writer, card: Card, row: usize, col: usize) !void {
    const color = CardToUiColor(card.color);
    try setColor(writer, color, null);

    // type cast int into str through bufPrint
    var buf: [3]u8 = undefined;
    const value = switch (card.value) {
        .NUMBER => |n| blk: {
            const num = try std.fmt.bufPrint(&buf, "{}", .{n});
            break :blk num;
        },
        .SKIP => "⦸",
        .DRAW2 => "+2",
        .REVERSE => "↺",
        .WILD => "★",
        .WILD4 => "+4",
    };

    const padding: u8 = switch (value.len) {
        2 => 0,
        else => 1
    };
    const spaces = " ";

    try placeTextAt(writer, "┌───┐\n", .{}, row, col);
    try placeTextAt(writer, "│   │\n", .{}, row + 1, col);
    try placeTextAt(writer, "│{s}{s}{s}│\n", .{ spaces[0..padding], value, " " }, row + 2, col);
    try placeTextAt(writer, "│   │\n", .{}, row + 3, col);
    try placeTextAt(writer, "└───┘\n", .{}, row + 4, col);

    try setColor(writer, null, null);
    try homeCursor(writer);
    try writer.flush();
}

pub fn startScreen(writer: *std.Io.Writer, reader: *std.Io.Reader) !void {
    const row = 20;
    const col = 80;
    try clearScreen(writer);

    try placeTextAt(writer, "██    ██  ██    ██   ██████ ", .{}, row, col);
    try placeTextAt(writer, "██    ██  ███   ██  ██    ██", .{}, row + 1, col);
    try placeTextAt(writer, "██    ██  ██ █  ██  ██    ██", .{}, row + 2, col);
    try placeTextAt(writer, "██    ██  ██  █ ██  ██    ██", .{}, row + 3, col);
    try placeTextAt(writer, "██    ██  ██   ███  ██    ██", .{}, row + 4, col);
    try placeTextAt(writer, "██    ██  ██    ██  ██    ██", .{}, row + 5, col);
    try placeTextAt(writer, " ██████   ██    ██   ██████ ", .{}, row + 6, col);

    try placeTextAt(writer, "ON THE COMMAND LINE", .{}, row + 7, col + 5);
    try placeTextAt(writer, "Press ENTER to continue", .{}, row + 9, col + 3);

    try moveCursor(writer, 100, 900);
    const waitInput = try reader.takeDelimiterExclusive('\n');
    _ = waitInput;
}

pub fn chooseColorScreen(writer: *std.Io.Writer, reader: *std.Io.Reader) !u8 {
    const row = 20;
    const col = 30;

    try placeBox(writer, row, col, 8, 20);
    try placeTextAt(writer, "  Select a Color  ", .{}, row + 1, col + 1);
    try placeTextAt(writer, " (press a number) ", .{}, row + 2, col + 1);
    try placeTextAt(writer, " 1) YELLOW 2) RED ", .{}, row + 4, col + 1);
    try placeTextAt(writer, " 3) GREEN 4) BLUE ", .{}, row + 5, col + 1);
    try moveCursor(writer, row + 6, col + 1);

    const cardColorInput = try reader.takeDelimiterExclusive('\n');
    const trimmedInput = std.mem.trimRight(u8, cardColorInput, "\r");
    const input = std.fmt.parseInt(u8, trimmedInput, 10) catch 1;
    return input;
}

pub fn gameFrame(writer: *std.Io.Writer, reader: *std.Io.Reader, gamestate: GameState) !void {
    _ = reader;
    try clearScreen(writer);
    // display top card
    try renderCard(writer, gamestate.topCard, 20, 80);

    // display player name
    try placeTextAt(writer, "{s}", .{gamestate.players.items[gamestate.turn].name}, 10, 20);

    // box around player cards
    try placeBox(writer, 39, 4, 8, 100);

    // display players cards
    for (gamestate.players.items[gamestate.turn].hand.items, 0..) |card, i| {
        if (i > 10) break;
        const col = 5 + (6 * i);
        try renderCard(writer, card, 40, col);
        try placeTextAt(writer, "{d}", .{i}, 45, col + 2);
    }

    // box around user input
    try placeBox(writer, 47, 4, 3, 100);

    try homeCursor(writer);
}
