using JuMP, XLSX, Statistics, Gurobi, DataFrames, CSV
include("lectura_datos118.jl")
include("montecarlo.jl")
# Leer los archivos CSV
data_x = CSV.read("x_values_90.csv", DataFrame)
data_u = CSV.read("u_values_90.csv", DataFrame)
data_v = CSV.read("v_values_90.csv", DataFrame)

x_values = Dict((row.i, row.t) => row.x for row in eachrow(data_x))
u_values = Dict((row.i, row.t) => row.u for row in eachrow(data_u))
v_values = Dict((row.i, row.t) => row.v for row in eachrow(data_v))


function UnitCommitmentFunction1(Data,x)
    BusSet = Data[1]; TimeSet = Data[2]; GeneratorSet = Data[3]; LineSet = Data[4]; Pd = Data[5]; GeneratorBusLocation = Data[6]; GeneratorPminInMW = Data[7]; GeneratorPmaxInMW = Data[8];
    GeneratorRampInMW = Data[9]; GeneratorStartUpShutDownRampInMW = Data[10]; GeneratorMinimumUpTimeInHours = Data[11]; GeneratorMinimumDownTimeInHours = Data[12];
    GeneratorStartUpCostInUSD = Data[13]; GeneratorFixedCostInUSDperHour = Data[14]; GeneratorVariableCostInUSDperMWh = Data[15];
    GeneratorVariableCostInUSDperMWh = Data[16]; LineFromBus = Data[17]; LineToBus = Data[18]; LineReactance = Data[19]; LineMaxFlow = Data[20];Tipo_Generador=Data[21];Generacion_renovable=Data[22];
    T = length(TimeSet)

    model = Model(Gurobi.Optimizer)
    # Definir las variables continuas
    @variable(model, Pg[GeneratorSet, TimeSet])
    @variable(model, Theta[BusSet, TimeSet])
    @variable(model, u[GeneratorSet,TimeSet], Bin) #u es si se enciende el generador. u = 1: Se enciende i en el tiempo t, u = 0: No se enciende i en t.
    @variable(model, v[GeneratorSet,TimeSet], Bin) #v es si se apaga el generador.  v = 1: Se apaga i en el tiempo t, v = 0: No se apaga i en t.


    @objective(model, Min,  sum(GeneratorFixedCostInUSDperHour[i] * x[(i, t)]
                            + GeneratorStartUpCostInUSD[i] * u[i, t]
                            + GeneratorVariableCostInUSDperMWh[i] * Pg[i,t] for i in GeneratorSet, t in TimeSet))
    #SE comentan ya que son binarias
    @constraint(model, LogicConstraintBorder[i in GeneratorSet, t in 1:1], x[i,t] - 0 == u[i,t] - v[i,t]) #Restricción binaria en tiempo 1
    @constraint(model, LogicConstraint[i in GeneratorSet, t in 2:T], x[i,t] - x[i,t-1] == u[i,t] - v[i,t]) #Restricción binaria para el resto del tiempo.

    @constraint(model, PMinConstraint[i in GeneratorSet, t in 1:T], GeneratorPminInMW[i] * x[(i, t)] <= Pg[i,t]) # Pmin <= Pg
    for i in GeneratorSet
        for t in TimeSet
            if Tipo_Generador[i]=="No renovable"
                @constraint(model, Pg[i,t] <= GeneratorPmaxInMW[i] * x[(i,t)]) # Pmax >= Pg
            end
        end
    end

    @constraint(model, FixAngleAtReferenceBusConstraint[i in 1:1, t in 1:T], Theta[i,t] == 0) # Angulo del bus de referencia

    @constraint(model, DCPowerFlowConstraint[i in BusSet, t in 1:T], 
        sum(Pg[k,t] for k in GeneratorSet if GeneratorBusLocation[k] == i)
        - Pd[i][t]
        == sum( (1/LineReactance[l]) * (Theta[LineFromBus[l],t] - Theta[LineToBus[l],t]) for l in LineSet if LineFromBus[l] == i)
        + sum( (1/LineReactance[l]) * (Theta[LineToBus[l],t] - Theta[LineFromBus[l],t]) for l in LineSet if LineToBus[l] == i))


    #Min Up/Down:
    @constraint(model, MinEncendido[i in GeneratorSet, t in 1:T-GeneratorMinimumUpTimeInHours[i]], sum(x[(i, t)] 
    for k in t:(t+GeneratorMinimumUpTimeInHours[i]-1)) >= GeneratorMinimumUpTimeInHours[i]*u[i, t])
    
    @constraint(model, MinEncendido2[i in GeneratorSet, t in T-GeneratorMinimumUpTimeInHours[i]+1:T], sum(x[(i, t)] - u[i, t] 
    for k in t:T) >= 0)    
    
    #Min Up/Down:
    @constraint(model, MinApagado[i in GeneratorSet, t in 1:T-GeneratorMinimumDownTimeInHours[i]], sum(1-x[(i, t)] 
    for k in t:(t+GeneratorMinimumDownTimeInHours[i]-1)) >= GeneratorMinimumDownTimeInHours[i]*v[i, t])

    @constraint(model, MinApagado2[i in GeneratorSet, t in T-GeneratorMinimumDownTimeInHours[i]+1:T], sum(1 - x[(i, t)] - v[i, t]
    for k in t:T) >= 0)

    #Ramp Down 
    @constraint(model, RampasDown[i in GeneratorSet, t in 2:T], -GeneratorRampInMW[i]*x[(i, t)]
        - GeneratorStartUpShutDownRampInMW[i]*v[i, t] <= Pg[i,t] - Pg[i,t-1])      
    #Ramp Up
    @constraint(model, RampasUp[i in GeneratorSet, t in 2:T], Pg[i,t] - Pg[i,t-1] <= GeneratorRampInMW[i]*x[(i, t-1)] + 
        GeneratorStartUpShutDownRampInMW[i]*u[i, t])#se pone t-1 ya que si se pone t cuando se prende se sumarian las dos ramplas

    # transmission line limits
    @constraint(model, CapacidadesLineas[i in LineSet, t in 1:T], -LineMaxFlow[i]<= (1/LineReactance[i]) * (Theta[LineFromBus[i],t] - 
        Theta[LineToBus[i],t]) <= LineMaxFlow[i])

    #Generador renovables
    for gen in 1:length(GeneratorSet)
        for t in 1:T
            if Tipo_Generador[gen]=="Renovable"
                @constraint(model,Pg[gen,t]<=Generacion_renovable[gen][t]*x[(gen, t)])
                #para que no este encendido si no genera
                #@constraint(model,Pg[gen,t]>=x[(gen, t)])

            elseif Tipo_Generador[gen]=="No renovable"
                #renovable reserva para arriba
                @constraint(model,Pg[gen,t]<=GeneratorPmaxInMW[gen]*x[gen,t])
                @constraint(model,Pg[gen,t]>=GeneratorPminInMW[gen]*x[gen,t])
            end
        end
    end
    # @constraint(model,reservaup[t in 1:T],sum(rup[gen,t] for gen in GeneratorSet)>=reserva_99[t])
    # @constraint(model,reservadown[t in 1:T],sum(rdown[gen,t] for gen in GeneratorSet)>=reserva_99[t])

    # Optimizacion
    JuMP.optimize!(model)

    return [model,Pg,u,v]
end
#DEFINO PARAMETROS
BusSet = id_buses
TimeSet = 1:24
GeneratorSet = [i for i in 1:length(bus_gen)] 
LineSet = id_lines
Pd=[load.Demanda for load in loads_list]

GeneratorBusLocation = bus_gen
GeneratorPminInMW = pmin_gen
GeneratorPmaxInMW = pmax_gen
GeneratorRampInMW = rampin_gen
GeneratorStartUpShutDownRampInMW = Srampin_gen
GeneratorMinimumUpTimeInHours = minup_gen
GeneratorMinimumDownTimeInHours = mindown_gen
GeneratorStartUpCostInUSD = st_cost_gen
GeneratorFixedCostInUSDperHour = fx_cost_gen
GeneratorVariableCostInUSDperMWh = v_cost_gen
Tipo_Generador=tipo_gen


LineFromBus = frombus_lines
LineToBus = tobus_lines
LineReactance = Xbus_lines
LineMaxFlow = fmax_lines
Generacion_renovable=prod_gen

#ESTE ES EL QUE VA CAMBIANDO: Generacion_renovable=prod_gen

factibles = 0
infactibles = 0

for iter in 1:100
    global lista_datos_eolico=collect(eachrow(eolico_montecarlo[iter]))
    global lista_datos_solar=collect(eachrow(solar_montecarlo[iter]))
    global prod_gen1 = [[] for gen in gen_list]
    for ren in lista_datos_eolico
        push!(prod_gen1, ren)
    end
    for ren in lista_datos_solar
        push!(prod_gen1, ren)
    end
    totall=[]
    for t in 1:24
        total=0
        for i in 1:40
            total=total + eolico_montecarlo[iter][i,t]
        end
        for i in 1:20
            total=total + solar_montecarlo[iter][i,t]
        end
        push!(totall,total)
        println(tot_promedio[t]-total)
    end
    
    global Generacion_renovable=prod_gen1
    global Data = [BusSet,TimeSet,GeneratorSet,LineSet,Pd,GeneratorBusLocation,GeneratorPminInMW,
            GeneratorPmaxInMW,GeneratorRampInMW,GeneratorStartUpShutDownRampInMW,GeneratorMinimumUpTimeInHours,
            GeneratorMinimumDownTimeInHours,GeneratorStartUpCostInUSD,GeneratorFixedCostInUSDperHour,
            GeneratorVariableCostInUSDperMWh,GeneratorVariableCostInUSDperMWh,LineFromBus,LineToBus,
            LineReactance,LineMaxFlow,Tipo_Generador,Generacion_renovable]
    global Results = UnitCommitmentFunction1(Data,x_values)
    global model = Results[1]
    if is_solved_and_feasible(model)
        global factibles
        factibles= factibles + 1
    else
        global infactibles
        infactibles= infactibles+ 1
    end
end
println("Cantidad factibles ", factibles)

# costo_startup = sum(value(u[i, t]) * GeneratorStartUpCostInUSD[i] for i in GeneratorSet for t in 1:24)
# costo_fijo = sum(value(x[i, t]) * GeneratorFixedCostInUSDperHour[i] for i in GeneratorSet for t in 1:24)
# costo_variable = sum(value(Pg[i, t]) * GeneratorVariableCostInUSDperMWh[i] for i in GeneratorSet for t in 1:24)
# println("Costo de encedido total: ", costo_startup)
# println("Costo fijo total: ", costo_fijo)
# println("Costo variable de generación total: ", costo_variable)

# println("--------------Generadores-------------")
# for t in 1:24
#     println("INSTANTE: ",t)
#     println("Cantidad generadores no renovables prendidos ",sum(value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
#     println("Cantidad generadores renovables prendidos ",sum(value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
#     println("Cantidad generadores no renovables comenzando a encender ",sum(value(u[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
#     println("Cantidad generadores renovables comenzando a encender",sum(value(u[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
#     println("Cantidad generadores no renovables apagando ",sum(value(v[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
#     println("Cantidad generadores renovables apagando",sum(value(v[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
# end


# costos_df = DataFrame(Variable=["Costo Total", "Costo de Encendido Total", "Costo Fijo Total", "Costo Variable Total"],
#                       Valor=[JuMP.objective_value(model), costo_startup, costo_fijo, costo_variable])



# generacion_df = DataFrame(Generador=GeneratorSet)

# for t in 1:24
#     generacion_df[!, Symbol("Hora $t")] = [JuMP.value(Pg[i, t]) for i in GeneratorSet]
# end
# transposed_df = permutedims(generacion_df)
# rename!(transposed_df, ["x$t" => "Generador $i" for (t , i) in enumerate(GeneratorSet)])
# delete!(transposed_df,[1])
# insertcols!(transposed_df , 1 , "Hora" => TimeSet)
# insertcols!(transposed_df , 9 , "Demanda horaria" => [sum(Pd[i][t] for i in BusSet) for t in TimeSet])


# onoff_df = DataFrame(Generador=GeneratorSet)

# for t in 1:24
#     onoff_df[!, Symbol("Hora $t")] = [JuMP.value(x[i, t]) for i in GeneratorSet]
# end
# transposed_onoff_df = permutedims(onoff_df)
# #println(transposed_onoff_df)
# rename!(transposed_onoff_df, ["x$t" => "Generador $i" for (t , i) in enumerate(GeneratorSet)])
# delete!(transposed_onoff_df,[1])
# insertcols!(transposed_onoff_df , 1 , "Hora" => TimeSet)

# XLSX.openxlsx("resultados_p2_c.xlsx", mode="w") do xf
#     XLSX.addsheet!(xf, "Estado ON-OFF")
#     XLSX.addsheet!(xf, "Generación")
#     XLSX.writetable!(xf["Generación"], Tables.columntable(transposed_df))
#     XLSX.writetable!(xf["Estado ON-OFF"], Tables.columntable(transposed_onoff_df))
#     XLSX.addsheet!(xf, "Costos")
#     XLSX.writetable!(xf["Costos"], Tables.columntable(costos_df))
# end