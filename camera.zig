const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");

const Vec3 = vec3.Vec3;
const Point = vec3.Point;

const Ray = ray.Ray;

pub const Camera = struct {
    origin: Point,
    lower_left_corner: Point,
    horizontal: Vec3,
    vertical: Vec3,

    const Self = @This();

    pub fn init() Self {
        comptime const ratio = 16.0 / 9.0;
        comptime const viewport_height = 2.0;
        comptime const viewport_width = ratio * viewport_height;
        comptime const focal_length = 1.0;

        const origin = Point.zero();
        const horizontal = Vec3.new(viewport_width, 0, 0);
        const vertical = Vec3.new(0, viewport_height, 0);

        return Self{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = origin.subbed(&horizontal.scaled(0.5)).subbed(&vertical.scaled(0.5)).subbed(&Vec3.new(0, 0, focal_length)),
        };
    }

    pub fn getRay(self: *const Self, u: f64, v: f64) Ray {
        return Ray.new(&self.origin, &self.lower_left_corner.added(&self.horizontal.scaled(u)).added(&self.vertical.scaled(v)).subbed(&self.origin));
    }
};
