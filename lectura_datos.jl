include("structs.jl")

using CSV, DataFrames

demanda = CSV.read("Demand.csv", DataFrame)
generadores = CSV.read("Generators.csv", DataFrame)
lineas = CSV.read("Lines.csv", DataFrame)
bess = CSV.read("Bess.csv", DataFrame)

nombres_columnas = names(generadores)

gen = Generador(generadores[!,1],generadores[!,2],generadores[!,3],generadores[!,4],generadores[!,5],generadores[!,6])

println("ID: ", gen.ID)
println("Bus: ", gen.Bus_Conexion)
println("Pmax: ", gen.Pmax)
println("Pmin: ", gen.Pmin)
#hola
