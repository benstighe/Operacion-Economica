using JuMP, DataFrames, Gurobi, CSV
model = Model(Gurobi.Optimizer)

@variable(model, Pmin[id_gen] <= Pg[id_gen,t] <= Pmax[id_gen]) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[id_bar,t]) #Theta : angulos de las barras

for t in tiempos
    for i in barras

        @constraint(model, Cumplir_demanda, sum(Pg[id_gen,t] for id_gen in ID_SET_gen_in_barra_i) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in ID_SET_barras_conectadas_a_i) == D[i,t]) 

    end
end
for t in tiempos
    for k in lineas
        @constraint(model, Flujo, -Fmax[k] <= B[[k]]*(Theta[k[0],t]-Theta[k[1],t] <= Fmax[k]))
    end 
end

