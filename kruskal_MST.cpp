#include <vector>
#include <algorithm>
#include <cmath>

struct Vec2
{
    float x, y;
};

struct Edge
{
    int u;
    int v;
    float w;

    bool operator<(const Edge &other) const
    {
        return w < other.w;
    }
};

struct DSU
{
    std::vector<int> parent, rank;

    DSU(int n)
    {
        parent.resize(n);
        rank.resize(n, 0);
        for (int i = 0; i < n; i++)
            parent[i] = i;
    }

    int find(int x)
    {
        if (parent[x] != x)
            parent[x] = find(parent[x]);
        return parent[x];
    }

    bool unite(int a, int b)
    {
        a = find(a);
        b = find(b);
        if (a == b)
            return false;

        if (rank[a] < rank[b])
            parent[a] = b;
        else if (rank[a] > rank[b])
            parent[b] = a;
        else
        {
            parent[b] = a;
            rank[a]++;
        }
        return true;
    }
};

std::vector<Edge> kruskal_mst(int num_points, std::vector<Edge> &edges)
{
    std::vector<Edge> mst;
    std::sort(edges.begin(), edges.end());
    DSU dsu(num_points);

    for (const Edge &e : edges)
    {
        if (dsu.unite(e.u, e.v))
        {
            mst.push_back(e);

            if ((int)mst.size() == num_points - 1)
                break;
        }
    }
    return mst;
}
