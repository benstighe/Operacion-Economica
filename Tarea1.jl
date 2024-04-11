using JuMP, DataFrames, Gurobi, CSV
include("lectura_datos.jl")
model = Model(Gurobi.Optimizer)
#arreglos de parametros
tiempo=[1:6]
barras=demanda.ID_Bus


#modelo 

@variable(model, Pg[gen.ID,tiempo] ) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[bar.ID,tiempo]) #Theta : angulos de las barras

for t in tiempo
    for i in barras
        #obtener_generadores esta en lectura de datos()
        @constraint(model, Cumplir_demanda, sum(Pg[id_gen,t] for id_gen in obtener_generadores_por_bus(gen,i)) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in obtener_bus_conectado_bus(lineas,i)) == D[i,t]) 

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