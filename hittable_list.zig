const std = @import("std");

const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable_module = @import("./hittable.zig");

const Allocator = std.mem.Allocator;
const HittableArrayList = std.ArrayList(*const Hittable);

const Vec3 = vec3.Vec3;
const Point = vec3.Point;

const Ray = ray.Ray;

const Hittable = hittable_module.Hittable;
const HitRecord = hittable_module.HitRecord;

pub const HittableList = struct {
    objects: HittableArrayList,
    hittable: Hittable,

    const Self = @This();

    pub fn hit(hittable: *const Hittable, r: *const Ray, t_min: f64, t_max: f64) ?HitRecord {
        const self = @fieldParentPtr(Self, "hittable", hittable);

        var rec: ?HitRecord = null;
        var closest_so_far = t_max;

        for (self.objects.items) |object| {
            if (object.hit(r, t_min, closest_so_far)) |new_rec| {
                rec = new_rec;
                closest_so_far = new_rec.t;
            }
        }

        return rec;
    }

    pub fn new(allocator: *Allocator) Self {
        return Self{
            .objects = HittableArrayList.init(allocator),
            .hittable = Hittable{ .hitFn = hit },
        };
    }

    pub fn add(self: *Self, object: *const Hittable) !void {
        try self.objects.append(object);
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }
};
