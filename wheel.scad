use <utilities.scad>

$fn = 256;

wheel_diameter = 14; // in cm
wheel_height = 6; // in cm
wheel_axle = 6; // diameter in mm

module beamXZ(p1, p2) {
    l = sqrt((p2[0] - p1[0])*(p2[0] - p1[0]) + (p2[1] - p1[1])*(p2[1] - p1[1]));
    theta = asin((p2[1] - p1[1])/l);
    
    translate([p1[0], 0, p1[1]])
    rotate([0, -theta, 0])
    translate([0.5, -1, 0])
    cube([l, 2, 2]);
}

module beam(p1, p2, plane="xz") {
    l = sqrt((p2[0] - p1[0])*(p2[0] - p1[0]) + (p2[1] - p1[1])*(p2[1] - p1[1]));
    theta = atan2(p2[1] - p1[1], p2[0] - p1[0]);
    
    translate(plane == "xz" ? [p1[0], 0, p1[1]] : plane == "xy" ? [p1[0], p1[1], 0] : [0, p1[0], p1[1]])
    rotate(plane == "xz" ? [0, -theta, 0] : plane == "xy" ? [0, 0, theta] : [-theta, 0, 0])
    translate([0.5, -1, 0])
    cube([l, 2, 2]);
}

module beam3d(p1, p2) {
    l = sqrt((p2[0] - p1[0])*(p2[0] - p1[0]) + (p2[1] - p1[1])*(p2[1] - p1[1]) + (p2[2] - p1[2])*(p2[2] - p1[2]));
    
    crs = cross(p1 - p2, [1, 0, 0]);
    translate(p1)    
    rotate(a=angleBetweenVectors(p1 - p2, [1, 0, 0]), v=crs)
    
    translate([0.5, -1, 0])
    cube([l, 2, 2]);
}

module rim(di, h) {
    pipe(di, di - 2, h);
    pipe(di, di - 6, 2);

    translate([0, 0, h - 5]) {
        difference() {
            pipe(di, di - 6, 5);
            cylinder(r1=di/2 - 1, r2= di/2 - 3, 3);
        }
    }
}

module arm(di, h, ax) {
    union() {
        translate([di/2 - 5, -1, 0])
        cube([4, 2, h]);
        
        translate([ax/2 + 0.5, -1, 0])
        cube([(di - ax)/2 - 1, 2, 2]);
        
        beam([ax/2, 0], [di/2 - 2, h - 2]);
        beam([ax/2, h - 2], [di/2 - 2, 0]);
        
        beam([di/4, 0], [di/2 - 2, h - 2]);
        beam([ax/2, h - 2], [di/4, 0]);
        
//        beam([ax/2, 0], [di/2 - 2, h/2]);
    }
}

module support(di, h, ax, narms) {
    diff = 360/narms;
    difference() {
        union() {
            cylinder(r=ax/2 + 3, h=h);
            
            translate([0, 0, h - 9])
            embeddedM4(ax);
             
            for (theta = [0:diff:359]) {
                rotate([0, 0, theta]) {
                    arm(di, h, ax);
                    beam3d([di/2*sin(0), di/2*cos(0), h], [di/4*sin(diff), di/4*cos(diff), 0]);
                    beam3d([0, (di/2 - 2), h/2], [3/8*di*sin(-diff), 3/8*di*cos(-diff), 0]);
                }
                
                 beam([3*di/8*sin(theta), 3*di/8*cos(theta)], [3*di/8*sin(theta+diff), 3*di/8*cos(theta+diff)], "xy");
            }
        }
        
        // Cube below 0 in z
        translate([-di, -di, -di*2])
        cube(di*2);
        
        // Cube above rim
        translate([-di, -di, h])
        cube(2*di);
        
        // Axle
        translate([0, 0, -1])
        cylinder(r=ax/2 + 0.3, h+2);

        // M4 bolt hole
        translate([0, 0, 6 + h - 9])
        rotate([0, 90, 0])
        cylinder(r=4.35/2.0, h=11);
        
        // M4 captive nut hole
        translate([ax/2 + 3.5/2 + 1, 0, 6 + h - 9])
        rotate([0, -90, 0])
        union() {
            hexagon(7.5, 3.5);
            translate([0, -7.5/2, -3.5/2])
            cube([10, 7.5, 3.5]);
        }
    }
    
}

module checkAxle(di, h, ax) {
    difference() {
        cylinder(r=ax/2 + 3, h=9);
        
        translate([0, 0, -1])
        cylinder(r=ax/2 + 0.3, 11);
    }
}

// size is the XY plane size, height in Z
module hexagon(size, height) {
  boxWidth = size/1.75;
  for (r = [-60, 0, 60]) rotate([0,0,r]) cube([boxWidth, size, height], true);
}

module embeddedM4(ax) {
    // center of nut at height 9
    union() {
        difference() {
            difference() {
                translate([0, -ax/2 - 3, 0])
                cube([7 + ax/2, ax + 6, 9]);
            
                translate([0, 0, -1])
                cylinder(r=ax/2 + 0.5, h=11);
            }
            
            translate([ax/2 + 3.5/2 + 1, 0, 6])
            rotate([0, -90, 0])
            union() {
                hexagon(7.5, 3.5);
                translate([0, -7.5/2, -3.5/2])
                cube([10, 7.5, 3.5]);
            }
            
            translate([0, 0, 6])
            rotate([0, 90, 0])
            cylinder(r=4.35/2.0, h=11);
        }
        
        translate([0, -ax/2 - 3, 0])
        rotate([-90, -90, 0])
        linear_extrude(ax + 6)
        polygon([[0, 0], [0, 7 + ax/2], [-7 - ax/2, 0]]);
    }
}

//rim(wheel_diameter*10, wheel_height*10);
support(wheel_diameter*10, wheel_height*10, wheel_axle, 8);
//
//difference() {
//    translate([0, 0, -9]) {
//    checkAxle(wheel_diameter*10, wheel_height*10, wheel_axle);
//        translate([wheel_axle/2 + 0.3, -5.5, 0])
//        cube([6, 11, 9]);
//    }
//
//    translate([wheel_axle/2 + 1.3 + 3.5/2, 0, -3])
//    embeddedM4();
//
//}
//embeddedM4(wheel_axle);
//checkAxle(wheel_diameter*10, wheel_height*10, wheel_axle);
