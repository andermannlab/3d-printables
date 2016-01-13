$fa = 0.1;

// ---------------------------------------------------------------------
// Back to basic math. This is the dot product of two vectors normalized
// to unit length. Takes two 3D vectors, u and v

function angleBetweenVectors(u, v) =
    acos((u*v)/(sqrt(u[0]*u[0] + u[1]*u[1] + u[2]*u[2])*sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])));

// ---------------------------------------------------------------------
// Make a cylinder within another cylinder
//  od is outer diameter
//  id is inner diameter
//  h is height

module pipe(od, id, h) {
    difference() {
        cylinder(r=od/2, h=h);
        translate([0, 0, -1])
        cylinder(r=id/2, h=h+2);
    }
}

// ---------------------------------------------------------------------
// Make a tube from two different circles, offset in x
//  topd is top diameter
//  based is bottom diameter
//  transx is the shift in x
//  wall is the thickness
//  h is the height

module hullPipe(topd, based, transx, wall, h) {
    difference() {
        // Make the outer shape
        hull() {
            cylinder(r=topd/2, h=1);
            translate([transx, 0, h])
            cylinder(r=based/2, h=1);
        }
        
        // Make the inner shape
        hull() {
            translate([0, 0, -h/100])
            cylinder(r=topd/2 - wall, h=1);
            translate([transx, 0, h + h/100])
            cylinder(r=based/2 - wall, h=1);
        }
    }
}

// ---------------------------------------------------------------------
// Transform: make a copy of an object and mirror across the X axis

module copy_mirror(vec=[0,1,0]) { 
    children();
    mirror(vec) children(); 
}

module copy_move(vec=[0, 0, 0]) {
    children();
    translate(vec) children();
}

module copy_rotate(angle, vec=[0, 0, 1]) {
    children();
    rotate(angle, vec) children();
}

// ---------------------------------------------------------------------
// Create a rounded rectangle (similar to cube, but with rounding radius

module rrect(sz, r=3) {
    w = sz[0];
    h = sz[1];
    d = sz[2];
    
    hull() {
        translate([r, r, 0])
        cylinder(r=r, h=d);
        
        translate([w-r, r, 0])
        cylinder(r=r, h=d);
        
        translate([w-r, h-r, 0])
        cylinder(r=r, h=d);
        
        translate([r, h-r, 0])
        cylinder(r=r, h=d);
        
        translate([r, r, 0])
        cube([w - r*2, h - r*2, d]);
    }
}

module rrect3(sz, r=3) {
    w = sz[0];
    h = sz[1];
    d = sz[2];
    
    hull() {
        copy_move([0, 0, d - 2*r]) {
            translate([r, r, r])
            sphere(r);
            
            translate([w-r, r, r])
            sphere(r);
            
            translate([w-r, h-r, r])
            sphere(r);
            
            translate([r, h-r, r])
            sphere(r);
        }
    }
}

// size is the XY plane size, height in Z
module hexagon(size, height) {
  boxWidth = size/1.75;
  for (r = [-60, 0, 60]) rotate([0,0,r]) cube([boxWidth, size, height], true);
}
