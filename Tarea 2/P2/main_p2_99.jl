### Load packages ###
using JuMP, XLSX, Statistics, Gurobi, DataFrames, CSV
include("lectura_datos118.jl")
include("montecarlo.jl")

function UnitCommitmentFunction(Data)
    BusSet = Data[1]; TimeSet = Data[2]; GeneratorSet = Data[3]; LineSet = Data[4]; Pd = Data[5]; GeneratorBusLocation = Data[6]; GeneratorPminInMW = Data[7]; GeneratorPmaxInMW = Data[8];
    GeneratorRampInMW = Data[9]; GeneratorStartUpShutDownRampInMW = Data[10]; GeneratorMinimumUpTimeInHours = Data[11]; GeneratorMinimumDownTimeInHours = Data[12];
    GeneratorStartUpCostInUSD = Data[13]; GeneratorFixedCostInUSDperHour = Data[14]; GeneratorVariableCostInUSDperMWh = Data[15];
    GeneratorVariableCostInUSDperMWh = Data[16]; LineFromBus = Data[17]; LineToBus = Data[18]; LineReactance = Data[19]; LineMaxFlow = Data[20];Tipo_Generador=Data[21];Generacion_renovable=Data[22];

    T = length(TimeSet)

    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "MIPGap", 0.005)

    @variable(model, x[GeneratorSet,TimeSet], Bin) #x es el estado del generador (encendido o apagado) (ON/OFF)
    @variable(model, u[GeneratorSet,TimeSet], Bin) #u es si se enciende el generador. u = 1: Se enciende i en el tiempo t, u = 0: No se enciende i en t.
    @variable(model, v[GeneratorSet,TimeSet], Bin) #v es si se apaga el generador.  v = 1: Se apaga i en el tiempo t, v = 0: No se apaga i en t.
    @variable(model, Pg[GeneratorSet,TimeSet]) #Pg : Cantidad de energía generada en MWh
    @variable(model, Theta[BusSet,TimeSet]) # Theta es el defase (angulo)
    @variable(model, r[GeneratorSet,TimeSet])


    @objective(model, Min,  sum(GeneratorFixedCostInUSDperHour[i] * x[i,t]
                            + GeneratorStartUpCostInUSD[i] * u[i,t]
                            + GeneratorVariableCostInUSDperMWh[i] * Pg[i,t] for i in GeneratorSet, t in TimeSet))

    @constraint(model, LogicConstraintBorder[i in GeneratorSet, t in 1:1], x[i,t] - 0 == u[i,t] - v[i,t]) #Restricción binaria en tiempo 1
    @constraint(model, LogicConstraint[i in GeneratorSet, t in 2:T], x[i,t] - x[i,t-1] == u[i,t] - v[i,t]) #Restricción binaria para el resto del tiempo.

    @constraint(model, PMinConstraint[i in GeneratorSet, t in 1:T], GeneratorPminInMW[i] * x[i,t] <= Pg[i,t]) # Pmin <= Pg
    for i in GeneratorSet
        for t in TimeSet
            if Tipo_Generador[i]=="No renovable"
                @constraint(model, Pg[i,t] <= GeneratorPmaxInMW[i] * x[i,t]) # Pmax >= Pg
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
    @constraint(model, MinEncendido[i in GeneratorSet, t in 1:T-GeneratorMinimumUpTimeInHours[i]], sum(x[i,k] 
    for k in t:(t+GeneratorMinimumUpTimeInHours[i]-1)) >= GeneratorMinimumUpTimeInHours[i]*u[i,t])
    
    @constraint(model, MinEncendido2[i in GeneratorSet, t in T-GeneratorMinimumUpTimeInHours[i]+1:T], sum(x[i,k] - u[i,t] 
    for k in t:T) >= 0)    
    
    #Min Up/Down:
    @constraint(model, MinApagado[i in GeneratorSet, t in 1:T-GeneratorMinimumDownTimeInHours[i]], sum(1-x[i,k] 
    for k in t:(t+GeneratorMinimumDownTimeInHours[i]-1)) >= GeneratorMinimumDownTimeInHours[i]*v[i,t])

    @constraint(model, MinApagado2[i in GeneratorSet, t in T-GeneratorMinimumDownTimeInHours[i]+1:T], sum(1 - x[i,k] - v[i,t] 
    for k in t:T) >= 0)

    #Ramp Down 
    @constraint(model, RampasDown[i in GeneratorSet, t in 2:T], -GeneratorRampInMW[i]*x[i,t] 
        - GeneratorStartUpShutDownRampInMW[i]*v[i,t] <= Pg[i,t] - Pg[i,t-1])      
    #Ramp Up
    @constraint(model, RampasUp[i in GeneratorSet, t in 2:T], Pg[i,t] - Pg[i,t-1] <= GeneratorRampInMW[i]*x[i,t-1] + 
        GeneratorStartUpShutDownRampInMW[i]*u[i,t])#se pone t-1 ya que si se pone t cuando se prende se sumarian las dos ramplas

    # transmission line limits
    @constraint(model, CapacidadesLineas[i in LineSet, t in 1:T], -LineMaxFlow[i]<= (1/LineReactance[i]) * (Theta[LineFromBus[i],t] - 
        Theta[LineToBus[i],t]) <= LineMaxFlow[i])

    #Generador renovables
    for gen in 1:length(GeneratorSet)
        for t in 1:T
            if Tipo_Generador[gen]=="Renovable"
                @constraint(model,Pg[gen,t]<=Generacion_renovable[gen][t]*x[gen,t])
                #para que no este encendido si no genera
                #@constraint(model,Pg[gen,t]>=x[gen,t])
                @constraint(model,r[gen,t]==0)

            elseif Tipo_Generador[gen]=="No renovable"
                #renovable reserva para arriba
                @constraint(model,Pg[gen,t]+r[gen,t]<=GeneratorPmaxInMW[gen]*x[gen,t])
                @constraint(model,Pg[gen,t]-r[gen,t]>=GeneratorPminInMW[gen]*x[gen,t])
            end
        end
    end
    #Para tener 13 
    @constraint(model,reservaup[t in 1:T],sum(r[gen,t] for gen in GeneratorSet)>=reserva_99_of_rial_otros[t])
    #Para tener mas (puede dar infactible)
    #@constraint(model,reservaup[t in 1:T],sum(r[gen,t] for gen in GeneratorSet)>=2*reserva_99_of_rial_otros[t])

    # Optimizacion
    JuMP.optimize!(model)

    return [model,x,u,v,Pg,r]
end

#OBTENEMOS LOS DATOS DE 118

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
Generacion_renovable=prod_gen

LineFromBus = frombus_lines
LineToBus = tobus_lines
LineReactance = Xbus_lines
LineMaxFlow = fmax_lines

Data = [BusSet,TimeSet,GeneratorSet,LineSet,Pd,GeneratorBusLocation,GeneratorPminInMW,
GeneratorPmaxInMW,GeneratorRampInMW,GeneratorStartUpShutDownRampInMW,GeneratorMinimumUpTimeInHours,
GeneratorMinimumDownTimeInHours,GeneratorStartUpCostInUSD,GeneratorFixedCostInUSDperHour,
GeneratorVariableCostInUSDperMWh,GeneratorVariableCostInUSDperMWh,LineFromBus,LineToBus,
LineReactance,LineMaxFlow,Tipo_Generador,Generacion_renovable]

Results = UnitCommitmentFunction(Data)
model = Results[1]; x = Results[2]; u = Results[3]; v = Results[4]; Pg = Results[5] ;r = Results[6] ;#rdown = Results[7] ;

println("Total cost: ", JuMP.objective_value(model))

costo_startup = sum(value(u[i, t]) * GeneratorStartUpCostInUSD[i] for i in GeneratorSet for t in 1:24)
costo_fijo = sum(value(x[i, t]) * GeneratorFixedCostInUSDperHour[i] for i in GeneratorSet for t in 1:24)
costo_variable = sum(value(Pg[i, t]) * GeneratorVariableCostInUSDperMWh[i] for i in GeneratorSet for t in 1:24)
println("Costo de encedido total: ", costo_startup)
println("Costo fijo total: ", costo_fijo)
println("Costo variable de generación total: ", costo_variable)
println("--------------Reservas-------------")
for t in 1:24
    println("INSTANTE ",t)
    println("Reserva 90  ",reserva_90_of_rial_otros[t])
    println("Reserva 99  ",reserva_99_of_rial_otros[t])
    println("Cantidad demanda ",sum(Pd[i][t] for i in BusSet))
    println("Limite inferior 90 ",tot_percentil_90_inf[t])
    println("Limite inferior 99 ",tot_percentil_99_inf[t])
    println("Limite sup 90 ",tot_percentil_90_sup[t])
    println("Limite sup 99 ",tot_percentil_99_sup[t])
    println("Cantidad max generadores ",sum(GeneratorPmaxInMW[k]*value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
    println("Cantidad min generadores ",sum(GeneratorPminInMW[k]*value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
    println("Suma reserva up ", sum(value(r[k, t]) for k in GeneratorSet))
    #println("Suma reserva down ", sum(value(rdown[k, t]) for k in GeneratorSet))
end


println("--------------Generadores-------------")
for t in 1:24
    println("INSTANTE: ",t)
    println("Cantidad generadores no renovables prendidos ",sum(value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
    println("Cantidad generadores renovables prendidos ",sum(value(x[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
    println("Cantidad generadores no renovables comenzando a encender ",sum(value(u[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
    println("Cantidad generadores renovables comenzando a encender",sum(value(u[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
    println("Cantidad generadores no renovables apagando ",sum(value(v[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="No renovable"))
    println("Cantidad generadores renovables apagando",sum(value(v[k, t]) for k in GeneratorSet if Tipo_Generador[k]=="Renovable"))
end
#ACA SE LLENA EL EXCEL
costos_df = DataFrame(Variable=["Costo Total", "Costo de Encendido Total", "Costo Fijo Total", "Costo Variable Total"],
                      Valor=[JuMP.objective_value(model), costo_startup, costo_fijo, costo_variable])


generacion_df = DataFrame(Generador=GeneratorSet)

for t in 1:24
    generacion_df[!, Symbol("Hora $t")] = [JuMP.value(Pg[i, t]) for i in GeneratorSet]
end
transposed_df = permutedims(generacion_df)
rename!(transposed_df, ["x$t" => "Generador $i" for (t , i) in enumerate(GeneratorSet)])
delete!(transposed_df,[1])
insertcols!(transposed_df , 1 , "Hora" => TimeSet)
insertcols!(transposed_df , 9 , "Demanda horaria" => [sum(Pd[i][t] for i in BusSet) for t in TimeSet])


onoff_df = DataFrame(Generador=GeneratorSet)

for t in 1:24
    onoff_df[!, Symbol("Hora $t")] = [JuMP.value(x[i, t]) for i in GeneratorSet]
end
transposed_onoff_df = permutedims(onoff_df)
#println(transposed_onoff_df)
rename!(transposed_onoff_df, ["x$t" => "Generador $i" for (t , i) in enumerate(GeneratorSet)])
delete!(transposed_onoff_df,[1])
insertcols!(transposed_onoff_df , 1 , "Hora" => TimeSet)

XLSX.openxlsx("resultados_p2_b.xlsx", mode="w") do xf
    XLSX.addsheet!(xf, "Estado ON-OFF")
    XLSX.addsheet!(xf, "Generación")
    XLSX.writetable!(xf["Generación"], Tables.columntable(transposed_df))
    XLSX.writetable!(xf["Estado ON-OFF"], Tables.columntable(transposed_onoff_df))
    XLSX.addsheet!(xf, "Costos")
    XLSX.writetable!(xf["Costos"], Tables.columntable(costos_df))
end

#LLENAMOS CSV para la otra pregunta
data_x1 = DataFrame(i=Int[], t=Int[], x=Float64[])
data_u1 = DataFrame(i=Int[], t=Int[], u=Float64[])
data_v1 = DataFrame(i=Int[], t=Int[], v=Float64[])

for i in GeneratorSet
    for t in TimeSet
        push!(data_x1, (i, t, value(x[i,t])))
        push!(data_u1, (i, t, value(u[i,t])))
        push!(data_v1, (i, t, value(v[i,t])))
    end
end

# Guardar los DataFrames en archivos CSV
CSV.write("x_values_99.csv", data_x1)
CSV.write("u_values_99.csv", data_u1)
CSV.write("v_values_99.csv", data_v1)

println("Valores de las variables binarias guardados en archivos CSV.")





