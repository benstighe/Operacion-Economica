using JuMP, DataFrames, Gurobi, CSV
include("lectura_datos.jl")
include("structs.jl")


model = Model(Gurobi.Optimizer)


#arreglos de parametros
tiempo=1:6
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
@variable(model, Theta[demanda.ID_Bus,tiempo]) #Theta : angulos de las barras

@objective(model, Min, sum(gen.Cvariable[i] * Pg[i,t] for i in gen.ID, t in tiempo)) #Función objetivo, minimizar costos. LISTO

#RESTRICCIÓN DE FLUJO/DEMANDA
for t in tiempo
    for i in barras
        #obtener_generadores y obtener_bus esta en lectura de datos
        @constraint(model, sum(Pg[id_gen,t]/100 for id_gen in obtener_generadores_por_bus(gen,i)) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in obtener_bus_conectado_bus(lineas,i)) == demanda_DF[i,t+1]/100) 

    end
end


for t in tiempo
    for k in lineas.ID
        #agregue el menos aqui (MB)
        @constraint(model, -lineas.Fmax[k]/100<=(1/lineas.X[k])*(Theta[lineas.FromBus[k], t] - Theta[lineas.ToBus[k], t])  <= lineas.Fmax[k]/100)
        #-Fmax[k] <= B[[k]]*(Theta[k[0],t]-Theta[k[1],t] <= Fmax[k]))
    end 
end


#este esta bien
for t in tiempo
    for id_gen in gen.ID
        @constraint(model , gen.Pmin[id_gen]/100 <= Pg[id_gen,t]/100 <= gen.Pmax[id_gen]/100)
    end
end

optimize!(model)

println("Total cost: ", objective_value(model))
#=
for t in tiempo
    for i in gen.ID
        println("i, t, Pg[i,t]: ", i," ", t," ", value(Pg[i,t]))
    end
end
=#

for t in tiempo
    for i in barras
        for j in obtener_bus_conectado_bus(lineas,i)
        println("Tiempo, BarraFrom, BarraTo, Potencia ", t, " ", i, " ", j, " ", (value(Theta[i,t]), value(Theta[j,t])))
        end
    end
end



#falta el de ramplas

