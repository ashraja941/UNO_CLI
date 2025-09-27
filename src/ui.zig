const std = @import("std");
const log = std.log.scoped(.ui);
const cardColor = @import("card.zig").cardColor;

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

// TODO: add a check for out of bounds
pub fn moveCursor(writer: *std.Io.Writer, row: usize, col: usize) !void {
    try writer.print("\x1B[{d};{d}H", .{ row, col });
    try writer.flush();
}

pub fn main() void {
    log.info("Test", .{});
}
