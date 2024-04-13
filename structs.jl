struct Generador
    ID :: Vector{Int64}
    Pmin :: Vector{Float64}
    Pmax :: Vector{Float64}
    Cvariable :: Vector{Float64}
    Ramp :: Vector{Float64}
    Bus_Conexion :: Vector{Int64}
end

struct Loads
    ID_Bus :: Vector{Int64}
    D_t1 :: Vector{Float64}
    D_t2 :: Vector{Float64}
    D_t3 :: Vector{Float64}
    D_t4 :: Vector{Float64}
    D_t5 :: Vector{Float64}
    D_t6 :: Vector{Float64}
end

struct Lines
    ID :: Vector{Int64}
    FromBus :: Vector{Int64}
    ToBus :: Vector{Int64}
    Fmax :: Vector{Float64}
    X :: Vector{Float64}
    
end

struct Bess
    ID :: Vector{Int64}
    Cap :: Vector{Int64}
    Rend :: Vector{Float64}
    Bus_conexion :: Vector{Int64}
end


