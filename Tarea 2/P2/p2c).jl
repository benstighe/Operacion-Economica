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

data_x1 = CSV.read("x_values_99.csv", DataFrame)
data_u1 = CSV.read("u_values_99.csv", DataFrame)
data_v1 = CSV.read("v_values_99.csv", DataFrame)

x_values1 = Dict((row.i, row.t) => row.x for row in eachrow(data_x1))
u_values1 = Dict((row.i, row.t) => row.u for row in eachrow(data_u1))
v_values1 = Dict((row.i, row.t) => row.v for row in eachrow(data_v1))

function UnitCommitmentFunction1(Data,x,v,u)
    BusSet = Data[1]; TimeSet = Data[2]; GeneratorSet = Data[3]; LineSet = Data[4]; Pd = Data[5]; GeneratorBusLocation = Data[6]; GeneratorPminInMW = Data[7]; GeneratorPmaxInMW = Data[8];
    GeneratorRampInMW = Data[9]; GeneratorStartUpShutDownRampInMW = Data[10]; GeneratorMinimumUpTimeInHours = Data[11]; GeneratorMinimumDownTimeInHours = Data[12];
    GeneratorStartUpCostInUSD = Data[13]; GeneratorFixedCostInUSDperHour = Data[14]; GeneratorVariableCostInUSDperMWh = Data[15];
    GeneratorVariableCostInUSDperMWh = Data[16]; LineFromBus = Data[17]; LineToBus = Data[18]; LineReactance = Data[19]; LineMaxFlow = Data[20];Tipo_Generador=Data[21];Generacion_renovable=Data[22];
    T = length(TimeSet)

    model = Model(Gurobi.Optimizer)
    # Definir las variables continuas
    @variable(model, Pg[GeneratorSet, TimeSet])
    @variable(model, Theta[BusSet, TimeSet])


    @objective(model, Min,  sum(GeneratorFixedCostInUSDperHour[i] * x[(i, t)]
                            + GeneratorStartUpCostInUSD[i] * u[(i, t)]
                            + GeneratorVariableCostInUSDperMWh[i] * Pg[i,t] for i in GeneratorSet, t in TimeSet))
    #SE comentan ya que son binarias
    # @constraint(model, LogicConstraintBorder[i in GeneratorSet, t in 1:1], x[(i,t)] - 0 == u[i,t] - v[i,t]) #Restricción binaria en tiempo 1
    # @constraint(model, LogicConstraint[i in GeneratorSet, t in 2:T], x[(i,t)] - x[(i,t-1)] == u[i,t] - v[i,t]) #Restricción binaria para el resto del tiempo.

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
        sum(Pg[k,t] for k in GeneratorSet if GeneratorBusLocation[k] == i)- Pd[i][t]
            == sum( (1/LineReactance[l]) * (Theta[LineFromBus[l],t] - Theta[LineToBus[l],t]) for l in LineSet if LineFromBus[l] == i)
            + sum( (1/LineReactance[l]) * (Theta[LineToBus[l],t] - Theta[LineFromBus[l],t]) for l in LineSet if LineToBus[l] == i))


    #Ramp Down 
    @constraint(model, RampasDown[i in GeneratorSet, t in 2:T], -GeneratorRampInMW[i]*x[(i, t)]
        - GeneratorStartUpShutDownRampInMW[i]*v[(i, t)] <= Pg[i,t] - Pg[i,t-1])      
    #Ramp Up
    @constraint(model, RampasUp[i in GeneratorSet, t in 2:T], Pg[i,t] - Pg[i,t-1] <= GeneratorRampInMW[i]*x[(i, t-1)] + 
        GeneratorStartUpShutDownRampInMW[i]*u[(i, t)])#se pone t-1 ya que si se pone t cuando se prende se sumarian las dos ramplas

    # transmission line limits
    @constraint(model, CapacidadesLineas[i in LineSet, t in 1:T], -LineMaxFlow[i]<= (1/LineReactance[i]) * (Theta[LineFromBus[i],t] - 
        Theta[LineToBus[i],t]) <= LineMaxFlow[i])

    #Generador renovables
    for gen in 1:length(GeneratorSet)
        for t in 1:T
            if Tipo_Generador[gen]=="Renovable"
                @constraint(model,Pg[gen,t]<=Generacion_renovable[gen][t]*x[(gen, t)])
            end
        end
    end

    # Optimizacion
    JuMP.optimize!(model)

    return [model,Pg]
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
costo=0
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
    global Generacion_renovable=prod_gen1
    global Data = [BusSet,TimeSet,GeneratorSet,LineSet,Pd,GeneratorBusLocation,GeneratorPminInMW,
            GeneratorPmaxInMW,GeneratorRampInMW,GeneratorStartUpShutDownRampInMW,GeneratorMinimumUpTimeInHours,
            GeneratorMinimumDownTimeInHours,GeneratorStartUpCostInUSD,GeneratorFixedCostInUSDperHour,
            GeneratorVariableCostInUSDperMWh,GeneratorVariableCostInUSDperMWh,LineFromBus,LineToBus,
            LineReactance,LineMaxFlow,Tipo_Generador,Generacion_renovable]
    global Results = UnitCommitmentFunction1(Data,x_values,v_values,u_values)
    global model = Results[1]
    if is_solved_and_feasible(model)
        global factibles
        factibles= factibles + 1
        global costo
        costo= costo + JuMP.objective_value(model)
    else
        global infactibles
        infactibles= infactibles+ 1
    end
end



factibles1 = 0
infactibles1 = 0
costo1=0
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
    global Generacion_renovable=prod_gen1
    global Data = [BusSet,TimeSet,GeneratorSet,LineSet,Pd,GeneratorBusLocation,GeneratorPminInMW,
            GeneratorPmaxInMW,GeneratorRampInMW,GeneratorStartUpShutDownRampInMW,GeneratorMinimumUpTimeInHours,
            GeneratorMinimumDownTimeInHours,GeneratorStartUpCostInUSD,GeneratorFixedCostInUSDperHour,
            GeneratorVariableCostInUSDperMWh,GeneratorVariableCostInUSDperMWh,LineFromBus,LineToBus,
            LineReactance,LineMaxFlow,Tipo_Generador,Generacion_renovable]
    global Results = UnitCommitmentFunction1(Data,x_values1,v_values1,u_values1)
    global model = Results[1]
    if is_solved_and_feasible(model)
        global factibles1
        factibles1= factibles1 + 1
        global costo1
        costo1=costo1+ JuMP.objective_value(model)
    else
        global infactibles1
        infactibles1= infactibles1+ 1
    end
end

println("Cantidad factibles 90 ", factibles)
println("Costo promedio_90 ", costo/factibles)
println("Cantidad factibles 99 ", factibles1)
println("Costo promedio_99 ", costo1/factibles1)