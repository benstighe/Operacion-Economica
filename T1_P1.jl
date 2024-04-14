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

#FUNCION OBJETIVO
@objective(model, Min, sum(gen.Cvariable[i] * Pg[i,t] for i in gen.ID, t in tiempo)) #Función objetivo, minimizar costos. LISTO

#RESTRICCIÓN DE FLUJO/DEMANDA
restr = []
for t in tiempo
    for i in barras
        nombre_restriccion = Symbol("restriccion_tiempo", t, "_barra", i)
        nomb=string("restriccion_tiempo", t, "_barra", i)
        push!(restr, nomb)
        #println(nombre_restriccion)
        @eval begin
             @constraint(model,$nombre_restriccion ,
                sum(Pg[id_gen, $t] / 100 for id_gen in obtener_generadores_por_bus(gen, $i)) -
                sum(B[$i, j] * (Theta[$i, $t] - Theta[j, $t]) for j in obtener_bus_conectado_bus(lineas, $i)) ==
                demanda_DF[$i, $t + 1] / 100
            )
        end
    end
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


#  COSTOS GENERADORES
resultados = DataFrame(
    demand = [sum(demanda_DF[i, t+1] for i in 1:nrow(demanda_DF)) for t in tiempo],  # Tomar la demanda para cada tiempo
    generado_G1 = [value(Pg[1, t]) for t in tiempo],  # Potencia generada por G1 en cada tiempo
    costo_G1 = gen.Cvariable[1]*[value(Pg[1, t]) for t in tiempo],  # Costo por G1 en cada tiempo
    generado_G2 = [value(Pg[2, t]) for t in tiempo],  # Potencia generada por G2 en cada tiempo
    costo_G2 = gen.Cvariable[2]*[value(Pg[2, t]) for t in tiempo],  # Costo por G2 en cada tiempo
    generado_G3 = [value(Pg[3, t]) for t in tiempo],  # Potencia generada por G3 en cada tiempo
    costo_G3 = gen.Cvariable[3]*[value(Pg[3, t]) for t in tiempo],  # Costo por G3 en cada tiempo
    costo_total=gen.Cvariable[1]*[value(Pg[1, t]) for t in tiempo]+gen.Cvariable[2]*[value(Pg[2, t]) for t in tiempo]+
                gen.Cvariable[3]*[value(Pg[3, t]) for t in tiempo]
)
println(resultados)

#PRECIOS SOMBRA

cons=all_constraints(model; include_variable_in_set_constraints = true)

# for indice in 1:54
#         restriccion=cons[indice]
#         nombrerest=restr[indice]
#         println(nombrerest,shadow_price(restriccion))
# end

df_resultados = DataFrame(Barra = barras)
for t in tiempo
    column_name = Symbol("Tiempo_$t")
    resultados_tiempo = [shadow_price(cons[(t-1)*9 + i]) for i in barras]
    df_resultados[!, column_name] = resultados_tiempo
end
println(df_resultados)