#include <vector>
#include <cmath>
#include <limits>
#include<iostream>
using namespace std;

struct Vec2
{
    float x, y;
};

struct Triangle
{
    Vec2 a, b, c;
};

float orient(const Vec2 &a, const Vec2 &b, const Vec2 &c)
{
    return ((b.x - a.x) * (c.y - a.y)) - ((b.y - a.y) * (c.x - a.x));
}
/* orient tells you which way three points turn.
Given points A → B → C: are they turning left, right, or are they collinear?
return value:
> 0 → counter-clockwise
< 0 → clockwise
= 0 → straight line */

bool in_circumcircle(const Triangle &t, const Vec2 &p)
// Is point p inside triangle t?
{
    float ax = t.a.x - p.x;
    float ay = t.a.y - p.y;
    float bx = t.b.x - p.x;
    float by = t.b.y - p.y;
    float cx = t.c.x - p.x;
    float cy = t.c.y - p.y;

    float det =
        (ax * ax + ay * ay) * (bx * cy - by * cx) -
        (bx * bx + by * by) * (ax * cy - ay * cx) +
        (cx * cx + cy * cy) * (ax * by - ay * bx);

    return det > 0; // det>0 - point is inside, remove triangle
}

struct Edge
{
    Vec2 a, b;
};

bool is_equal_edge(const Edge &e1, const Edge &e2)
{
    return ((e1.a.x == e2.a.x && e1.a.y == e2.a.y &&
             e1.b.x == e2.b.x && e1.b.y == e2.b.y) ||
            (e1.a.x == e2.b.x && e1.a.y == e2.b.y &&
             e1.b.x == e2.a.x && e1.b.y == e2.a.y));
}
/* Edges are undirected. The function checks same ordered and reverse ordered
Let's say we add a new point, and corresponding to the new point, two adjacent triangles are getting removed, ABC and ABD. Now, since btoh triangles are bad, the edges AC, BC, AD, BD will get removed once, but the edge AB is getting removed twice. That's why we have to make this function
So later we remove duplicate edges and keep only boundary edges, which form the hole.*/

vector<Triangle> delaunay_triangulation(const vector<Vec2> &points)
{
    vector<Triangle> triangles;

    // --- Step 1: Super triangle ---
    float INF = 1e5f;
    Vec2 p1 = {-INF, -INF};
    Vec2 p2 = {INF, -INF};
    Vec2 p3 = {0, INF};

    triangles.push_back({p1, p2, p3});

    // --- Step 2: Insert points one by one ---
    for (const Vec2 &p : points)
    {
        vector<Edge> polygon;
        vector<Triangle> new_tris;

        // Find triangles to remove
        for (const Triangle &t : triangles)
        {
            if (in_circumcircle(t, p))
            {
                polygon.push_back({t.a, t.b});
                polygon.push_back({t.b, t.c});
                polygon.push_back({t.c, t.a});
            }
            else
            {
                new_tris.push_back(t);
            }
        }

        // Remove duplicate edges (internal edges)
        vector<Edge> boundary;
        for (size_t i = 0; i < polygon.size(); i++)
        {
            bool shared = false;
            for (size_t j = 0; j < polygon.size(); j++)
            {
                if (i != j && polygon[i] == polygon[j])
                {
                    shared = true;
                    break;
                }
            }
            if (!shared)
                boundary.push_back(polygon[i]);
        }

        // Re-triangulate the hole
        for (const Edge &e : boundary)
        {
            new_tris.push_back({e.a, e.b, p});
        }

        triangles = new_tris;
    }

    // --- Step 3: Remove triangles connected to super triangle ---
    vector<Triangle> result;
    for (const Triangle &t : triangles)
    {
        if (t.a.x > -INF / 2 && t.b.x > -INF / 2 && t.c.x > -INF / 2)
            result.push_back(t);
    }

    return result;
}
