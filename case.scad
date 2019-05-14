include<milkysway/geometry/2d/extended_primitives.scad>;
include<milkysway/geometry/3d/extended_primitives.scad>;
include<milkysway/geometry/3d/grip_studs.scad>;
include<milkysway/geometry/3d/polystrut_3d.scad>;
include<milkysway/geometry/3d/threads.scad>;
include<milkysway/operators/transform_hull.scad>;

wall_thickness        = 3;
thin_wall_thickness   = 1;
tessalation_tolerance = 0.3;

corner_radius = 3;

inner_width  = 92;
inner_height = 62;
inner_depth  = 55;

window_width     = 72.5;
window_height    = 20;
window_thickness = 0.2;
window_taper     = 6;
window_z_offset  = window_taper / 2 + wall_thickness;

seal_diameter             = 3;
seal_taper_height         = 18;
seal_turn_radius          = 12;
seal_compression_distance = 2.5;
seal_inset_width          = max(seal_diameter + tessalation_tolerance * 2 + thin_wall_thickness * 2 - wall_thickness, 0.001);
seal_path_width           = inner_width + seal_diameter + tessalation_tolerance * 2 + thin_wall_thickness * 2;
seal_path_depth           = inner_depth + seal_diameter + tessalation_tolerance * 2 + thin_wall_thickness * 2;

case_max_width = seal_path_width + thin_wall_thickness * 2 + tessalation_tolerance * 2 + seal_diameter;
case_max_depth = seal_path_depth + thin_wall_thickness * 2 + tessalation_tolerance * 2 + seal_diameter;

bolt_mount_taper_height = 30;

bolt_head_height = 5;

grip_stud_depth = 1;
num_grip_studs  = 20;

thread_length   = 5;
thread_diameter = 10;

lid_thickness = wall_thickness + bolt_head_height + tessalation_tolerance;

mount_hole_diameter = 5;
mount_height        = inner_height * 0.7;
mount_taper_height  = mount_hole_diameter + wall_thickness;

$fa = 30;
$fn = 360 / $fa;

body();
*lid();
*bolt();
*assemble();

module bolt()
{
    cylinder(d = thread_diameter + wall_thickness * 2 - grip_stud_depth * 2, h = bolt_head_height);
    grip_studs(num_grip_studs, grip_stud_depth, thread_diameter + wall_thickness * 2 - grip_stud_depth * 2, bolt_head_height);
    translate([0, 0, bolt_head_height])
        cylinder(d = thread_diameter, h = lid_thickness + tessalation_tolerance);
    translate([0, 0, bolt_head_height + lid_thickness + tessalation_tolerance])
        threads_fff(outer_diameter = thread_diameter, length = thread_length, countersink = "top");
}

module assemble()
{
    body();
    translate([0, 0, inner_height + wall_thickness + tessalation_tolerance])
        lid();
    translate([0, 0, inner_height + wall_thickness * 2 + tessalation_tolerance * 2 + bolt_head_height])
        let(bolt_x_offset = case_max_width / 2 + thread_diameter / 2 + wall_thickness + tessalation_tolerance)
        rotate([180, 0, 0])
        {
            translate([bolt_x_offset, 0, 0])
                bolt();
            translate([-bolt_x_offset, 0, 0])
                bolt();
        }
}

module lid()
{
    difference()
    {
        linear_extrude(height = lid_thickness)
        {
            offset(r = seal_inset_width)
                case_shape();
            lid_bolt_mount_shape();
            rotate([0, 0, 180])
                lid_bolt_mount_shape();
        }
        translate([case_max_width / 2, 0, wall_thickness])
            cube(999, orient_y = ORIENT_CENTRE);
        translate([-case_max_width / 2, 0, wall_thickness])
            cube(999, orient_x = ORIENT_NEGATIVE, orient_y = ORIENT_CENTRE);
        translate([
            -seal_path_width / 2 + seal_turn_radius,
            -seal_path_depth / 2 + seal_turn_radius,
            -seal_compression_distance / 2
        ])
            polystrut_3d(points = seal_path(), d = seal_diameter + tessalation_tolerance * 2, $fa = $fa * 3);
    }
}

module body()
{
    difference()
    {
        union()
        {
            cube(
                [
                    inner_width + wall_thickness * 2,
                    inner_depth + wall_thickness * 2,
                    inner_height + wall_thickness * 2
                ],
                orient_x = ORIENT_CENTRE,
                orient_y = ORIENT_CENTRE,
                cr = corner_radius
            );
            translate([0, 0, inner_height + wall_thickness - seal_taper_height])
                transform_hull(translate = [0, 0, seal_taper_height], translate_easing = EASE_OUT_IN, $fa = $fa * 5)
                {
                    case_shape();
                    offset(r = seal_inset_width)
                        case_shape();
                }
            translate([0, 0, inner_height + wall_thickness - thread_length])
            {
                bolt_mount();
                rotate([0, 0, 180])
                    bolt_mount();
            }
            bolt_mount_taper();
            rotate([0, 0, 180])
                bolt_mount_taper();
        }
        translate([0, 0, wall_thickness])
            cube([inner_width, inner_depth, 999], orient_x = ORIENT_CENTRE, orient_y = ORIENT_CENTRE);
        translate([0, 0, inner_height + wall_thickness])
            cylinder(d = 999, h = 999);
        translate([0, -inner_depth / 2 + 0.01, window_z_offset + window_height / 2])
            rotate([90, 0, 0])
            linear_extrude(height = wall_thickness + 0.02, scale = [window_taper / window_width + 1, window_taper / window_height + 1])
            square([window_width, window_height], center = true, cr = min(window_width, window_height) / 2 - 0.001);
        translate([
            -seal_path_width / 2 + seal_turn_radius,
            -seal_path_depth / 2 + seal_turn_radius,
            inner_height + wall_thickness + seal_compression_distance / 2
        ])
            polystrut_3d(points = seal_path(), d = seal_diameter + tessalation_tolerance * 2, $fa = $fa * 3);
    }

    mount();
    mirror([1, 0, 0])
        mount();

    window_support();
    mirror([1, 0, 0])
        window_support();

    difference()
    {
        intersection()
        {
            translate([
                -seal_path_width / 2 + seal_turn_radius,
                -seal_path_depth / 2 + seal_turn_radius,
                inner_height + wall_thickness + seal_compression_distance / 2
            ])
                polystrut_3d(points = seal_path(), d = seal_diameter + tessalation_tolerance * 2 + thin_wall_thickness * 2, $fa = $fa * 3);
            translate([0, 0, wall_thickness])
                cube([inner_width, inner_depth, inner_height], orient_x = ORIENT_CENTRE, orient_y = ORIENT_CENTRE);
        }
        translate([
            -seal_path_width / 2 + seal_turn_radius,
            -seal_path_depth / 2 + seal_turn_radius,
            inner_height + wall_thickness + seal_compression_distance / 2
        ])
            polystrut_3d(points = seal_path(), d = seal_diameter + tessalation_tolerance * 2, $fa = $fa * 3);
    }

    module window_support()
    {
        translate([inner_width / 2, -inner_depth / 2 + window_thickness + tessalation_tolerance * 2, wall_thickness])
            cube([(inner_width - window_width) / 2, wall_thickness, window_height + window_taper], orient_x = ORIENT_NEGATIVE);
    }

    module bolt_mount_taper()
    {
        translate([0, 0, inner_height + wall_thickness - bolt_mount_taper_height - thread_length])
            transform_hull(translate = [0, 0, bolt_mount_taper_height], translate_easing = EASE_OUT_IN, translate_easing_exponent = 1.3, $fa = $fa * 5)
            {
                translate([-thread_diameter - seal_diameter - thin_wall_thickness * 2 + wall_thickness, 0, 0])
                    offset(r = -thread_diameter * 0.8)
                    bolt_mount_shape();
                bolt_mount_shape();
            }
    }
}

module case_shape()
{
    square([inner_width + wall_thickness * 2, inner_depth + wall_thickness * 2], center = true, cr = corner_radius);
}

module bolt_mount(with_threads)
{
    diameter = thread_diameter + tessalation_tolerance * 2 + wall_thickness * 2;
    difference()
    {
        linear_extrude(height = thread_length)
            bolt_mount_shape();
        if(true)
        {
            translate([case_max_width / 2 + diameter / 2, 0, 0])
                threads_fff(outer_diameter = thread_diameter + tessalation_tolerance * 2, length = thread_length);
        }
    }
}

module bolt_mount_shape()
{
    diameter = thread_diameter + tessalation_tolerance * 2 + wall_thickness * 2;
    translate([case_max_width / 2    + diameter / 2, 0, 0])
    {
        square([diameter, diameter], orient_y = ORIENT_CENTRE, orient_x = ORIENT_NEGATIVE);
        circle(d = diameter);
    }
}

module lid_bolt_mount_shape()
{
    difference()
    {
        bolt_mount_shape();
        translate([
            case_max_width / 2 + thread_diameter / 2 + tessalation_tolerance + wall_thickness,
            0,
            0
        ])
            circle(d = thread_diameter + tessalation_tolerance * 2);
    }
}

module mount()
{
    diameter = mount_hole_diameter + wall_thickness * 2;
    translate([inner_width / 2 + diameter / 2, inner_depth / 2 + wall_thickness - corner_radius - diameter / 2, (inner_height + wall_thickness - mount_height) / 2])
    difference()
    {
        cylinder(d = diameter, h = mount_height);
        cylinder(d = mount_hole_diameter, h = 999);
        taper();
        translate([0, 0, mount_height])
            mirror([0, 0, 1])
            taper();
    }

    module taper()
    {
        translate([diameter / 2, 0, 0])
            linear_extrude(height = mount_taper_height, scale = [0.0001, 1])
            square([diameter, diameter], orient_x = ORIENT_NEGATIVE, orient_y = ORIENT_CENTRE);
    }
}

function seal_path() =
    let(
        dx = seal_path_width - seal_turn_radius * 2,
        dy = seal_path_depth - seal_turn_radius * 2
    )
    concat(
            seal_path_corner([0, 0], 2),
            seal_path_corner([dx, 0], 3),
            seal_path_corner([dx, dy], 0),
            seal_path_corner([0, dy], 1),
            [[-seal_turn_radius, 0, 0]]
    );

function seal_path_corner(offset = [0, 0], quadrant = 0) =
    [
        for(a = [quadrant * 90 : $fa : quadrant * 90 + 90])
            [cos(a) * seal_turn_radius + offset[0], sin(a) * seal_turn_radius + offset[1], 0]
    ];