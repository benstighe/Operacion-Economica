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
@variable(model, d[bess.ID,tiempo]) #descarga bateria
@variable(model, c[bess.ID,tiempo]) #carga bateria
@variable(model, e[bess.ID,tiempo]) #energia bateria




#FUNCION OBJETIVO
@objective(model, Min, sum(gen.Cvariable[i] * Pg[i,t] for i in gen.ID, t in tiempo)) #Función objetivo, minimizar costos. LISTO

#RESTRICCIÓN DE FLUJO/DEMANDA
restr = []
for t in tiempo
    for i in barras
        nombre_restriccion = Symbol("restriccion_tiempo", t, "_barra", i)
        nomb=string("restriccion_tiempo", t, "_barra", i)
        push!(restr, nomb)
        @eval begin 
            @constraint(model,$nombre_restriccion, sum(Pg[id_gen,$t]/100 for id_gen in obtener_generadores_por_bus(gen,$i))+
            sum(d[id_bat,$t]/100-c[id_bat,$t]/100 for id_bat in obtener_baterias_por_bus(bess,$i)) - 
            sum(B[$i,j]*(Theta[$i,$t]-Theta[j,$t]) for j in obtener_bus_conectado_bus(lineas,$i)) == demanda_DF[$i,$t+1]/100) 
        end
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

#RESTRICCIÓN DE RAMPAS
for t in 2:length(tiempo)
    for id_gen in gen.ID
        @constraint(model, -gen.Ramp[id_gen]/100 <= ((Pg[id_gen,t]/100) - (Pg[id_gen,t-1]/100))   <= gen.Ramp[id_gen]/100)
    end
end
#RESTRICCIONES BATERIAS

#RESTRICCION VARIABLES CARGA Y DESCARGA (no pueden ser mayor a la capacidad)
for t in tiempo
    for bat_id in bess.ID
        @constraint(model,0<=d[bat_id,t]<=bess.Cap[bat_id])
        @constraint(model,0<=c[bat_id,t]<=bess.Cap[bat_id])
    end 
end

#RESTRICCION CARGA INICIAL
#se hace asi y no e[bat_id,1]==bess.Cap[bat_id]*3*0.5 ya que asi hay flujos en t=1
for bat_id in bess.ID
    @constraint(model,e[bat_id,1]==bess.Cap[bat_id]*3*0.5+(c[bat_id,1]*bess.Rend[bat_id])-(d[bat_id,1]/bess.Rend[bat_id])) 
end 

#RESTRICCION CARGA Final

for bat_id in bess.ID
    @constraint(model,e[bat_id,6]==bess.Cap[bat_id]*3*0.5) 
end 

#RESTRICCION DE CAPACIDAD BATERIAS

for t in tiempo
    for bat_id in bess.ID
        @constraint(model,0<=e[bat_id,t]<=bess.Cap[bat_id]*3)
    end 
end

#RESTRICCION CARGA Y DESCARGA BATERIAS

for t in 2:length(tiempo)
    for bat_id in bess.ID
        @constraint(model,e[bat_id,t]==e[bat_id,t-1]+(c[bat_id,t]*bess.Rend[bat_id])-(d[bat_id,t]/bess.Rend[bat_id]))
    end 
end


optimize!(model)


println("El costo óptimo es : \$", objective_value(model))

println("Para cada nodo el óptimo es el siguiente: ")

# for t in tiempo
#     for i in gen.ID
#         println("i, t, Pg[i,t]: ", i," ", t," ", value(Pg[i,t]))
#     end
# end

# for t in tiempo
#     for i in barras
#         for j in obtener_bus_conectado_bus(lineas,i)
#         println("Tiempo, BarraFrom, BarraTo, Potencia ", t, " ", i, " ", j, " ", (value(Theta[i,t]), value(Theta[j,t])))
#         end
#     end
# end

resultados = DataFrame(
    demand = [sum(demanda_DF[i, t+1] for i in 1:nrow(demanda_DF)) for t in tiempo],  # Tomar la demanda para cada tiempo
    bat_1_descarga=[value(d[1,t]-c[1,t]) for t in tiempo],#bat1desc
    bat_2_descarga=[value(d[2,t]-c[2,t]) for t in tiempo],#bat2desc
    bat_3_descarga=[value(d[3,t]-c[3,t]) for t in tiempo],#bat3desc
    generado_G1 = [value(Pg[1, t]) for t in tiempo],  # Potencia generada por G1 en cada tiempo
    costo_G1 = gen.Cvariable[1]*[value(Pg[1, t]) for t in tiempo],  # Costo por G1 en cada tiempo
    generado_G2 = [value(Pg[2, t]) for t in tiempo],  # Potencia generada por G2 en cada tiempo
    costo_G2 = gen.Cvariable[2]*[value(Pg[2, t]) for t in tiempo],  # Costo por G2 en cada tiempo
    generado_G3 = [value(Pg[3, t]) for t in tiempo],  # Potencia generada por G3 en cada tiempo
    costo_G3 = gen.Cvariable[3]*[value(Pg[3, t]) for t in tiempo],  # Costo por G3 en cada tiempo
    costo_total=gen.Cvariable[1]*[value(Pg[1, t]) for t in tiempo]+gen.Cvariable[2]*[value(Pg[2, t]) for t in tiempo]+
                gen.Cvariable[3]*[value(Pg[3, t]) for t in tiempo])

println(resultados)
println("Baterias informacion")
resultados1 = DataFrame(
    str_bat_1=[value(e[1,t]) for t in tiempo],#bat1
    str_bat_2=[value(e[2,t]) for t in tiempo],#bat2
    str_bat_3=[value(e[3,t]) for t in tiempo],#bat3
    bat_1_descarga=[value(d[1,t]) for t in tiempo],#bat1desc
    bat_2_descarga=[value(d[2,t]) for t in tiempo],#bat2desc
    bat_3_descarga=[value(d[3,t]) for t in tiempo],#bat3desc
    bat_1_carga=[value(c[1,t]) for t in tiempo],#bat1desc
    bat_2_carga=[value(c[2,t]) for t in tiempo],#bat2desc
    bat_3_carga=[value(c[3,t]) for t in tiempo],#bat3desc
)

println(resultados1)


#PRECIO SOMBRA

cons=all_constraints(model; include_variable_in_set_constraints = true)

df_resultados = DataFrame(Barra = barras)
for t in tiempo
    column_name = Symbol("Tiempo_$t")
    resultados_tiempo = [-shadow_price(cons[(t-1)*9 + i]) for i in barras]
    df_resultados[!, column_name] = resultados_tiempo
end
println("PRECIOS SOMBRA")
println(df_resultados)