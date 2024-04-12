struct Generador
    ID::Int64
    Pmin::Int64
    Pmax::Float64
    Cvariable::Int64
    Ramp::Int64
    Bus_Conexion::Int64
end

struct Loads
    ID_Bus::Int64
    D_t1::Int64
    D_t2::Int64
    D_t3::Int64
    D_t4::Int64
    D_t5::Int64
    D_t6::Int64
end

struct Lines
    ID::Int64
    FromBus::Int64
    ToBus::Int64
    Fmax::Int64
    X::Float64
end

struct Bess
    ID::Int64
    Cap::Int64
    Rend::Float64
    Bus_conexion::Int64
end