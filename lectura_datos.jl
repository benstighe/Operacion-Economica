include("structs.jl")

using CSV, DataFrames

demanda_DF = CSV.read("Demand.csv", DataFrame)
generadores_DF = CSV.read("Generators.csv", DataFrame)
lineas_DF = CSV.read("Lines.csv", DataFrame)
bess_DF = CSV.read("Bess.csv", DataFrame)


gen = Generador(generadores_DF[!,1],generadores_DF[!,2],generadores_DF[!,3],generadores_DF[!,4],generadores_DF[!,5],generadores_DF[!,6])
lineas = Lines(lineas_DF[!,1],lineas_DF[!,2],lineas_DF[!,3],lineas_DF[!,4],lineas_DF[!,5])
demanda = Loads(demanda_DF[!,1], demanda_DF[!,2],demanda_DF[!,3], demanda_DF[!,4], demanda_DF[!,5], demanda_DF[!,6], demanda_DF[!,7])
bess = Bess(bess_DF[!,1], bess_DF[!,2], bess_DF[!,3], bess_DF[!,4])


#para obtener los generadores para cierta barra
function obtener_generadores_por_bus(gen::Generador, bus::Int64)
    # Crear un vector para almacenar los IDs de los generadores en el bus dado
    generadores_en_bus = Int[]
    # Iterar sobre los generadores y añadir los IDs correspondientes al bus dado
    for i in 1:length(gen.Bus_Conexion)
        if gen.Bus_Conexion[i] == bus
            push!(generadores_en_bus, gen.ID[i])
        end
    end
    return generadores_en_bus
end
#para obtener bus conectado a cada bus
function obtener_bus_conectado_bus(lineas::Lines, bus::Int64)
    # Crear un vector para almacenar los IDs de las lineas en el bus dado
    lineas_en_bus = Int[]
    # Iterar sobre las lineas y añadir los IDs correspondientes al bus dado
    for i in 1:length(lineas.ID)
        if lineas.FromBus[i] == bus 
            push!(lineas_en_bus, lineas.ToBus[i])
        end
        if lineas.ToBus[i] == bus
            push!(lineas_en_bus, lineas.FromBus[i])
        end
    end
    return lineas_en_bus
end
#obtener_bus_conectado_bus(lineas,2)
#crear diccionario de B  (1/x)
function crear_diccionario_B(lines::Lines)
    dict = Dict{Tuple{Int64, Int64}, Float64}()
    for i in 1:length(lines.FromBus)
        from_bus= lines.FromBus[i]
        to_bus= lines.ToBus[i]
        x= lines.X[i]
        tupla1= (from_bus, to_bus)
        tupla2= (to_bus,from_bus)
        dict[tupla1] = 1/x
        dict[tupla2] =1/x
    end
    return dict
end
B=crear_diccionario_B(lineas)

#println("ID: ", gen.ID)
#println("Bus: ", gen.Bus_Conexion)
#println("Pmax: ", gen.Pmax)
#println("Pmin: ", gen.Pmin)
#hola

println(demanda)