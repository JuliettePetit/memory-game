const std = @import("std");

const Game = struct {
    cards: []u32,
    hidden: []bool,
    first_pick: ?usize = null,
    pairs_found: usize = 0,
};

var buf: [1024 * 1024]u8 = undefined; // 1MB
var fba = std.heap.FixedBufferAllocator.init(&buf);
const allocator = fba.allocator();

var prng = std.Random.DefaultPrng.init(0);
extern fn jsSeed() u64;

export fn seedRng() void {
    prng = std.Random.DefaultPrng.init(jsSeed());
}

fn initCards(nb: usize) ![]u32 {
    const nb_colors = nb / 2;

    var avail_colors: []usize = try allocator.alloc(usize, nb_colors);
    defer allocator.free(avail_colors);
    @memset(avail_colors, 2);

    var cards: []u32 = try allocator.alloc(u32, nb);
    var i: usize = 0;
    while (i < nb) : (i += 1) {
        var d: usize = prng.random().intRangeLessThan(usize, 0, nb_colors);
        while (avail_colors[d] == 0) {
            d = prng.random().intRangeLessThan(usize, 0, nb_colors);
        }
        cards[i] = @intCast(d);
        avail_colors[d] -= 1;
    }
    return cards;
}

export fn getCards(g: *Game) [*]u32 {
    return g.cards.ptr;
}

export fn getHiddenCards(g: *Game) [*]bool {
    return g.hidden.ptr;
}

export fn init(nb: usize) ?*Game {
    const g = allocator.create(Game) catch return null;
    g.* = Game{
        .cards = initCards(nb) catch {
            allocator.destroy(g);
            return null;
        },
        .hidden = allocator.alloc(bool, nb) catch {
            allocator.destroy(g);
            return null;
        },
    };
    @memset(g.hidden, true);
    return g;
}

/// 0 = no match
/// 1 = single
/// 2 = match
export fn selectCard(g: *Game, index: usize) i32 {
    if (g.first_pick != null) {
        const matched = flipCardIfMatching(g, index);
        if (matched) g.pairs_found += 1;
        g.first_pick = null;
        return if (matched) 2 else 0;
    } else g.first_pick = index;
    return 1;
}

fn flipCardIfMatching(g: *Game, index: usize) bool {
    const first = g.first_pick.?;
    if (g.cards[index] == g.cards[first]) {
        g.hidden[index] = false;
        g.hidden[first] = false;
        return true;
    }
    return false;
}

fn gameEnd(g: *Game) bool {
    for (g.cards) |card| {
        if (card.hidden) {
            return false;
        }
    }
    return true;
}

fn getCardsNumber(g: *Game) usize {
    return g.cards.len;
}

fn getCardColor(card: u32) i32 {
    return card.color;
}

export fn delete(g: *Game) void {
    defer allocator.free(g.cards);
}
