const std = @import("std");

const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable = @import("./hittable.zig");
const sphere = @import("./sphere.zig");
const hittable_list = @import("./hittable_list.zig");
const material = @import("./material.zig");
const camera = @import("./camera.zig");

const Point = vec3.Point;
const Color = vec3.Color;
const Vec3 = vec3.Vec3;

const Ray = ray.Ray;

const Hittable = hittable.Hittable;
const Sphere = sphere.Sphere;
const HittableList = hittable_list.HittableList;

const Lambertian = material.Lambertian;
const Metal = material.Metal;

const Camera = camera.Camera;

var rnd: std.rand.DefaultPrng = undefined;

fn rayColor(r: *const Ray, world: *const Hittable, depth: i32) Color {
    if (depth <= 0) {
        return Color.new(0, 0, 0);
    }

    if (world.hit(r, 0.001, std.math.inf(f64))) |hit_record| {
        if (hit_record.mat.scatter(r, &hit_record)) |scatter_record| {
            return rayColor(&scatter_record.scattered, world, depth - 1).multiplied(&scatter_record.attenuation);
        }
        return Color.new(0, 0, 0);
    }

    comptime const base1 = Color.new(1.0, 1.0, 1.0);
    comptime const base2 = Color.new(0.5, 0.7, 1.0);

    const unit_direction = r.direction().normalize();
    const t2 = 0.5 * (unit_direction.y() + 1.0);
    return base1.scaled(1.0 - t2).added(&base2.scaled(t2));
}

pub fn main() !void {
    const stdout = std.io.getStdOut().outStream();
    const stderr = std.io.getStdErr().outStream();
    rnd = std.rand.DefaultPrng.init(std.time.timestamp());

    // Image
    comptime const ratio = 16.0 / 9.0;
    comptime const width: i32 = 400;
    comptime const width_float = @intToFloat(f64, width);
    comptime const height = @floatToInt(i32, width_float / ratio);
    comptime const height_float = @intToFloat(f64, height);
    comptime const samples_per_pixel = 100;
    comptime const max_depth = 50;

    // Camera
    const cam = Camera.init();

    // World
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const material_ground = Lambertian.init(&Color.new(0.8, 0.8, 0.0), &rnd.random);
    const material_center = Lambertian.init(&Color.new(0.7, 0.3, 0.3), &rnd.random);
    const material_left = Metal.init(&Color.new(0.8, 0.8, 0.8));
    const material_right = Metal.init(&Color.new(0.8, 0.6, 0.2));

    const center = Sphere.new(&Point.new(0, 0, -1), 0.5, &material_center.material);
    const ground = Sphere.new(&Point.new(0, -100.5, -1), 100, &material_ground.material);
    const left = Sphere.new(&Point.new(-1.0, 0.0, -1.0), 0.5, &material_left.material);
    const right = Sphere.new(&Point.new(1.0, 0.0, -1.0), 0.5, &material_right.material);

    var world = HittableList.new(allocator);
    try world.add(&center.hittable);
    try world.add(&ground.hittable);
    try world.add(&right.hittable);
    try world.add(&left.hittable);

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ width, height });

    var j: i32 = height - 1;

    while (j >= 0) : (j -= 1) {
        try stderr.print("\rScanlines remaining: {} ", .{j});

        var i: i32 = 0;
        while (i < width) : (i += 1) {
            var color = Color.zero();
            var s: i32 = 0;
            while (s < samples_per_pixel) : (s += 1) {
                const u = (@intToFloat(f64, i) + rnd.random.float(f64)) / (width_float - 1.0);
                const v = (@intToFloat(f64, j) + rnd.random.float(f64)) / (height_float - 1.0);
                const r = cam.getRay(u, v);
                color.add(&rayColor(&r, &world.hittable, max_depth));
            }
            try vec3.writeColor(&stdout, &color, samples_per_pixel);
        }
    }
    try stderr.print("\nDone\n", .{});
}
