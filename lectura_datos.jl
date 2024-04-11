using CSV, DataFrames

demanda = CSV.read("Demand.csv", DataFrame)
generadores = CSV.read("Generators.csv", DataFrame)
lineas = CSV.read("Lines.csv", DataFrame)
bess = CSV.read("Bess.csv", DataFrame)

