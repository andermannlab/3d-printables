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