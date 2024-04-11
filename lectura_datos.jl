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

#println("ID: ", gen.ID)
#println("Bus: ", gen.Bus_Conexion)
#println("Pmax: ", gen.Pmax)
#println("Pmin: ", gen.Pmin)
#hola
