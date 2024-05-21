struct Generador
    Bus_Conexion :: Int64
    Pmin :: Float64
    Pmax :: Float64
    Cvariable :: Float64
    CFijo :: Float64
    CEncendido :: Float64
    Ramp :: Float64
end

struct Loads
    ID_Bus :: Int64
    Demanda :: Vector{Float64}
end

struct Lines
    ID :: Int64
    FromBus :: Int64
    ToBus :: Int64
    Fmax :: Float64
    X :: Float64
    R :: Float64
    
end

struct Renewables
    Bus_Conexion :: Int64
    Pmin :: Float64
    Pmax :: Float64
    Cvariable :: Float64
    CFijo :: Float64
    CEncendido :: Float64
    Ramp :: Float64
end

