use <curvedPipe.scad>
use <utilities.scad>
// Set the number of objects that make a curve to 64
$fn = 64;

// ========================================================== //
// Variables
lickspout_tube_inner_diameter = 2.5; // in mm. Refers to ensure tube
lickspout_tube_wall = 1; // in mm. Refers to ensure tube
lickspout_offset = [-1, 0, -3]; // in mm

base_tube_diameter = 12.0; // in mm. Tested, should be 12.0
base_tube_arm_diameter = 7.0; // in mm
base_tube_wall = 1; // in mm. Refers to base tube

curvefn = 64; // Set to 128 for printing, 64 for modeling
// ========================================================== //


    





// ---------------------------------------------------------------------
// slipTip creates a male or female tip to accept an Ensure tube. Male
// ends don't work particularly well, so I suggest female. This function
// adds the tip onto the end of the tube, appropriately positioning and
// rotating it.
//  p1 is the point at which the tip should start
//  v1 is a point that makes a vector along which the tip should point
//  Set female to false to allow it to accept a 3.1 mm OD tube.

module slipTip(p1, v1, female=False) {
     // Tip for sliding the tubing on
    translate(p1) {
        u = p1 - v1;
        v = [0, 0, 1];
        // Basic linear algebra. Calculate the angle to move to
        rotate(a=angleBetweenVectors(v, u), v=cross(v, u)) {
            if (female) {
                // Female: make a cylinder with an ID of 3.4 mm
                difference() {
                    cylinder(r=3.4/2 + 1, h=5);
                    translate([0, 0, -1])
                    cylinder(r=3.4/2, h=8);
                }
            }
            else {
                // Male: make a cone with an ID of 1.2 mm
                difference() {
                    union() {
                        cylinder(h=2, r=3.7/2.0);
                        translate([0, 0, 2]) {
                            cylinder(r1=3.7/2.0, r2=1.2/2.0, h=5);
                        }
                    }
                    translate([0, 0, -1]) {
                        cylinder(h=12, r1=1.7/2.0, r2=1.2/2.0);
                    }
                }
            }
        }
    }   
}

// ---------------------------------------------------------------------
// lickspoutPipe makes a pipe for the lickspout (essentially, a tube to
// contain Ensure, water, or quinine). This depends on the curvedPipe
// library.
//  od is the outer diameter of the pipe
//  id is the inner diameter
//  passes female onto slipTip. If female, then it makes a female 
//      acceptor of 3.1mm OD tubing
//  di sets the distance between tubes near the tip, based on the
//      diameter of the tubing. Ignore usually, but can be useful for 
//      testing whether another object intrudes into the lickspout tube
//  end sets whether a tubing acceptor should be added to the end

module lickspoutPipe(od, id, female=false, di=-1, end=1) {
    di = di < 0 ? (od - id)/2.0 + id/2.0 : di;
    
    pipe = [
        [-4, 0, 0],
        [0, 0, 0],
        [5, di, 0],
        [20, 4, 0],
        [20, 4, 8],
    ];
    
    translate([0, 0, 0] - pipe[0]) {
        union() {
            curvedPipe(pipe, len(pipe) - 1, [10, 10, 5, 4, 6], od, id, fn=curvefn);
            if (end > 0) {
                slipTip(pipe[len(pipe) - 1], pipe[len(pipe) - 2], female);
        }
    }
    }
}

// ---------------------------------------------------------------------
// Combine a lickspout tube with the necessary support structure
//  od is outer diameter of Ensure tubing
//  id is inner diameter of Ensure tubing
//  female sets whether tubing acceptor is male or female. Passed to 
//      slipTip

module halfLickspout(od, id, female=false) {
    union() {
        difference() {
            lickspoutPipe(od, id, female);
            
            cubesize = 30;
            translate([-1, -cubesize, -cubesize/2.0])
            cube(cubesize);
        }
    }
}

// ---------------------------------------------------------------------
// Create an entire lickspout from two lickspout halves and a lickspout
// arm. 
//  od is outer diameter of Ensure tubing
//  id is inner diameter of Ensure tubing
//  female sets whether tubing acceptor is male or female. Passed to 
//      slipTip

module lickspout(od, id, female=false) {
    union() {
        // Translation necessary because we've sharpened the tip
        translate([-1, 0, od/2.0])
        difference() {
            // Add two halves together
            union() {
                halfLickspout(od, id, female);
                mirror([0, 1, 0])
                halfLickspout(od, id, female);
            }
            
            // And subtract the tip
            rotate([0, -35, 0])
            translate([-2, -15, -2.5])
            cube(20);
        }
        
        // Add a cube to hold the two arms together
        translate([22, -1.5, 0]) {
            translate([-.5, -0.5 - (od - id)/4.0, 0])
            cube([3, 4 + (od - id)/2.0, 10]);
        }
        
        // And add the lickspout arm
        lickspoutArm(od, id);
    }
}

// ---------------------------------------------------------------------
// Create the arm portion of the replaceable lickspout. The same
// function generates a slightly larger version that can be subtracted
// from the superstructure
//  od is outer diameter of Ensure tubing
//  id is inner diameter of Ensure tubing
//  subtract lets you decide whether the object is to be subtracted from
//      superstructure (true) or not (false)

module lickspoutArm(od, id, subtract=false) {
    translate([22, -1.5, 0]) {
        // Make size changes dependent on subtraction
        cubewidth = subtract ? 3.5 : 3;
        holderrad = subtract ? 6.3 : 6.0;
        
        // MAYBE CHANGE HEIGHT HERE
        cube([23, cubewidth, 3]);
        
        translate([26, 1.5, 0])
        if (subtract == false) {
            // Add the hole for an 8-32 bolt
            difference() {
                cylinder(r=holderrad, h=3);
                translate([0, 0, -1])
                cylinder(r=4.35/2.0, h=5);
            }
        }
        else {
            // Obviously, the hole is unnecessary
            cylinder(r=holderrad, h=3);
        }
        
        // Add a pretty little polygon so that Christian can't break it
        linear_extrude(3)
        translate([2.5, 1.5])
        polygon([[0, -2 - (od - id)/4.0], [0, 2 + (od - id)/4.0], [3, 1.5], [3, -1.5]]);
    }
}

module ledHolder(od, wall) {
    rotate([-90, 0, 0]) {
        translate([0, 0, 4]) {
            difference() {
                cylinder(r=od/2.0, h=6);
                translate([0, 0, -1])
                cylinder(r=od/2.0 - wall, h=8);
            }
        }

        // LED width is 4.7 mm. Let's try 5.2 mm
        difference() {
            cylinder(r=od/2.0, h=4);
            translate([0, 0, -1])
            cylinder(r=5.2/2.0, h=8);
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
            pipe(od, id, 3);
            translate([0, 0, -1])
            difference() {
                cylinder(r=id/2+0.3, h=5);
                translate([0, -od/2, -1])
                cube(od);
            }
        }
                
        translate([-1, -1, -od*2])
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
                [80, 0],
                [80, 28],
                [55, 33],
                [40, 18],
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

module posLEDholder(p1, led_holder_diameter, armd, wall, rotation_angle) {
        // Right arm LED holder and extension
    rotate([0, 0, rotation_angle]) {
        difference() {
            translate([0, p1-10, led_holder_diameter/2 - 1])
            union() {
                ledHolder(10, wall);
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
            
            translate([-10, p1-11, 10 - wall*2])
            cube([20, 40, 20]);
            
            // End tube
            translate([-30, 40, -5])
            cube(40);
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
                [55, 33],
                [40, 18],
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
                pipe(based, based-wall*2, 80);
            }
            
            translate([50, -150, -75])
            cube(150);
        }
        
        translate([77, 0, 0])
        halfStickRing(armd + 2, armd - 0.2);
        
        
        translate([50, 20, 0])
        rotate([0, 0, -45])
        halfStickRing(armd + 2, armd - 0.2);
    }
}

module supportStructure(od, id, based, armd, wall) {
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
                lickspoutArm(od, id, true);
                
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

module armCenter(armd, wall, rotation_angle) {
    translate([0, 0, armd/2]) {
        curvedPipe([
            [-sin(rotation_angle)*30, 30, 0],
            [40, 30, 0],
            [70, 0, 0],
            [80, 0, 0],
        ], 3, [10, 10, 10], armd - wall*2, 0, fn=curvefn);
    }
}

module base(od, id, based, armd, wall, rotation) {
    union() {
        rightArm(od, id, based, armd, wall, rotation);
        supportStructure(od, id, based, armd, wall);
        mirror([0, 1, 0]) {
            rightArm(od, id, based, armd, wall, -rotation);
            supportStructure(od, id, based, armd, wall);
        }
    }
}


fulldiameter = lickspout_tube_inner_diameter + 2*lickspout_tube_wall;

//lickspoutArm(fulldiameter, lickspout_tube_inner_diameter);
lickspout(fulldiameter, lickspout_tube_inner_diameter, female=true);

//hat(base_tube_arm_diameter, base_tube_wall);
base(fulldiameter, lickspout_tube_inner_diameter, base_tube_diameter, base_tube_arm_diameter, base_tube_wall, 25);
//armCenter(base_tube_arm_diameter, base_tube_wall, 25);
//supportStructure(fulldiameter, lickspout_tube_inner_diameter, base_tube_diameter, base_tube_arm_diameter, base_tube_wall);

//baseBottom(fulldiameter, lickspout_tube_inner_diameter, base_tube_diameter, base_tube_wall);
//baseTop(fulldiameter, lickspout_tube_inner_diameter, base_tube_diameter, base_tube_wall);
//baseBlock();
// Main should be 12.8mm in diameter with 3mm walls, 50 mm long