const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const log = std.log.scoped(.cards);

pub const InitializationError = error{
    InvalidNumber,
    InvalidColor,
};

pub const CardColor = enum { RED, BLUE, GREEN, YELLOW, WILDCOLOR };

pub const CardType = union(enum) {
    NUMBER: u4,
    SKIP: void,
    REVERSE: void,
    DRAW2: void,
    WILD: void,
    WILD4: void,
};

pub const Card = struct {
    color: CardColor,
    value: CardType,

    pub fn init(color: CardColor, value: CardType) InitializationError!Card {
        switch (value) {
            .NUMBER => |n| {
                if (n > 9) return InitializationError.InvalidNumber;
                if (color == .WILDCOLOR) return InitializationError.InvalidColor;
            },
            .SKIP, .REVERSE, .DRAW2 => {
                if (color == .WILDCOLOR) return InitializationError.InvalidColor;
            },
            .WILD, .WILD4 => {
                if (color != .WILDCOLOR) return InitializationError.InvalidColor;
            }
        }

        return Card{
            .color = color,
            .value = value,
        };
    }
};

test "Tagged Union type check" {
    const ct = CardType.SKIP;
    try expect(@as(CardType, ct) == CardType.SKIP);

    const cn = CardType{ .NUMBER = 1 };
    try expect(@as(CardType, cn) == CardType.NUMBER);

    switch (cn) {
        .NUMBER => |value| try expect(value == 1),
        else => unreachable,
    }
}

test "Create Card" {
    const card = try Card.init(.RED, .SKIP);
    try expect(card.color == CardColor.RED);
    try expect(card.value == CardType.SKIP);
}

test "create faulty card" {
    try expectError(InitializationError.InvalidNumber, Card.init(.BLUE, .{ .NUMBER = 13 }));
    try expectError(InitializationError.InvalidColor, Card.init(.WILDCOLOR, .{ .NUMBER = 9 }));
    try expectError(InitializationError.InvalidColor, Card.init(.WILDCOLOR, .SKIP));
    try expectError(InitializationError.InvalidColor, Card.init(.BLUE, .WILD));
}
