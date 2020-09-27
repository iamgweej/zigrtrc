const std = @import("std");

pub inline fn randomFloatInRange(rnd: *std.rand.Random, comptime T: type, at_least: T, at_most: T) T {
    return at_least + (at_most - at_least) * rnd.float(T);
}
