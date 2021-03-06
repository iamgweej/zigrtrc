const std = @import("std");

const util = @import("./util.zig");

pub const Vec3 = struct {
    p: [3]f64,

    const Self = @This();

    pub fn new(x_: f64, y_: f64, z_: f64) Self {
        return Self{ .p = [_]f64{ x_, y_, z_ } };
    }

    pub fn zero() Self {
        return Self{ .p = [_]f64{0} ** 3 };
    }

    pub inline fn random(rnd: *std.rand.Random) Self {
        return Self.new(rnd.float(f64), rnd.float(f64), rnd.float(f64));
    }

    pub inline fn randomInBox(rnd: *std.rand.Random, min: f64, max: f64) Self {
        return Self.new(
            util.randomFloatInRange(rnd, f64, min, max),
            util.randomFloatInRange(rnd, f64, min, max),
            util.randomFloatInRange(rnd, f64, min, max),
        );
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

    pub inline fn add(self: *Self, other: *const Self) void {
        self.p[0] += other.p[0];
        self.p[1] += other.p[1];
        self.p[2] += other.p[2];
    }

    pub inline fn added(self: *const Self, other: *const Self) Self {
        return Self{ .p = [_]f64{ self.p[0] + other.p[0], self.p[1] + other.p[1], self.p[2] + other.p[2] } };
    }

    pub inline fn subbed(self: *const Self, other: *const Self) Self {
        return Self{ .p = [_]f64{ self.p[0] - other.p[0], self.p[1] - other.p[1], self.p[2] - other.p[2] } };
    }

    pub inline fn multiplied(self: *const Self, other: *const Self) Self {
        return Self{ .p = [_]f64{ self.p[0] * other.p[0], self.p[1] * other.p[1], self.p[2] * other.p[2] } };
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

inline fn clamp(x: f64, min: f64, max: f64) f64 {
    if (x < min) {
        return min;
    }
    if (x > max) {
        return max;
    }
    return x;
}

pub inline fn writeColor(out: *const OutStream, color: *const Color, samples_per_pixel: i32) !void {
    const scale = 1.0 / @intToFloat(f64, samples_per_pixel);
    const g = std.math.sqrt(scale * color.y());
    const r = std.math.sqrt(scale * color.x());
    const b = std.math.sqrt(scale * color.z());

    try out.print("{} {} {}\n", .{
        @floatToInt(i32, 256 * clamp(r, 0.0, 0.999)),
        @floatToInt(i32, 256 * clamp(g, 0.0, 0.999)),
        @floatToInt(i32, 256 * clamp(b, 0.0, 0.999)),
    });
}

pub inline fn dot(v: *const Vec3, u: *const Vec3) f64 {
    return (v.p[0] * u.p[0]) + (v.p[1] * u.p[1]) + (v.p[2] * u.p[2]);
}

pub inline fn cross(u: *const Vec3, v: *const Vec3) Vec3 {
    return Vec3.new(
        u.p[1] * v.p[2] - u.p[2] * v.p[1],
        u.p[2] * v.p[0] - u.p[0] * v.p[2],
        u.p[0] * v.p[1] - u.p[1] * v.p[0],
    );
}

pub fn reflect(v: *const Vec3, n: *const Vec3) Vec3 {
    return v.subbed(&n.scaled(2 * dot(v, n)));
}

pub fn refract(uv: *const Vec3, n: *const Vec3, etai_over_etat: f64) Vec3 {
    const cos_theta = -dot(uv, n);
    const r_out_perp = uv.added(&n.scaled(cos_theta)).scaled(etai_over_etat);
    const r_out_parallel = n.scaled(-std.math.sqrt(std.math.fabs(1 - r_out_perp.normSquared())));
    return r_out_perp.added(&r_out_parallel);
}

pub fn randomUnitVector(rnd: *std.rand.Random) Vec3 {
    const a = util.randomFloatInRange(rnd, f64, 0, 2 * std.math.pi);
    const z = util.randomFloatInRange(rnd, f64, -1, 1);
    const r = std.math.sqrt(1 - z * z);
    return Vec3.new(r * std.math.cos(a), r * std.math.sin(a), z);
}

pub fn randomUnitSphereVector(rnd: *std.rand.Random) Vec3 {
    const r = util.randomFloatInRange(rnd, f64, 0, 1);
    return randomUnitVector(rnd).scaled(r);
}

pub fn randomInUnitDisk(rnd: *std.rand.Random) Vec3 {
    const r_squared = rnd.float(f64);
    const r = std.math.sqrt(r_squared);
    const a = util.randomFloatInRange(rnd, f64, 0, 2 * std.math.pi);
    return Vec3.new(r * std.math.cos(a), r * std.math.cos(a), 0);
}
