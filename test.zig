const std = @import("std");

const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable = @import("./hittable.zig");
const sphere = @import("./sphere.zig");
const hittable_list = @import("./hittable_list.zig");

const Point = vec3.Point;
const Color = vec3.Color;
const Vec3 = vec3.Vec3;

const Ray = ray.Ray;

const Hittable = hittable.Hittable;
const Sphere = sphere.Sphere;
const HittableList = hittable_list.HittableList;

fn ray_color(r: *const Ray, world: *const Hittable) Color {
    if (world.hit(r, 0, std.math.inf(f64))) |record| {
        return record.normal.added(&Color.new(1, 1, 1)).scaled(0.5);
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

    // Image
    comptime const ratio = 16.0 / 9.0;
    comptime const width: i32 = 400;
    comptime const widthFloat = @intToFloat(f64, width);
    comptime const height = @floatToInt(i32, widthFloat / ratio);
    comptime const heightFloat = @intToFloat(f64, height);

    // World
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const sphere1 = Sphere.new(&Point.new(0, 0, -1), 0.5);
    const sphere2 = Sphere.new(&Point.new(0, -100.5, -1), 100);

    var world = HittableList.new(allocator);
    try world.add(&sphere1.hittable);
    try world.add(&sphere2.hittable);

    // Camera
    comptime const viewport_height = 2.0;
    comptime const viewport_width = ratio * viewport_height;
    comptime const focal_length = 1.0;

    comptime const origin = Point.zero();
    comptime const horizontal = Vec3.new(viewport_width, 0, 0);
    comptime const vertical = Vec3.new(0, viewport_height, 0);
    comptime const lower_left_corner = origin.subbed(&horizontal.scaled(0.5)).subbed(&vertical.scaled(0.5)).subbed(&Vec3.new(0, 0, focal_length));

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ width, height });

    var j: i32 = height - 1;

    while (j >= 0) : (j -= 1) {
        try stderr.print("\rScanlines remaining: {} ", .{j});

        var i: i32 = 0;
        while (i < width) : (i += 1) {
            const u = @intToFloat(f64, i) / (widthFloat - 1.0);
            const v = @intToFloat(f64, j) / (heightFloat - 1.0);
            const direction = lower_left_corner.added(&horizontal.scaled(u)).added(&vertical.scaled(v)).subbed(&origin);
            const r = Ray.new(&origin, &direction);
            const color = ray_color(&r, &world.hittable);
            try vec3.write_color(&stdout, &color);
        }
    }
    try stderr.print("\nDone\n", .{});
}
