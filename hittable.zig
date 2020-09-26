const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");

const Vec3 = vec3.Vec3;
const Point = vec3.Point;

const Ray = ray.Ray;

pub const HitRecord = struct {
    p: Point,
    normal: Vec3,
    t: f64,
    front_face: bool,

    const Self = @This();

    pub fn fromOutwardNormal(p: *const Point, t: f64, outwardNormal: *const Vec3, direction: *const Vec3) Self {
        const front_face = vec3.dot(direction, outwardNormal) < 0;
        return Self{
            .p = p.*,
            .normal = if (front_face) outwardNormal.* else outwardNormal.neg(),
            .t = t,
            .front_face = front_face,
        };
    }
};

pub const Hittable = struct {
    hitFn: fn (self: *const Self, r: *const Ray, t_min: f64, t_max: f64) ?HitRecord,

    const Self = @This();

    pub inline fn hit(self: *const Self, r: *const Ray, t_min: f64, t_max: f64) ?HitRecord {
        return self.hitFn(self, r, t_min, t_max);
    }
};
