const std = @import("std");

const vec3 = @import("./vec3.zig");
const ray = @import("./ray.zig");
const hittable = @import("./hittable.zig");

const Color = vec3.Color;

const Ray = ray.Ray;

const HitRecord = hittable.HitRecord;

pub const ScatterRecord = struct {
    attenuation: Color,
    scattered: Ray,
};

pub const Material = struct {
    scatterFn: fn (self: *const Self, r_in: *const Ray, rec: *const HitRecord) ?ScatterRecord,

    const Self = @This();

    pub inline fn scatter(self: *const Self, r_in: *const Ray, rec: *const HitRecord) ?ScatterRecord {
        return self.scatterFn(self, r_in, rec);
    }
};

pub const Lambertian = struct {
    albedo: Color,
    material: Material,
    rnd: *std.rand.Random,

    const Self = @This();

    pub fn scatter(material: *const Material, r_in: *const Ray, rec: *const HitRecord) ?ScatterRecord {
        const self = @fieldParentPtr(Self, "material", material);
        const scatter_direction = rec.normal.added(&vec3.randomUnitVector(self.rnd));
        return ScatterRecord{ .scattered = Ray.new(&rec.p, &scatter_direction), .attenuation = self.albedo };
    }

    pub fn init(a: *const Color, rnd: *std.rand.Random) Self {
        return Self{
            .albedo = a.*,
            .material = Material{ .scatterFn = scatter },
            .rnd = rnd,
        };
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64,
    material: Material,
    rnd: *std.rand.Random,

    const Self = @This();

    pub fn scatter(material: *const Material, r_in: *const Ray, rec: *const HitRecord) ?ScatterRecord {
        const self = @fieldParentPtr(Self, "material", material);
        const reflected = vec3.reflect(&r_in.direction().normalize(), &rec.normal);
        const scattered = Ray.new(&rec.p, &reflected.added(&vec3.randomUnitSphereVector(self.rnd).scaled(self.fuzz)));
        if (vec3.dot(&scattered.direction(), &rec.normal) > 0) {
            return ScatterRecord{ .scattered = scattered, .attenuation = self.albedo };
        }
        return null;
    }

    pub fn init(a: *const Color, fuzz: f64, rnd: *std.rand.Random) Self {
        return Self{
            .albedo = a.*,
            .fuzz = if (fuzz < 1) fuzz else 1,
            .material = Material{ .scatterFn = scatter },
            .rnd = rnd,
        };
    }
};

fn schlick(cosine: f64, ref_idx: f64) f64 {
    const r0 = (1 - ref_idx) / (1 + ref_idx);
    const r0_sqaured = r0 * r0;
    return r0_sqaured + (1 - r0_sqaured) * std.math.pow(f64, 1 - cosine, 5);
}

pub const Dielectric = struct {
    ref_idx: f64,
    material: Material,
    rnd: *std.rand.Random,

    const Self = @This();

    pub fn scatter(material: *const Material, r_in: *const Ray, rec: *const HitRecord) ?ScatterRecord {
        const self = @fieldParentPtr(Self, "material", material);

        const attenuation = Color.new(1, 1, 1);
        const etai_over_etat = if (rec.front_face) (1.0 / self.ref_idx) else self.ref_idx;
        const unit_direction = r_in.direction().normalize();

        const cos_theta = std.math.min(-vec3.dot(&unit_direction, &rec.normal), 1.0);
        const sin_theta = std.math.sqrt(1 - cos_theta * cos_theta);
        if (etai_over_etat * sin_theta > 1.0 or self.rnd.float(f64) < schlick(cos_theta, etai_over_etat)) {
            return ScatterRecord{
                .attenuation = attenuation,
                .scattered = Ray.new(&rec.p, &vec3.reflect(&unit_direction, &rec.normal)),
            };
        }

        const refracted = vec3.refract(&unit_direction, &rec.normal, etai_over_etat);
        return ScatterRecord{
            .attenuation = attenuation,
            .scattered = Ray.new(&rec.p, &refracted),
        };
    }

    pub fn init(ref_idx: f64, rnd: *std.rand.Random) Self {
        return Self{
            .ref_idx = ref_idx,
            .material = Material{ .scatterFn = scatter },
            .rnd = rnd,
        };
    }
};
