const std = @import("std");
const Player = @import("player.zig").Player;
const ArrayList = std.ArrayList;
const Card = @import("card.zig").Card;
const Allocator = std.mem.Allocator;

const GameDirection = enum { FORWARD, BACKWARD };

const aiNames = [_][]const u8{
    "HAL9000",
    "Skynet",
    "Cortana",
    "DeepBlue",
    "RoboBob",
    "GLaDOS",
    "T-800",
    "Marvin",
};

pub const GameState = struct {
    players: ArrayList(Player),
    gameDirection: GameDirection,
    turn: usize,
    topCard: Card,

    pub fn init(allocator: Allocator) !GameState {
        return .{
            .players = try ArrayList(Player).initCapacity(allocator, 4),
            .gameDirection = .FORWARD,
            .turn = 0,
            // TODO: Create random first card
            .topCard = try Card.init(.BLUE, .{ .NUMBER = 1 })
        };
    }

    // TODO: deallocate all the memory
    // pub fn deinit(allocator: Allocator) void {}

    pub fn getPlayers(self: *GameState, allocator: Allocator, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        try writer.print("Enter the number of Human Players : ", .{});
        try writer.flush();
        const humanLine = try reader.takeDelimiterExclusive('\n');
        const trimmedHuman = std.mem.trimRight(u8, humanLine, "\r"); // remove the stupid windows \r
        const numHumans = try std.fmt.parseInt(u8, trimmedHuman, 10);

        try writer.print("Enter the number of AI Players    : ", .{});
        try writer.flush();
        const aiLine = try reader.takeDelimiterExclusive('\n');
        const trimmedAi = std.mem.trimRight(u8, aiLine, "\r"); // remove the stupid windows \r
        const numAi = try std.fmt.parseInt(u8, trimmedAi, 10);

        var names = try ArrayList([]u8).initCapacity(allocator, 2);
        defer {
            for (names.items) |n| allocator.free(n);
            names.deinit(allocator);
        }

        for (0..(numHumans)) |i| {
            try writer.print("Enter name of player {d} : ", .{i + 1});
            try writer.flush();
            const nameLine = try reader.takeDelimiterExclusive('\n');
            const owned = try allocator.alloc(u8, nameLine.len);
            std.mem.copyForwards(u8, owned, nameLine);
            try names.append(allocator, owned);
        }

        for (0..(numAi)) |i| {
            // Choose random names from a list
            const nameLine = aiNames[i];
            const owned = try allocator.alloc(u8, nameLine.len);
            std.mem.copyForwards(u8, owned, nameLine);
            try names.append(allocator, owned);
        }

        for (names.items) |n| {
            const player = try Player.init(allocator, n, .HUMAN);
            try self.players.append(allocator, player);
        }

        for (self.players.items) |p| {
            try writer.print("player info : {s}\n", .{p.name});
        }
    }
};
