#include <vector>
#include <algorithm>
#include <cmath>
#include <map>
using namespace std;

bool cmp(vector<float> &a, vector<float> &b)
{
    return a[2] < b[2];
}

struct Vec2
{
    float x, y;
};

struct Triangle
{
    int a, b, c;
};

pair<int, int> makeEdgeSame(int u, int v)
{
    if(u>v)
    swap(u, v);
    return {u, v};
}
// (2,5) and (5,2) -> same edge

float distanceWeight(const Vec2 &p1, const Vec2 &p2)
{
    float dx = p1.x - p2.x;
    float dy = p1.y - p2.y;
    return sqrt(dx*dx + dy*dy);
}

vector<vector<float>> extractEdges(const vector<Triangle> &triangles,
                                        const vector<Vec2> &points)
{
    // When delaunay triangulation is done, the edges the boundary of the city appear to close and useless, so to fix that, we are removing the edges that aren't shared by 2 triangles.

    // count how many times each edge appears
    map<pair<int, int>, int> edgeCount;

    for (const Triangle &t : triangles)
    {
        edgeCount[makeEdgeSame(t.a, t.b)]++;
        edgeCount[makeEdgeSame(t.b, t.c)]++;
        edgeCount[makeEdgeSame(t.c, t.a)]++;
    }

    vector<vector<float>> edges;

    for (const auto &it : edgeCount)
    {
        if (it.second == 2)
        {
            int u = it.first.first;
            int v = it.first.second;

            float wt = distanceWeight(points[u], points[v]);

            edges.push_back({(float)u, (float)v, wt});
        }
    }

    return edges;
}

void makeSet(vector<int> &parent, vector<int> &rank, int n)
{
    for (int i = 0; i < n; i++)
    {
        parent[i] = i;
        rank[i] = 0;
    }
}

int findParent(vector<int> &parent, int node)
{
    if (parent[node] == node)
        return node;

    return parent[node] = findParent(parent, parent[node]);
}

void unionSet(int u, int v, vector<int> &parent, vector<int> &rank)
{
    u = findParent(parent, u);
    v = findParent(parent, v);

    if (rank[u] < rank[v])
        parent[u] = v;
    else if (rank[u] > rank[v])
        parent[v] = u;
    else
    {
        parent[v] = u;
        rank[u]++;
    }
}

vector<vector<float>> minimumSpanningTree(vector<vector<float>> &edges, int n)
{
    sort(edges.begin(), edges.end(), cmp);

    vector<int> parent(n), rank(n);
    makeSet(parent, rank, n);

    vector<vector<float>> mstEdges;

    for (int i = 0; i < edges.size(); i++)
    {
        int u = (int)edges[i][0];
        int v = (int)edges[i][1];
        float wt = edges[i][2];

        int pu = findParent(parent, u);
        int pv = findParent(parent, v);

        if (pu != pv)
        {
            mstEdges.push_back({(float)u, (float)v, wt});
            unionSet(pu, pv, parent, rank);
        }
    }

    return mstEdges;
}

int final_implementation(const vector<Triangle> &triangles,
                         const vector<Vec2> &points)
{
    vector<vector<float>> edges = extractEdges(triangles, points);
    // store all the edges, and don't cpnvert to MST yet, as some of these will be added as secondary roads later.

    vector<vector<float>> mst = minimumSpanningTree(edges, points.size());
}