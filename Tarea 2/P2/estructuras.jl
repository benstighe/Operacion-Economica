struct Generador
    Bus_Conexion :: Int64
    Pmin :: Float64
    Pmax :: Float64
    Cvariable :: Float64
    CFijo :: Float64
    CEncendido :: Float64
    Ramp :: Float64
    SRamp :: Float64
    min_up :: Int64
    min_down :: Int64
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
    
end

struct Renewables
    Bus_Conexion :: Int64
    Pmin :: Float64
    Pmax :: Float64
    Cvariable :: Float64
    CFijo :: Float64
    CEncendido :: Float64
    Ramp :: Float64
    SRamp :: Float64
    min_up :: Int64
    min_down :: Int64
    Generation :: Vector{Float64}
end

struct Renewables1
    Tipo :: String
    Bus_Conexion :: Int64
    Pmin :: Float64
    Pmax :: Float64
    Cvariable :: Float64
    CFijo :: Float64
    CEncendido :: Float64
    Ramp :: Float64
    SRamp :: Float64
    min_up :: Int64
    min_down :: Int64
    Generation :: Vector{Float64}

end
