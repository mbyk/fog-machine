//
//  Bresenham.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/2/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit

class Bresenham: NSObject {

    
    private func reverseResults(matrix: [(x:Int,y:Int)]) -> [(x:Int,y:Int)] {
        var results:[(x:Int,y:Int)] = []
        for (x,y) in matrix.reverse() {
            results.append((x, y))
        }
        return results
    }

    
    //Adopted from http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Java
    internal func findLine(var x1: Int, var y1: Int, x2: Int, y2: Int) -> [(x:Int,y:Int)] {
        
        var results:[(x:Int,y:Int)] = []
        let obsX = x1
        let obsY = y1
        
        // delta of exact value and rounded value of the dependant variable
        var d = 0;
        
        let dy = abs(y2 - y1);
        let dx = abs(x2 - x1);
        
        let dy2 = (dy << 1); // slope scaling factors to avoid floating
        let dx2 = (dx << 1); // point
        
        let ix = x1 < x2 ? 1 : -1; // increment direction
        let iy = y1 < y2 ? 1 : -1;
        
        if (dy <= dx) {
            for (;;) {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
                }
                if (x1 == x2) {
                    break;
                }
                x1 += ix;
                d += dy2;
                if (d > dx) {
                    y1 += iy;
                    d -= dx2;
                }
            }
        } else {
            for (;;) {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
               }
                if (y1 == y2) {
                    break;
                }
                y1 += iy;
                d += dx2;
                if (d > dy) {
                    x1 += ix;
                    d -= dy2;
                }
            }
        }
        
        //dump(results)
        
        return results
    }
    
    
}