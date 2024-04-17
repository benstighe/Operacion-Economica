using JuMP, DataFrames, Gurobi, CSV
include("lectura_datos.jl")
include("structs.jl")


model = Model(Gurobi.Optimizer)


#DEFINICIONES AUXILIARES

tiempo=1:(ncol(demanda_DF)-1)
barras=demanda.ID_Bus
B=crear_diccionario_B(lineas)


#----------------DEFINICION DE MODELO---------------------------------------

#VARIABLES
@variable(model, Pg[gen.ID,tiempo] ) #Pg : Cantidad de energía generada [MWh]
@variable(model, Theta[demanda.ID_Bus,tiempo]) #Theta : angulos de las barras
@variable(model, 0 <= Pg_Insatisfecho[demanda.ID_Bus, tiempo]) #Pg_Insatisfecho : Demanda no satisfecha

#FUNCION OBJETIVO
@objective(model, Min, sum(gen.Cvariable[i] * Pg[i,t] for i in gen.ID, t in tiempo)
                     + sum(Pg_Insatisfecho[j, t] * 30 for j in demanda.ID_Bus, t in tiempo)) #Función objetivo, minimizar costos. LISTO

#RESTRICCIÓN DE FLUJO/DEMANDA
for t in tiempo
    for i in barras
        @constraint(model, sum(Pg[id_gen,t]/100 for id_gen in obtener_generadores_por_bus(gen,i)) - 
        sum(B[i,j]*(Theta[i,t]-Theta[j,t]) for j in obtener_bus_conectado_bus(lineas,i)) == demanda_DF[i,t+1]/100 - Pg_Insatisfecho[i,t]/100) 
    end
end

#Barra 1 SLACK
for t in tiempo
    @constraint(model,Theta[1,t]==0)
end 

#RESTRICCION DE FLUJO LIMITE POR LINEAS
for t in tiempo
    for k in lineas.ID
        @constraint(model, -lineas.Fmax[k]/100<=(1/lineas.X[k])*(Theta[lineas.FromBus[k], t] - Theta[lineas.ToBus[k], t])
                    <= lineas.Fmax[k]/100)
    end 
end


#RESTRICCION DE LIMITES DE GENERACIÓN
for t in tiempo
    for id_gen in gen.ID
        @constraint(model , gen.Pmin[id_gen]/100 <= Pg[id_gen,t]/100 <= gen.Pmax[id_gen]/100)
    end
end

#RESTRICCION BARRA SLACK
for t in tiempo
    @constraint(model, Theta[1,t] == 0)
end


#=
#RESTRICCIÓN DE RAMPAS
for t in 2:length(tiempo)
    for id_gen in gen.ID
        @constraint(model, -gen.Ramp[id_gen]/100 <= ((Pg[id_gen,t]/100) - (Pg[id_gen,t-1]/100))   <= gen.Ramp[id_gen]/100)
    end
end
=#

optimize!(model)


println("El costo óptimo es : \$", objective_value(model) - sum(value(Pg_Insatisfecho[i,t]) for i in barras, t in tiempo)*30000)
println("Pago por multa: ", sum(value(Pg_Insatisfecho[i,t]) for i in barras, t in tiempo)*30)


for t in tiempo
    for i in gen.ID
        println("i, t, Pg[i,t]: ", i," ", t," ", value(Pg[i,t]))
    end
end


for t in tiempo
    println("Demanda insatisfecha en tiempo: ", t, " ", sum(value(Pg_Insatisfecho[i,t]) for i in barras))
    println("Demanda satisfecha en tiempo: ", t, " ",  sum(value(Pg[j,t]) for j in gen.ID))
    println("-----------------------------------")
end

for t in [3,4]
    for k in lineas.ID
        println("Flujo en linea ", lineas.FromBus[k], "-", lineas.ToBus[k], ", en el tiempo: ", t, " ", B[lineas.FromBus[k],lineas.ToBus[k]]*
                                                        (value(Theta[lineas.FromBus[k],t]) - value(Theta[lineas.ToBus[k],t])))
    end
    
    println("-----------------------------------")
end


#=

for t in tiempo
    for i in barras
        for j in obtener_bus_conectado_bus(lineas,i)
        println("Tiempo, BarraFrom, BarraTo, Potencia ", t, " ", i, " ", j, " ", (value(Theta[i,t]), value(Theta[j,t])))
        end
    end
end
=#
