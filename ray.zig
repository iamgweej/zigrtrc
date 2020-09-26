const vec3 = @import("./vec3.zig");

const Point = vec3.Point;
const Vec3 = vec3.Vec3;

pub const Ray = struct {
    orig: Point,
    dir: Vec3,

    const Self = @This();

    pub fn new(orig: *const Point, dir: *const Vec3) Self {
        return Self{
            .orig = orig.*,
            .dir = dir.*,
        };
    }

    pub fn at(self: *const Self, t: f64) Point {
        return self.orig.added(&self.dir.scaled(t));
    }

    pub inline fn origin(self: *const Self) Point {
        return self.orig;
    }

    pub inline fn direction(self: *const Self) Vec3 {
        return self.dir;
    }
};
