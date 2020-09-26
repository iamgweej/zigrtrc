const math = @import("std").math;
const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable_module = @import("./hittable.zig");

const Vec3 = vec3.Vec3;
const Point = vec3.Point;

const Ray = ray.Ray;

const Hittable = hittable_module.Hittable;
const HitRecord = hittable_module.HitRecord;

pub const Sphere = struct {
    center: Point,
    radius: f64,
    hittable: Hittable,

    const Self = @This();

    inline fn buildHitRecord(self: *const Self, r: *const Ray, t: f64) HitRecord {
        const p = r.at(t);
        const outward_normal = p.subbed(&self.center).scaled(1 / self.radius);
        return HitRecord.fromOutwardNormal(&p, t, &outward_normal, &r.direction());
    }

    pub fn hit(hittable: *const Hittable, r: *const Ray, t_min: f64, t_max: f64) ?HitRecord {
        const self = @fieldParentPtr(Self, "hittable", hittable);
        const oc = r.origin().subbed(&self.center);
        const a = r.direction().normSquared();
        const half_b = vec3.dot(&oc, &r.direction());
        const c = oc.normSquared() - self.radius * self.radius;
        const discriminant = half_b * half_b - a * c;

        if (discriminant > 0) {
            const root = math.sqrt(discriminant);

            const first_time = (-half_b - root) / a;
            if (first_time < t_max and first_time > t_min) {
                return self.buildHitRecord(r, first_time);
            }
            const second_time = (-half_b + root) / a;
            if (second_time < t_max and second_time > t_min) {
                return self.buildHitRecord(r, second_time);
            }
        }

        return null;
    }

    pub fn new(center: *const Point, radius: f64) Self {
        return Self{
            .center = center.*,
            .radius = radius,
            .hittable = Hittable{ .hitFn = hit },
        };
    }
};
