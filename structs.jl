struct Generador
    ID :: Vector{Int64}
    Pmin :: Vector{Int64}
    Pmax :: Vector{Float64}
    Cvariable :: Vector{Int64}
    Ramp :: Vector{Int64}
    Bus_Conexion :: Vector{Int64}
end

# Creating an instance of Generador
#gen = Generador([1, 2, 3], [4, 5, 6], [10.0, 20.0, 30.0], [5.0, 10.0, 15.0])

#println("ID: ", gen.ID)
#println("Bus: ", gen.Bus[1])
#println("Pmax: ", gen.Pmax[1])
#println("Pmin: ", gen.Pmin[1])

struct Loads
    ID_Bus :: Vector{Int64}
    D_t1 :: Vector{Int64}
    D_t2 :: Vector{Int64}
    D_t3 :: Vector{Int64}
    D_t4 :: Vector{Int64}
    D_t5 :: Vector{Int64}
    D_t6 :: Vector{Int64}
end

struct Lines
    ID :: Vector{Int64}
    FromBus :: Vector{Int64}
    ToBus :: Vector{Int64}
    Fmax :: Vector{Int64}
    X :: Vector{Float64}
    
end

struct Bess
    ID :: Vector{Int64}
    Cap :: Vector{Int64}
    Rend :: Vector{Float64}
    Bus_conexion :: Vector{Int64}
end


