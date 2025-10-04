const std = @import("std");
const log = std.log.scoped(.ui);
const cardColor = @import("card.zig").CardColor;
const cardType = @import("card.zig").CardType;
const Card = @import("card.zig").Card;
const GameState = @import("game.zig").GameState;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

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

pub fn truncateName(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len <= 8) {
        // return a copy of the original name
        const copy = try allocator.alloc(u8, name.len);
        std.mem.copyForwards(u8, copy, name);
        return copy;
    }

    const truncated = try allocator.alloc(u8, 8);
    std.mem.copyForwards(u8, truncated[0..5], name[0..5]);
    std.mem.copyForwards(u8, truncated[5..], "...");
    return truncated;
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
    // bounding box
    try placeBox(writer, 1, 1, 35, 99);

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
    const row = 14;
    const col = 37;

    try placeBox(writer, row, col, 8, 20);
    try placeTextAt(writer, "  Select a Color  ", .{}, row + 1, col + 1);
    try placeTextAt(writer, " (press a number) ", .{}, row + 2, col + 1);
    try placeTextAt(writer, "                  ", .{}, row + 3, col + 1);
    try placeTextAt(writer, " 1) YELLOW 2) RED ", .{}, row + 4, col + 1);
    try placeTextAt(writer, " 3) GREEN 4) BLUE ", .{}, row + 5, col + 1);
    try moveCursor(writer, row + 6, col + 1);

    const cardColorInput = try reader.takeDelimiterExclusive('\n');
    const trimmedInput = std.mem.trimRight(u8, cardColorInput, "\r");
    const input = std.fmt.parseInt(u8, trimmedInput, 10) catch 1;
    return input;
}

fn wrapIndex(turn: usize, offset: isize, numPlayers: usize) usize {
    // convert to signed so we can go negative
    const raw = @as(isize, @intCast(turn)) + offset;

    // modulo that works with negatives
    const wrapped = @mod(raw, @as(isize, @intCast(numPlayers)));

    return @intCast(wrapped);
}

fn displayPlayers(allocator: Allocator, writer: *std.Io.Writer, gamestate: GameState) !void {
    const index = gamestate.turn;
    // name 1
    try placeTextAt(writer, "👤", .{}, 3, 20);
    const before2 = wrapIndex(index, -2, gamestate.numPlayers);
    const before2name = try truncateName(allocator, gamestate.players.items[before2].name);
    defer allocator.free(before2name);
    const before2offset: usize = (before2name.len) / 2;
    try placeTextAt(writer, "{s}", .{before2name}, 4, 20 - before2offset);

    // name 2
    try placeTextAt(writer, "👤", .{}, 3, 32);
    const before1 = wrapIndex(index, -1, gamestate.numPlayers);
    const before1name = try truncateName(allocator, gamestate.players.items[before1].name);
    defer allocator.free(before1name);
    const before1offset: usize = (before1name.len) / 2;
    try placeTextAt(writer, "{s}", .{before1name}, 4, 32 - before1offset);

    // name 3
    try placeTextAt(writer, "🕹️", .{}, 3, 45);
    try placeTextAt(writer, "You", .{}, 4, 44);

    // name 4
    try placeTextAt(writer, "👤", .{}, 3, 57);
    const after1 = wrapIndex(index, 1, gamestate.numPlayers);
    const after1name = try truncateName(allocator, gamestate.players.items[after1].name);
    defer allocator.free(after1name);
    const after1offset: usize = (after1name.len) / 2;
    try placeTextAt(writer, "{s}", .{after1name}, 4, 57 - after1offset);

    // name 5
    try placeTextAt(writer, "👤", .{}, 3, 70);
    const after2 = wrapIndex(index, 2, gamestate.numPlayers);
    const after2name = try truncateName(allocator, gamestate.players.items[after2].name);
    defer allocator.free(after2name);
    const after2offset: usize = (after2name.len) / 2;
    try placeTextAt(writer, "{s}", .{after2name}, 4, 70 - after2offset);
    try writer.flush();
}

pub fn winScreen(writer: *std.Io.Writer, gamestate: GameState) !void {
    try placeBox(writer, 1, 1, 35, 99);
    try placeTextAt(writer, "{s} Won", .{gamestate.players.items[gamestate.turn].name}, 10, 20);
}

pub fn gameFrame(allocator: Allocator, writer: *std.Io.Writer, reader: *std.Io.Reader, gamestate: GameState) !void {
    _ = reader;
    try clearScreen(writer);

    // bounding box
    try placeBox(writer, 1, 1, 35, 99);

    // turn arrow
    switch (gamestate.gameDirection) {
        .FORWARD => {
            try placeTextAt(writer, "─────────────────────────────────────────────────────────────>", .{}, 2, 15);
        },
        .BACKWARD => {
            try placeTextAt(writer, "<─────────────────────────────────────────────────────────────", .{}, 2, 15);
        }
    }
    // display player line
    try displayPlayers(allocator, writer, gamestate);

    // display top card
    try renderCard(writer, gamestate.topCard, 15, 45);

    // display player name
    try placeTextAt(writer, "It's your turn : {s}", .{gamestate.players.items[gamestate.turn].name}, 23, 3);

    // box around player cards
    try placeBox(writer, 24, 3, 8, 95);

    // 2 arrows
    try placeTextAt(writer, "<", .{}, 25, 4);
    try placeTextAt(writer, ">", .{}, 25, 96);

    // display players cards
    const maxHandNumber = gamestate.players.items[gamestate.turn].hand.items.len / 15;
    if (gamestate.players.items[gamestate.turn].handNumber > maxHandNumber) {
        gamestate.players.items[gamestate.turn].handNumber = maxHandNumber;
    } else if (gamestate.players.items[gamestate.turn].handNumber < 0) {
        gamestate.players.items[gamestate.turn].handNumber = 0;
    }
    const currentHandNumber = gamestate.players.items[gamestate.turn].handNumber;

    for (gamestate.players.items[gamestate.turn].hand.items[(15 * currentHandNumber)..], 0..) |card, i| {
        if (i > 14) break;
        const col = 6 + (6 * i);
        try renderCard(writer, card, 25, col);
        try placeTextAt(writer, "{d}", .{i}, 30, col + 2);
    }

    // box around user input
    try placeBox(writer, 32, 3, 3, 95);
    try placeTextAt(writer, "Enter your move : ", .{}, 33, 5);

    try homeCursor(writer);
}

test "truncated name " {
    const allocator = std.testing.allocator;
    const name1 = "1234567890";
    const tName = try truncateName(allocator, name1);
    defer allocator.free(tName);
    const expected = "12345...";
    std.debug.print("{s}\n", .{tName});

    try expect(std.mem.eql(u8, expected, tName));
}
