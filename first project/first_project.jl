using LightGraphs
using GraphPlot
using RowEchelon
using Compose

const Vertexes = Int
const Edges = Int
const Power = Float32
const Resistance = Float32

struct Edge_Details
    source::Vertexes
    destination::Edges
    power::Power
    resistance::Resistance
end

#function from LightGraphs but for some reason it's not importing with "using" clause
function cycle_basis(g::Graph, root=nothing)
    gnodes = Set(vertices(g))
    cycles = Vector{Vector{eltype(g)}}()
    while !isempty(gnodes)
        if root == nothing
            root = pop!(gnodes)
        end
        stack = [root]
        pred = Dict(root => root)
        keys_pred = Set(root)
        used = Dict(root => [])
        keys_used = Set(root)
        while !isempty(stack)
            z = pop!(stack)
            zused = used[z]
            for nbr in neighbors(g,z)
                if !in(nbr, keys_used)
                    pred[nbr] = z
                    push!(keys_pred, nbr)
                    push!(stack,nbr)
                    used[nbr] = [z]
                    push!(keys_used, nbr)
                elseif nbr == z
                    push!(cycles, [z])
                elseif !in(nbr, zused)
                    pn = used[nbr]
                    cycle = [nbr,z]
                    p = pred[z]
                    while !in(p, pn)
                        push!(cycle, p)
                        p = pred[p]
                    end
                    push!(cycle,p)
                    push!(cycles,cycle)
                    push!(used[nbr], z)
                end
            end
        end
        setdiff!(gnodes,keys_pred)
        root = nothing
    end
    return cycles
end

#connects verteces{source, destination} with edges and sorts edges by index
function prepare_resources_from_graph(graph::Graph, edges_details::Array{Edge_Details,1})
    vertex_edge_map = Dict{Set{Vertexes}, Edges}()
    edges_sorted = Array{Edge_Details}(length(edges_details))

    for (index, edge) in enumerate(edges(graph))
        vertex_edge_map[Set([edge.src, edge.dst])] = index
    end
    for edge in edges_details
        edges_sorted[vertex_edge_map[Set([edge.source, edge.destination])]] = edge
    end
    return (vertex_edge_map, edges_sorted)
end

#first law is the one about vertex flow
function use_first_kirchhoff_law(vertex_edge_map::Dict{Set{Vertexes},Edges}, edges::Array{Edge_Details,1}, graph_matrix::Array{Int,2})
    edge_matrix = zeros(Int, 1, vertex_edge_map.count)
    X = Array{Float32,1}()
    for i = 1:size(graph_matrix,1)
        edge_row = zeros(Int64, 1, vertex_edge_map.count)
        for j = 1:size(graph_matrix, 1)
            if graph_matrix[i, j] == 1
                index = vertex_edge_map[Set([j, i])]
                if edges[index].source == j
                    edge_row[index] = 1
                else
                    edge_row[index] = -1
                end
            end
        end
        push!(X, 0.0)
        edge_matrix = vcat(edge_matrix, edge_row)
    end
    return (edge_matrix[2:end, :], X)
end

#second law is the one about loops
function use_second_kirchhoff_law(vertex_edge_map::Dict{Set{Vertexes},Edges}, edges::Array{Edge_Details,1}, cycle::Array{Edges,1})
    cycle = vcat(cycle, [cycle[1]])
    powers::Float32 = 0
    resistances = zeros(Int, vertex_edge_map.count)
    previous_edge = Set{Int}(cycle[end-1:end])
    previous_vertex = cycle[1]

    for vertex in cycle[2:end]
        index = vertex_edge_map[Set([previous_vertex, vertex])]
        sign = -1
        if in(edges[index].source, previous_edge)
            sign = 1
        end
        powers += edges[index].power * sign
        resistances[index] = edges[index].resistance * sign
        previous_edge = Set{Int}([previous_vertex, vertex])
        previous_vertex = vertex
    end
    return (resistances, powers)
end

#Gauss algorithm
function gauss_algorithm(n::Int, A::Array{Float32, 2}, X::Array{Float32, 1})
    for i = 1:n
        (_, index) = findmax(A[i:end, i])
        if A[index+i-1, i] == 0.0
            (_, index2) = findmin(A[i:end, i])
            index = index2
        end
        index += i-1
        A[i, :], A[index, :] = A[index, :], A[i, :]
        X[i], X[index] = X[index], X[i]
        for j = 1:n
            if i != j
                multiplier = A[j, i] / A[i, i]
                A[j, :] -= multiplier * A[i, :]
                X[j] -= multiplier * X[i]
                X[i] = X[i] / A[i, i]
                A[i, :] = A[i, :] / A[i, i]
            end
        end
    end
end

#main function
function main(n::Int, edges::Array{Edge_Details, 1})

    #preparations
    graph_matrix::Array{Int, 2} = zeros(Int, n, n)
    for egde in edges
        graph_matrix[egde.destination, egde.source] = 1
        graph_matrix[egde.source, egde.destination] = 1
    end
    graph::Graph = Graph(graph_matrix)
    (vertex_edge_map, edges_sorted) = prepare_resources_from_graph(graph, edges)

    #second Kirchhoff's law
    cycles = cycle_basis(graph)
    edge_count = size(edges, 1)
    A1 = zeros(Float32, size(cycles, 1), edge_count)
    X1 = zeros(Float32, size(cycles, 1))
    for (index, cycle) in enumerate(cycles)
        resistances, powers = use_second_kirchhoff_law(vertex_edge_map, edges_sorted, cycle)
        A1[index, :] = resistances
        X1[index] = powers
    end

    #first Kirchhoff's law
    (A2, X2) = use_first_kirchhoff_law(vertex_edge_map, edges_sorted, graph_matrix)
    A_reformed::Array{Float32,2} = rref(A2) #reduced row echelon form

    #dealing with 0s
    bit_mask::BitArray{1} = []
    for i = 1:size(A_reformed, 1)
        push!(bit_mask, any(x -> x != 0, A_reformed[i, :]))
    end
    A_reformed = A_reformed[bit_mask, :]
    A_combined = vcat(A1, A_reformed)
    X_combined = vcat(X1, zeros(Float32, size(A_reformed,1)))

    #calculating everything
    gauss_algorithm(size(X_combined,1), A_combined, X_combined)
    return (X_combined, graph)
end

#examples

#1
# http://tinyurl.com/y7ranshb
n1 = 4
edges1 = [Edge_Details(1, 2, 5, 3),Edge_Details(1, 3, 5, 1),Edge_Details(2, 3 ,0, 1),Edge_Details(1, 4, 0, 10),Edge_Details(2, 4, 0, 2)]
result1, graph1 = main(n1, edges1)
comp = compose(context(), rectangle(), fill("white"), gplot(graph1, nodelabel=1:n1, edgelabel=result1))
draw(PNG("first.png", 10cm, 10cm),comp)

#2
# http://tinyurl.com/ycqcp9gn
n2 = 3
edges2 = [Edge_Details(1, 2, 5, 3),Edge_Details(2, 3, 0, 2),Edge_Details(3, 1 ,0, 10)]
result2, graph2 = main(n2, edges2)
comp = compose(context(), rectangle(), fill("white"), gplot(graph2, nodelabel=1:n2, edgelabel=result2))
draw(PNG("second.png", 10cm, 10cm),comp)

#3
# http://tinyurl.com/y73cowmn
n3 = 7
edges3 = [Edge_Details(1, 2, 0, 1), Edge_Details(2, 3, 0, 1), Edge_Details(3, 4, 0, 10), Edge_Details(5, 4, 0, 20), Edge_Details(3, 5, 0, 5), Edge_Details(4, 6, 5, 5), Edge_Details(6, 7, 5, 0), Edge_Details(5, 7, 0, 2), Edge_Details(7, 3, 5, 5), Edge_Details(1, 7, 0, 0)]
result3, graph3 = main(n3, edges3)
comp = compose(context(), rectangle(), fill("white"), gplot(graph3, nodelabel=1:n3, edgelabel=result3))
draw(PNG("third.png", 10cm, 10cm),comp)
