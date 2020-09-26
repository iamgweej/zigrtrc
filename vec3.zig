const std = @import("std");

pub const Vec3 = struct {
    p: [3]f64,

    const Self = @This();

    pub fn new(x_: f64, y_: f64, z_: f64) Self {
        return Self{ .p = [_]f64{ x_, y_, z_ } };
    }

    pub fn zero() Self {
        return Self{ .p = [_]f64{0} ** 3 };
    }

    pub inline fn x(self: *const Self) f64 {
        return self.p[0];
    }

    pub inline fn y(self: *const Self) f64 {
        return self.p[1];
    }

    pub inline fn z(self: *const Self) f64 {
        return self.p[2];
    }

    pub inline fn neg(self: *const Self) Self {
        return Self{ .p = [_]f64{ -self.p[0], -self.p[1], -self.p[2] } };
    }

    pub inline fn scaled(self: *const Self, t: f64) Self {
        return Self{ .p = [_]f64{ t * self.p[0], t * self.p[1], t * self.p[2] } };
    }

    pub inline fn added(self: *const Self, other: *const Self) Self {
        return Self{ .p = [_]f64{ self.p[0] + other.p[0], self.p[1] + other.p[1], self.p[2] + other.p[2] } };
    }

    pub inline fn subbed(self: *const Self, other: *const Self) Self {
        return Self{ .p = [_]f64{ self.p[0] - other.p[0], self.p[1] - other.p[1], self.p[2] - other.p[2] } };
    }

    pub inline fn norm(self: *const Self) f64 {
        return std.math.sqrt(self.normSquared());
    }

    pub inline fn normSquared(self: *const Self) f64 {
        return (self.p[0] * self.p[0]) + (self.p[1] * self.p[1]) + (self.p[2] * self.p[2]);
    }

    pub inline fn normalize(self: *const Self) Self {
        return self.scaled(1 / self.norm());
    }
};

pub const Point = Vec3;
pub const Color = Vec3;

const OutStream = std.io.OutStream(std.fs.File, std.os.WriteError, std.fs.File.write);

pub inline fn writeColor(out: *const OutStream, color: *const Color) !void {
    try out.print("{} {} {}\n", .{
        @floatToInt(i32, 255.999 * color.x()),
        @floatToInt(i32, 255.999 * color.y()),
        @floatToInt(i32, 255.999 * color.z()),
    });
}

pub inline fn dot(v: *const Vec3, u: *const Vec3) f64 {
    return (v.p[0] * u.p[0]) + (v.p[1] * u.p[1]) + (v.p[2] * u.p[2]);
}
