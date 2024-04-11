using JuMP, DataFrames, Gurobi, CSV
include("lectura_datos.jl")
model = Model(Gurobi.Optimizer)
#arreglos de parametros
tiempo=[1:6]
barras=demanda.ID_Bus
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

#modelo 

@variable(model, Pg[gen.ID,tiempo] ) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[bar.ID,tiempo]) #Theta : angulos de las barras

for t in tiempo
    for i in barras
        #obtener_generadores y obtener_bus esta en lectura de datos(queda por definir bien la demanda)
        @constraint(model, Cumplir_demanda, sum(Pg[id_gen,t] for id_gen in obtener_generadores_por_bus(gen,i)) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in obtener_bus_conectado_bus(lineas,i)) == D[i,t]) 

    end
end

#este no lo he visto todavia
for t in tiempo
    for k in lineas
        @constraint(model, Flujo, -Fmax[k] <= B[[k]]*(Theta[k[0],t]-Theta[k[1],t] <= Fmax[k]))
    end 
end

#este esta bien
for t in tiempo
    for id_gen in gen.ID
        @constraint(model,Cumplir_potencias,gen.Pmin[id_gen] <= Pg[id_gen,t] <= gen.Pmax[id_gen])
    end
end


#falta el de ramplas

