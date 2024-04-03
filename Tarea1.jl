using JuMP, DataFrames, Gurobi, CSV
model = Model(Gurobi.Optimizer)

@variable(model, Pmin[id_gen] <= Pg[id_gen] <= Pmax[id_gen]) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[id_bar]) #Theta : angulos de las barras

for i in barras

    @constraint(model, Cumplir_demanda, sum(Pg[id_gen] for id_gen in ID_SET_gen_in_barra_i) - 
    sum(B[i,j]*(Theta[i]-Theta[j]) for j in ID_SET_barras_conectadas_a_i) == D[i]) 

    end

for k in lineas
    @constraint(model, Flujo, -Fmax[k] <= B[[k]]*(Theta[k[0]]-Theta[k[1]] <= Fmax[k]))
end 

