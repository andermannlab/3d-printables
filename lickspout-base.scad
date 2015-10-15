use <curvedPipe.scad>
use <utilities.scad>
use <lickspout-spout.scad>

// Set the number of objects that make a curve to 64
$fn = 64;

// ========================================================== //
// Variables
lickspout_tube_inner_diameter = 2.5; // in mm. Refers to ensure tube
lickspout_tube_wall = 1; // in mm. Refers to ensure tube
lickspout_offset = [-1, 0, -3]; // in mm

base_tube_diameter = 12.0; // in mm. Tested, should be 12.0
base_tube_arm_diameter = 7.0; // in mm
base_tube_wall = 1; // in mm. Refers to base tube. Doubled where held
                    // by Thorlabs piece

curvefn = 64; // Set to 128 for printing, 64 for modeling
// ========================================================== //


// ---------------------------------------------------------------------

module ledHolder(od, wall) {
    rotate([-90, 0, 0]) {
        translate([0, 0, 4]) {
            difference() {
                cylinder(r=od/2.0, h=6);
                translate([0, 0, -1])
                cylinder(r=od/2.0 - wall, h=8);
            }
        }

        // LED width is 4.7 mm. Tested. 5.2 is super tight. going 5.3 mm
        difference() {
            cylinder(r=od/2.0, h=4);
            translate([0, 0, -1])
            cylinder(r=5.5/2.0, h=8);
        }
    }
}

module ledPlug(led_holder_diameter, wall) {
    translate([0, -17, 1.25])
    union() {
        translate([-3, 17, -1.25])
        cube([6, 24, 1]);

        difference() {
            translate([0, 41, led_holder_diameter/2 - 1])
            rotate([90, 0, 0])
            cylinder(r=led_holder_diameter/2 - wall - 0.4, h=3);

             translate([-led_holder_diameter/2, 34.5, -8])
            rotate([45, 0, 0])
            cube(led_holder_diameter);
        }
        
        translate([0, 41, led_holder_diameter/2 - 1])
        rotate([90, 0, 0])
        cylinder(r=led_holder_diameter/2, h=1);
    }
}

module posLEDholder(p1, led_holder_diameter, armd, wall, rotation_angle) {
        // Right arm LED holder and extension
    rotate([0, 0, rotation_angle]) {
        difference() {
            translate([0, p1-10, led_holder_diameter/2 - 1])
            union() {
                ledHolder(10, wall);
                
                // Extend the ledHolder pipe
                translate([0, 30, 0])
                rotate([90, 0, 0])
                pipe(led_holder_diameter, led_holder_diameter - 2*wall, 20);
                
            }
            
            translate([0, 0, led_holder_diameter/2 - 1])
            
            translate([0, 30 + armd/2 - wall/2, -wall/2])
            rotate([0, 90, -rotation_angle])
            cylinder(r=armd/2 - wall, h=10);
            
            translate([-10, p1-11, -20])
            cube([20, 40, 20]);
            
            translate([-10, p1-11, 10 - wall*2 + 0.5])
            cube([20, 40, 20]);
            
            // End tube
            translate([-30, 40, -5])
            cube(40);
        }
    }
}

module stickRing(od, id) {
    // Fix the outer diameter so that it makes a wall at least 1mm thick
    od = od - id - 0.4 < 1 ? id + 1.4 : od;
    
    // Subtract the bottom edge
    difference() {
        // Rotate so that the thin part is on the top
        translate([0, 0, od/2 - (od-id)/2])
        rotate([0, 90, 0])
        difference() {
            pipe(od, id, 5);
            translate([0, 0, -1])
            difference() {
                cylinder(r=id/2+0.5, h=7);
                translate([0, -od/2, -1])
                cube(od);
            }
        }
                
        translate([-1, -1, -od*2])
        cube(od*2);
    }
}

module thickStickRing(od, id) {
    // Fix the outer diameter so that it makes a wall at least 1mm thick
    offset_mm = 1.0;
    thickness = 2.0;
    
    od = od - id - offset_mm < thickness ? id + thickness + offset_mm : od;
    
    // Subtract the bottom edge
    difference() {
        // Rotate so that the thin part is on the top
        translate([0, 0, od/2 - (od-id)/2])
        rotate([0, 90, 0])
        difference() {
            pipe(od, id, 6);
            translate([0, 0, -1])
            difference() {
                cylinder(r=id/2+0.5, h=8);
                translate([0, -od/2, -1])
                cube(od);
            }
        }
                
        translate([-1, -od, -od*2])
        cube(od*2);
    }
}

module halfStickRing(od, id) {
    difference() {
        stickRing(od, id);
        translate([-1, -od*2, -1])
        cube(od*2);
    }
}

module hat(armd, wall) {
    translate([0, 0, -armd/2])
    union() {
        rightArmTop(armd, wall);
        mirror([0, 1, 0])
        rightArmTop(armd, wall);
    }
}

module rightArmTop(armd, wall) {
    translate([0, 0, armd/2]) {
        intersection() {
            // Shape to remove top
            linear_extrude(10)
            polygon([
                [40, 0],
                [79.7, 0],
                [79.7, 28],
                [55, 23.7],
                [40, 23.7],
            ]);
            
             curvedPipe([
                [-14, 30, 0],
                [40, 30, 0],
                [70, 0, 0],
                [80, 0, 0],
            ], 3, [10, 10, 10], armd, armd - wall*2, fn=curvefn);
        }
    }
}

module rightArm(od, id, based, armd, wall, rotation_angle=25) {
    led_holder_diameter = 10;
    p1 = 25;
    p2 = 36;
    
    union() {
        // Thin right arm pipe
        difference() {
            // Arm pipe
            translate([0, 0, armd/2]) {
                curvedPipe([
                    [-sin(rotation_angle)*30, 30, 0],
                    [40, 30, 0],
                    [70, 0, 0],
                    [80, 0, 0],
                ], 3, [10, 10, 10], armd, armd - wall*2, fn=curvefn);
            }
            
            // Subset of LED holder pipe
            rotate([90, 0, rotation_angle])
            translate([0, led_holder_diameter/2+0.1-wall, -50])
            cylinder(r=led_holder_diameter/2 - wall, h=40);
        
            
            translate([50, -150, -75])
            cube(150);
            
            // Shape to remove top
            translate([0, 0, armd/2])
            linear_extrude(10)
            polygon([
                [40, -1],
                [80, -1],
                [80, 28],
                [55, 24],
                [40, 24],
            ]);
        }
        
        posLEDholder(p1, led_holder_diameter, armd, wall, rotation_angle);
        
        difference() {
            union() {
                translate([80, 0, armd/2])
                rotate([0, 90, 0])
                hullPipe(armd, based, -based/2 + armd/2, wall, 15);
                
                translate([95, 0, based/2])
                rotate([0, 90, 0])
                pipe(based, based-wall*4, 75);
            }
            
            translate([50, -150, -75])
            cube(150);
        }
        
        translate([50, 20, 0])
        rotate([0, 0, -45])
        halfStickRing(armd + 2, armd - 0.2);
    }
}

module supportStructure(spoutod, spoutid) {
    difference() {
        union() {
            difference() {
                linear_extrude(3)
                polygon([
                    [40, 26],
                    [66.5, 0],
                    [40, 0]
                ]);
                
                translate([0, 0, -1])
                scale([1, 1, 3])
                lickspoutArm(spoutod, spoutid, true);
                
                translate([0, 0, -1])
                linear_extrude(5)
                polygon([
                    [43, 20],
                    [52, 10],
                    [43, 10]
                ]);
            }
            
            translate([48, 0, 3])
            difference() {
                union() {
                    translate([-8, 0, 0])
                    cube([8, 8, 3]);
                    cylinder(r=8, h=3);
                    cube([4, 4, 4]);
                    
                    translate([0, 0, 3])
                    scale([1, 1, 0.5])
                    sphere(6);
                    
                    translate([0, 0, 2])
                    cylinder(r=4, h=4);
                }
                translate([0, 0, -1])
                cylinder(r=4.35/2.0, h=20);
                scale([1, 1, 0.5])
                sphere(6);
            }
        }

        translate([0, -200, -100])
        cube(200);
    }
}

module base(spoutod, spoutid, based, armd, wall, rotation) {
    union() {
        rightArm(spoutod, spoutid, based, armd, wall, rotation);
        supportStructure(spoutod, spoutid);
        mirror([0, 1, 0]) {
            rightArm(spoutod, spoutid, based, armd, wall, -rotation);
            supportStructure(spoutod, spoutid);
        }
        
        translate([75, 0, 0])
        thickStickRing(armd + 2, armd - 0.2);
    }
}


fulldiameter = lickspout_tube_inner_diameter + 2*lickspout_tube_wall;

//lickspout(fulldiameter, lickspout_tube_inner_diameter, female=true);
//hat(base_tube_arm_diameter, base_tube_wall);

base(fulldiameter, lickspout_tube_inner_diameter, base_tube_diameter, base_tube_arm_diameter, base_tube_wall, 25);

//unilicker(fulldiameter, lickspout_tube_inner_diameter, female=true);


//ledPlug(10, base_tube_wall);