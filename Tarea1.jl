using JuMP, DataFrames, Gurobi, CSV
model = Model(Gurobi.Optimizer)

@variable(model, 0 <= Pg[id_gen] <= Pmax[id_gen]) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[id_bar]) #Theta : angulos de las barras

@constraint(model, Cumplir_demanda, sum(Pg[id_gen] for id_gen in ID_SET) - sum()) 