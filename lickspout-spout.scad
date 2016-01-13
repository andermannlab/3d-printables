use <utilities.scad>
use <curvedPipe.scad>

// Set the number of objects that make a curve to 64
$fn = 128;

// ========================================================== //
// Variables
lickspout_tube_inner_diameter = 2.5; // in mm. Refers to ensure tube
lickspout_tube_wall = 1; // in mm. Refers to ensure tube
lickspout_offset = [-1, 0, -3]; // in mm

curvefn = 128; // Set to 128 for printing, 64 for modeling
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
        translate([1, 1.5])
        polygon([[0, -2 - (od - id)/4.0], [0, 2 + (od - id)/4.0], [3, 1.5], [3, -1.5]]);
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
/*    intersection() {
        translate([5.5, 0.25, -1])
        rotate([90, 0, 0])
        cylinder(r=5, h=1);
        
        translate([2, 1, 5])
        rotate([90, 0, 0])
        cylinder(r=5, h=2);
        
        translate([0, -2.5, 0])
        cube(5.5);
    }
  */  
        
    union() {
        // Translation necessary because we've sharpened the tip
        translate([-1, 0, od/2.0])
        difference() {
            // Add two halves together
            translate([-1.5, 0, 0])
            union() {
                halfLickspout(od, id, female);
                mirror([0, 1, 0])
                halfLickspout(od, id, female);
                
                translate([2.5, -0.4, -od/2.0])
                cube([5, 0.8, 5]);
            }
            
            // And subtract the tip
            rotate([0, -50, 0])
            translate([-2, -15, -2.5])
            cube(20);
            
            translate([-15, -10, 0])
            cube(20);
            
            translate([3, 0, 1.55])
            // And subtract the tip
            rotate([0, -50, 0])
            translate([0, -15, -2.5])
            cube(20);
            
            translate([-20, -10, -5])
            cube(20);
        }
        
        // Add a cube to hold the two arms together
        translate([20.5, -1.5, 0]) {
            translate([-.5, -0.5 - (od - id)/4.0, 0])
            cube([3, 4 + (od - id)/2.0, 10]);
        }
        
        // And add the lickspout arm
        lickspoutArm(od, id);
    }
}

module uniLickspoutPipe(od, id, female=true, di=-1, end=true) {
    di = di < 0 ? (od - id)/2.0 + id/2.0 : di;
    
    pipe = [
        [-4, 0, 0],
        [0, 0, 0],
        [20, 0, 0],
        [20, 0, 8],
    ];
    
    translate([0, 0, 0] - pipe[0]) {
        union() {
            curvedPipe(pipe, len(pipe) - 1, [10, 10, 5, 4], od, id, fn=curvefn);
            if (end) {
                slipTip(pipe[len(pipe) - 1], pipe[len(pipe) - 2], female);
            }
        }
    }
}

module unilicker(od, id, female=true) {
   

    
    union() {
        translate([1.5, 0, 3])
        difference() {
            translate([-0.2, 0, -0.5])
            sphere(2.7);
            
            translate([-2.5, -2.5, -8])
            cube(5);
            
            translate([-0.5, 0, 0])
            sphere(2.1);
            translate([-5, -5, -1.5])
            cube(10);
            
            translate([0, 0, id/2 - 2])
            rotate([0, 90, 0])
            cylinder(r=id/2, h=10);
        }
        
        translate([-1, 0, od/2.0])
        difference() {
            // Add two halves together
            
            uniLickspoutPipe(od, id);
            
            // And subtract the tip
            rotate([0, -35, 0])
            translate([-2, -15, -2.5])
            cube(20);
        }

        translate([23, od/2, 0])
        rotate([90, -90, 0])
        linear_extrude(od)
        polygon([
            [0, 0],
            [6, 0],
            [0, 7]
        ]);
        
        lickspoutArm(od, id);
    }
}

fulldiameter = lickspout_tube_inner_diameter + 2*lickspout_tube_wall;

lickspout(fulldiameter, lickspout_tube_inner_diameter, female=true);
//unilicker(fulldiameter, lickspout_tube_inner_diameter);