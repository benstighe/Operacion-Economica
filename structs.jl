struct Generador
    ID :: Vector{Int64}
    Bus :: Vector{Int64}
    Pmax :: Vector{Float64}
    Pmin :: Vector{Float64}
    Cfijo :: Vector{Float64}
    Cvariable :: Vector{Float64}
end

# Creating an instance of Generador
#gen = Generador([1, 2, 3], [4, 5, 6], [10.0, 20.0, 30.0], [5.0, 10.0, 15.0])

println("ID: ", gen.ID)
println("Bus: ", gen.Bus[1])
println("Pmax: ", gen.Pmax[1])
println("Pmin: ", gen.Pmin[1])

struct Loads
    ID :: Vector{Int64}
    Bus :: Vector{Int64}
    Load_MW :: Vector{Float64}
end

struct Lines
    ID :: Vector{Int64}
    FromBus :: Vector{Int64}
    ToBus :: Vector{Int64}
    B :: Vector{Float64}
    Fmax :: Vector{Float64}
end



