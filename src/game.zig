const std = @import("std");
const ui = @import("ui.zig");
const Player = @import("player.zig").Player;
const Card = @import("card.zig").Card;
const CardType = @import("card.zig").CardType;
const CardColor = @import("card.zig").CardColor;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const GameDirection = enum { FORWARD, BACKWARD };

const aiNames = [_][]const u8{
    "Alice",
    "Alex",
    "Ashwin",
    "Andrea",
    "Andrew",
    "Augustine",
    "Aarya",
    "Amy",
    "Sway",
    "Asahino",
};

const CardWeight = struct {
    kind: CardType,
    weight: u4,
};

const weights = [_]CardWeight{
    .{ .kind = .{ .NUMBER = 0 }, .weight = 10 },
    .{ .kind = .SKIP, .weight = 1 },
    .{ .kind = .REVERSE, .weight = 1 },
    .{ .kind = .DRAW2, .weight = 1 },
    .{ .kind = .WILD, .weight = 1 },
    .{ .kind = .WILD4, .weight = 1 },
};

fn weightedChoice(rand: std.Random, table: []const CardWeight) CardType {
    var total: u8 = 0;
    for (table) |entry| {
        total += entry.weight;
    }

    const roll = rand.uintLessThan(u8, total);

    var cumilative: usize = 0;
    for (table) |entry| {
        cumilative += entry.weight;
        if (roll < cumilative) return entry.kind;
    }
    unreachable;
}

fn randomCard(rand: std.Random) !Card {
    const kind = weightedChoice(rand, &weights);

    const color: CardColor = switch (kind) {
        .WILD, .WILD4 => .WILDCOLOR,
        else => col: {
            while (true) {
                const currentColor = rand.enumValue(CardColor);
                if (currentColor != .WILDCOLOR)
                    break :col currentColor;
            }
        }
    };

    return switch (kind) {
        .NUMBER => try Card.init(color, .{ .NUMBER = rand.intRangeLessThan(u4, 0, 10) }),
        else => try Card.init(color, kind)
    };
}

pub const GameState = struct {
    players: ArrayList(Player),
    gameDirection: GameDirection,
    turn: usize,
    topCard: Card,

    pub fn init(allocator: Allocator, rand: std.Random) !GameState {
        return .{
            .players = try ArrayList(Player).initCapacity(allocator, 4),
            .gameDirection = .FORWARD,
            .turn = 0,
            .topCard = try randomCard(rand),
        };
    }

    pub fn deinit(self: *GameState, allocator: Allocator) void {
        for (self.players.items) |*p| {
            p.deinit(allocator);
        }
        self.players.deinit(allocator);
    }

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
            // TODO: Choose random names from a list
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

    pub fn printGameStates(self: GameState) void {
        std.debug.print("Current state: \ndirection : {any}\nTop Card : {any}, Turn : {any}, \nPlayers : {any}\n", .{ self.gameDirection, self.topCard, self.turn, self.players });
    }

    pub fn changeTopCard(self: *GameState, card: Card) void {
        self.topCard = card;
    }
};

test "memory leak" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));
}

test "random choice" {
    var rng = std.Random.DefaultPrng.init(2);
    const rand = rng.random();
    std.debug.print("random choice: {any}\n", .{weightedChoice(rand, &weights)});
}

test "random Card" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const card = try randomCard(rand);

    std.debug.print("random card: {any}\n", .{card});
}

test "test 1000 times" {
    for (0..100000) |_| {
        const time: i128 = std.time.nanoTimestamp();
        const bitTime: u128 = @bitCast(time);
        const seed: u64 = @truncate(bitTime);
        var rng = std.Random.DefaultPrng.init(seed);

        const rand = rng.random();
        const card = try randomCard(rand);
        _ = card;
    }
    // std.debug.print("Passed 100000 times", .{});
}

test "print" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));
    game.printGameStates();
}

test "changed top card" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    const card = try Card.init(.GREEN, .SKIP);
    game.changeTopCard(card);
    const topCard = game.topCard;

    try expect(switch (card.value) {
        .NUMBER => |an| switch (topCard.value) {
            .NUMBER => |bn| an == bn,
            else => unreachable,
        },
        .SKIP, .REVERSE, .DRAW2, .WILD, .WILD4 => true,
    });
    try expect(card.color == topCard.color);
}
