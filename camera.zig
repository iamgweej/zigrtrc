const std = @import("std");

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

    pub fn init(lookfrom: *const Point, lookat: *const Point, vup: *const Vec3, vfov: f64, aspect_ratio: f64) Self {
        const theta = (vfov / 180) * std.math.pi;
        const h = std.math.tan(theta / 2);
        const viewport_height = 2.0 * h;
        const viewport_width = aspect_ratio * viewport_height;

        const w = lookfrom.subbed(lookat).normalize();
        const u = vec3.cross(vup, &w).normalize();
        const v = vec3.cross(&w, &u);

        const origin = lookfrom.*;
        const horizontal = u.scaled(viewport_width);
        const vertical = v.scaled(viewport_height);
        const lower_left_corner = origin.subbed(&horizontal.scaled(0.5)).subbed(&vertical.scaled(0.5)).subbed(&w);

        return Self{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = lower_left_corner,
        };
    }

    pub fn getRay(self: *const Self, s: f64, t: f64) Ray {
        return Ray.new(&self.origin, &self.lower_left_corner.added(&self.horizontal.scaled(s)).added(&self.vertical.scaled(t)).subbed(&self.origin));
    }
};
