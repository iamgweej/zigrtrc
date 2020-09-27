const std = @import("std");

const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable = @import("./hittable.zig");
const sphere = @import("./sphere.zig");
const hittable_list = @import("./hittable_list.zig");
const material = @import("./material.zig");
const camera = @import("./camera.zig");
const util = @import("./util.zig");

const OutStream = std.io.OutStream(std.fs.File, std.os.WriteError, std.fs.File.write);

const Point = vec3.Point;
const Color = vec3.Color;
const Vec3 = vec3.Vec3;

const Ray = ray.Ray;

const Hittable = hittable.Hittable;
const Sphere = sphere.Sphere;
const HittableList = hittable_list.HittableList;

const Material = material.Material;
const Lambertian = material.Lambertian;
const Metal = material.Metal;
const Dielectric = material.Dielectric;

const Camera = camera.Camera;

var stdout: OutStream = undefined;
var stderr: OutStream = undefined;

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

fn randomScene(allocator: *std.mem.Allocator) !HittableList {
    const p = Point.new(4, 0.2, 0);
    const r = &rnd.random;

    var world = HittableList.new(allocator);

    const ground_material = try allocator.create(Lambertian);
    ground_material.* = Lambertian.init(&Color.new(0.5, 0.5, 0.5), r);

    const ground = try allocator.create(Sphere);
    ground.* = Sphere.new(&Point.new(0, -1000, 0), 1000, &ground_material.material);

    try world.add(&ground.hittable);

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = r.float(f64);

            const center = Point.new(
                @intToFloat(f64, a) + 0.9 * r.float(f64),
                0.2,
                @intToFloat(f64, b) + 0.9 * r.float(f64),
            );
            try stderr.print("Randomized center: {} {} {}\n", .{ center.x(), center.y(), center.z() });
            if (center.subbed(&p).norm() > 0.9) {
                try stderr.print("Center: {} {} {}\n", .{ center.x(), center.y(), center.z() });
                var sphere_material: *const Material = undefined;

                if (choose_mat < 0.8) {
                    // diffuse
                    const lambertian_ptr = try allocator.create(Lambertian);
                    lambertian_ptr.* = Lambertian.init(&Color.random(r), r);
                    sphere_material = &lambertian_ptr.material;
                } else if (choose_mat < 0.95) {
                    // metal
                    const metal_ptr = try allocator.create(Metal);
                    metal_ptr.* = Metal.init(
                        &Color.randomInBox(r, 0.5, 1),
                        util.randomFloatInRange(r, f64, 0, 0.5),
                        r,
                    );
                    sphere_material = &metal_ptr.material;
                } else {
                    // glass
                    const dielectric_ptr = try allocator.create(Dielectric);
                    dielectric_ptr.* = Dielectric.init(1.5, r);
                    sphere_material = &dielectric_ptr.material;
                }

                const small_sphere = try allocator.create(Sphere);
                small_sphere.* = Sphere.new(&center, 0.2, sphere_material);
                try world.add(&small_sphere.hittable);
            }
        }
    }

    //    auto material1 = make_shared<dielectric>(1.5);
    // world.add(make_shared<sphere>(point3(0, 1, 0), 1.0, material1));

    // auto material2 = make_shared<lambertian>(color(0.4, 0.2, 0.1));
    // world.add(make_shared<sphere>(point3(-4, 1, 0), 1.0, material2));

    // auto material3 = make_shared<metal>(color(0.7, 0.6, 0.5), 0.0);
    // world.add(make_shared<sphere>(point3(4, 1, 0), 1.0, material3));

    const material1 = try allocator.create(Dielectric);
    material1.* = Dielectric.init(1.5, r);
    const sphere1 = try allocator.create(Sphere);
    sphere1.* = Sphere.new(&Point.new(0, 1, 0), 1.0, &material1.material);
    try world.add(&sphere1.hittable);

    const material2 = try allocator.create(Lambertian);
    material2.* = Lambertian.init(&Color.new(0.4, 0.2, 0.1), r);
    const sphere2 = try allocator.create(Sphere);
    sphere2.* = Sphere.new(&Point.new(-4, 1, 0), 1.0, &material2.material);
    try world.add(&sphere2.hittable);

    const material3 = try allocator.create(Metal);
    material3.* = Metal.init(&Color.new(0.7, 0.6, 0.5), 0.0, r);
    const sphere3 = try allocator.create(Sphere);
    sphere3.* = Sphere.new(&Point.new(4, 1, 0), 1.0, &material3.material);
    try world.add(&sphere3.hittable);

    return world;
}

pub fn main() !void {
    stdout = std.io.getStdOut().outStream();
    stderr = std.io.getStdErr().outStream();
    rnd = std.rand.DefaultPrng.init(std.time.timestamp());

    // Image
    comptime const ratio = 3.0 / 2.0;
    comptime const width: i32 = 1200;
    comptime const width_float = @intToFloat(f64, width);
    comptime const height = @floatToInt(i32, width_float / ratio);
    comptime const height_float = @intToFloat(f64, height);
    comptime const samples_per_pixel = 500;
    comptime const max_depth = 50;

    // Camera
    const lookfrom = Point.new(13, 2, 3);
    const lookat = Point.new(0, 0, 0);
    const vup = Vec3.new(0, 1, 0);
    const dist_to_focus = 10.0;
    const aperture = 0.1;

    const cam = Camera.init(
        &lookfrom,
        &lookat,
        &vup,
        20.0,
        ratio,
        aperture,
        dist_to_focus,
        &rnd.random,
    );

    // World
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var world = try randomScene(allocator);

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
