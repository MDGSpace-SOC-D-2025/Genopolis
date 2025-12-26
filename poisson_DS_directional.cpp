#include <vector>
#include <random>
#include <cmath>
#include<iostream>
using namespace std;

// We're using float in this code instead pf double because engines like godot use float internally, precision of float is enough for the game, double would cost more memory

struct Vec2
{
    float x, y;
};

// To generate random int or float
float randf(std::mt19937 &rng, float a, float b)
// using & so same generator used everytime
{
    uniform_real_distribution<float> dist(a, b);
    return dist(rng);
}

int randi(mt19937 &rng, int a, int b)
{
    uniform_int_distribution<int> dist(a, b);
    return dist(rng);
}

// To generate an angle close to 0, 90, 180 or 270
float sample_biased_angle(mt19937 &rng, float angleSpreadDeg)
{
    static const float PI = 3.14159265f;
    // Array storing the base angles
    static const float baseAngles[4] = {
        0.0f,
        PI / 2.0f,
        PI,
        3.0f * PI / 2.0f};

    // Pick one direction
    int base = randi(rng, 0, 3);

    // Convert angle from degrees to radians
    float spreadRad = angleSpreadDeg * (PI / 180.0f);

    float offset = randf(rng, -spreadRad, spreadRad);

    return baseAngles[base] + offset;
}

// To check if a newly generated point doesn't follow the min dist rule.
bool too_close(const Vec2 &p, const vector<Vec2> &points, float minDist)
{
    for (const auto &q : points)
    {
        float dx = p.x - q.x;
        float dy = p.y - q.y;
        if ( (dx * dx + dy * dy) < (minDist * minDist) )
            return true;
    }
    return false;
}

vector<Vec2> poisson_biased
   (int width,
    int height,
    float minDist,
    int k, // no. of iterations for checking around a point
    int seed,
    float angleSpreadDeg)
{
    mt19937 rng(seed);

    vector<Vec2> points; // accepted points
    vector<Vec2> active; // points that can still spawn neighbors

    // Initial random point
    Vec2 first
    {
        randf(rng, 0.0f, (float)width),
        randf(rng, 0.0f, (float)height)
    };

    points.push_back(first);
    active.push_back(first);

    while (!active.empty())
    {
        // A random active point is being picked
        int idx = randi(rng, 0, (int)active.size() - 1);
        Vec2 center = active[idx];

        bool found = false;

        // We will try k times to place a new point around it
        for (int i = 0; i < k; i++)
        {
            float angle = sample_biased_angle(rng, angleSpreadDeg);
            float radius = randf(rng, minDist, 2.0f * minDist);

            Vec2 candidate
            {
                center.x + radius * cos(angle),
                center.y + radius * sin(angle)
            };

            // Keep points inside the area of the city.
            if (candidate.x < 0 || candidate.x >= width ||
                candidate.y < 0 || candidate.y >= height)
                continue;

            // Enforce Poisson spacing
            if (!too_close(candidate, points, minDist))
            {
                points.push_back(candidate);
                active.push_back(candidate);
                found = true;
                break;
            }
        }
        if (!found)
        {
            active.erase(active.begin() + idx);
        }
    }
    return points;
}

int main()
{
    vector<Vec2> v;
    v = poisson_biased(1000, 1000, 1.0f, 20, 27, 10);
    for(auto i : v)
    cout << i.x << "  " << i.y << endl;
}