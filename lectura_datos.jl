include("structs.jl")

using CSV, DataFrames

demanda_DF = CSV.read("Demand.csv", DataFrame)
generadores_DF = CSV.read("Generators.csv", DataFrame)
lineas_DF = CSV.read("Lines.csv", DataFrame)
bess_DF = CSV.read("Bess.csv", DataFrame)

function generar_generadores(DataFrame_fuente::DataFrame)
    lista_generadores = Generador[]
    for row in 1:nrow(DataFrame_fuente)
        gen = Generador(DataFrame_fuente[row,1],DataFrame_fuente[row,2],DataFrame_fuente[row,3],DataFrame_fuente[row,4],DataFrame_fuente[row,5],DataFrame_fuente[row,6])
        push!(lista_generadores, gen)  
    end
    return lista_generadores
end

function generar_demanda(DataFrame_fuente::DataFrame)
    lista_demanda = Loads[]
    for row in 1:nrow(DataFrame_fuente)
        demanda = Loads(DataFrame_fuente[row,1],DataFrame_fuente[row,2],DataFrame_fuente[row,3],DataFrame_fuente[row,4],DataFrame_fuente[row,5]
        ,DataFrame_fuente[row,6],DataFrame_fuente[row,7])
        push!(lista_demanda, demanda)  
    end
    return lista_demanda
end

function generar_lineas(DataFrame_fuente::DataFrame)
    lista_lineas = Lines[]
    for row in 1:nrow(DataFrame_fuente)
        lineas = Lines(DataFrame_fuente[row,1],DataFrame_fuente[row,2],DataFrame_fuente[row,3],DataFrame_fuente[row,4],DataFrame_fuente[row,5])
        push!(lista_lineas, lineas)  
    end
    return lista_lineas
end

function generar_bess(DataFrame_fuente::DataFrame)
    lista_bess = Bess[]
    for row in 1:nrow(DataFrame_fuente)
        bess = Bess(DataFrame_fuente[row,1],DataFrame_fuente[row,2],DataFrame_fuente[row,3],DataFrame_fuente[row,4])
        push!(lista_bess, bess)  
    end
    return lista_bess
end


demanda = generar_demanda(demanda_DF)
generadores = generar_generadores(generadores_DF)
lineas = generar_lineas(lineas_DF)
bess = generar_bess(bess_DF)


#para obtener los generadores para cierta barra
function obtener_generadores_por_bus(gen::Array, bus::Int64)
    # Crear un vector para almacenar los IDs de los generadores en el bus dado
    generadores_en_bus = Int[]
    # Iterar sobre los generadores y añadir los IDs correspondientes al bus dado
    for i in 1:length(gen)
        if gen[i].Bus_Conexion == bus
            push!(generadores_en_bus, gen[i].ID)
        end
    end
    return generadores_en_bus
end

println(obtener_generadores_por_bus(generadores,5))


#=
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
=#
