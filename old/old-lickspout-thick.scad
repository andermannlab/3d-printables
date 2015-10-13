use <curvedPipe.scad>
$fn = 64;

// ========================================================== //
// Variables
tube_inner_diameter = 2.5; // in mm. Refers to ensure tube
tube_wall_thickness = 1; // in mm. Refers to ensure tube
lickspout_offset = [-1, 0, -3]; // in mm
base_tube_wall_thickness = 1; // in mm. Refers to base tube
base_tube_diameter = 12.0; // in mm. Tested, should be 12.0
curvefn = 128; // Set to 128 for printing, 64 for modeling
// ========================================================== //


// ---------------------------------------------------------------------
// Back to basic math. This is the dot product of two vectors normalized
// to unit length. Takes two 3D vectors, u and v
function angleBetweenVectors(u, v) =
    acos((u*v)/(sqrt(u[0]*u[0] + u[1]*u[1] + u[2]*u[2])*sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])));
    
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

        // LED width is 4.7 mm. Let's try 5.4 mm
        difference() {
            cylinder(r=od/2.0, h=4);
            translate([0, 0, -1])
            cylinder(r=5.4/2.0, h=8);
        }
    }
}

module baseHalf(od, id, based, wall) {
    difference() {
        union() {
            translate([0, 0, based/2]) {
                translate([0, 15, 0])
                ledHolder(based, wall);
                
                curvedPipe([
                    [0, 25, 0],
                    [0, 34, 0],
                    [40, 34, 0],
                    [70, 0, 0],
                    [120, 0, 0],
                ], 4, [10, 10, 10, 10], based, based - wall*2, fn=curvefn);
            }
            difference() {
                linear_extrude(3)
                polygon([
                    [40, 30],
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

module base(od, id, based, wall) {
    union() {
        baseHalf(od, id, based, wall);
        mirror([0, 1, 0])
        baseHalf(od, id, based, wall);
    }
}

module copy_mirror(vec=[0,1,0]) { 
    children(); 
    mirror(vec) children(); 
}

// ---------------------------------------------------------------------
// baseBlock is s set of shapes that can be subtracted or intersected
// with the lickspout base to form the top and bottom. Because the
// printer is imperfect in its positioning, we're making it so that the
// block can be slightly expanded (by 0.2 mm in each direction) so that
// the two pieces mesh perfectly.

//  based is the diameter of the base tube (meant to match a 12.8 mm 
//  diameter thorlabs tube)
//  expand expands the blocks by 0.2 mm in each important direction

module baseBlock(based, expand=false) {
    outward = expand ? 25.2 : 25;
    backward = expand ? 18.2 : 18;
    
    difference() {
        union() {
            translate([-10, outward, based/2])
            cube(30);
            translate([-10, -outward-30, based/2])
            cube(30);
            translate([backward, -50, based/2])
            cube([60, 100, 30]);
        }
        
        copy_mirror([0, 1, 0])
        translate([0, 0, -1])
        linear_extrude(100)
        polygon([
            [40, 23],
            [59, 0],
            [40, -1]
        ]);
    }
}

module baseBottom(od, id, based, wall) {
    difference() {
        base(od, id, based, wall);
        baseBlock(based);
    }
}

module baseTop(od, id, based, wall) {
    translate([0, 0, -based/2])
    intersection() {
        base(od, id, based, wall);
        baseBlock(based, true);
    }
}


fulldiameter = tube_inner_diameter + 2*tube_wall_thickness;

//lickspoutArm(fulldiameter, tube_inner_diameter);
//lickspout(fulldiameter, tube_inner_diameter, female=true);
//baseBottom(fulldiameter, tube_inner_diameter, base_tube_diameter, base_tube_wall_thickness);
baseTop(fulldiameter, tube_inner_diameter, base_tube_diameter, base_tube_wall_thickness);
//baseBlock();
// Main should be 12.8mm in diameter with 3mm walls, 50 mm long