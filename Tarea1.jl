using JuMP, DataFrames, Gurobi, CSV
include("lectura_datos.jl")
model = Model(Gurobi.Optimizer)
tiempo=[1:6]
@variable(model, Pg[gen.ID,tiempo] ) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[bar.ID,tiempo]) #Theta : angulos de las barras

for t in tiempo
    for i in barras

        @constraint(model, Cumplir_demanda, sum(Pg[id_gen,t] for id_gen in ID_SET_gen_in_barra_i) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in ID_SET_barras_conectadas_a_i) == D[i,t]) 

    end
end
for t in tiempo
    for k in lineas
        @constraint(model, Flujo, -Fmax[k] <= B[[k]]*(Theta[k[0],t]-Theta[k[1],t] <= Fmax[k]))
    end 
end

for t in tiempo
    for id_gen in gen.ID
        @constraint(model,Cumplir_potencias,gen.Pmin[id_gen] <= Pg[id_gen,t] <= gen.Pmax[id_gen])
    end
end