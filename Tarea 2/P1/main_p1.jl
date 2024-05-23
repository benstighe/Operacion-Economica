### Load packages ###
using JuMP, GLPK, XLSX, Statistics
include("lectura_datos.jl")

### Function for solving unit commitment ###
function UnitCommitmentFunction(Data)
    BusSet = Data[1]; TimeSet = Data[2]; GeneratorSet = Data[3]; LineSet = Data[4]; Pd = Data[5]; GeneratorBusLocation = Data[6]; GeneratorPminInMW = Data[7]; GeneratorPmaxInMW = Data[8];
    GeneratorRampInMW = Data[9]; GeneratorStartUpShutDownRampInMW = Data[10]; GeneratorMinimumUpTimeInHours = Data[11]; GeneratorMinimumDownTimeInHours = Data[12];
    GeneratorStartUpCostInUSD = Data[13]; GeneratorFixedCostInUSDperHour = Data[14]; GeneratorVariableCostInUSDperMWh = Data[15];
    GeneratorVariableCostInUSDperMWh = Data[16]; LineFromBus = Data[17]; LineToBus = Data[18]; LineReactance = Data[19]; LineMaxFlow = Data[20];

    T = length(TimeSet)

    model = Model(GLPK.Optimizer)

    @variable(model, x[GeneratorSet,TimeSet], Bin) #x es el estado del generador (encendido o apagado) (ON/OFF)
    @variable(model, u[GeneratorSet,TimeSet], Bin) #u es si se enciende el generador. u = 1: Se enciende i en el tiempo t, u = 0: No se enciende i en t.
    @variable(model, v[GeneratorSet,TimeSet], Bin) #v es si se apaga el generador.  v = 1: Se apaga i en el tiempo t, v = 0: No se apaga i en t.
    @variable(model, Pg[GeneratorSet,TimeSet]) #Pg : Cantidad de energía generada en MWh
    @variable(model, Theta[BusSet,TimeSet]) # Creo que Theta es el defase (angulo)

    @objective(model, Min, sum(GeneratorFixedCostInUSDperHour[i] * x[i,t]
        + GeneratorStartUpCostInUSD[i] * u[i,t]
        + GeneratorVariableCostInUSDperMWh[i] * Pg[i,t] for i in GeneratorSet, t in TimeSet))

    @constraint(model, LogicConstraintBorder[i in GeneratorSet, t in 1:1], x[i,t] - 0 == u[i,t] - v[i,t]) # Funciones lógicas
    @constraint(model, LogicConstraint[i in GeneratorSet, t in 2:T], x[i,t] - x[i,t-1] == u[i,t] - v[i,t])

    @constraint(model, PMinConstraint[i in GeneratorSet, t in 1:T], GeneratorPminInMW[i] * x[i,t] <= Pg[i,t]) # Pmin <= Pg
    @constraint(model, PMaxConstraint[i in GeneratorSet, t in 1:T], Pg[i,t] <= GeneratorPmaxInMW[i] * x[i,t]) # Pmax >= Pg

    @constraint(model, FixAngleAtReferenceBusConstraint[i in 1:1, t in 1:T], Theta[i,t] == 0) # Angulo del bus de referencia

    @constraint(model, DCPowerFlowConstraint[i in BusSet, t in 1:T], 
        sum(Pg[k,t] for k in GeneratorSet if GeneratorBusLocation[k] == i)
        - Pd[i][t]
        == sum( (1/LineReactance[l]) * (Theta[LineFromBus[l],t] - Theta[LineToBus[l],t]) for l in LineSet if LineFromBus[l] == i)
        + sum( (1/LineReactance[l]) * (Theta[LineToBus[l],t] - Theta[LineFromBus[l],t]) for l in LineSet if LineToBus[l] == i))


    #Min Up/Down:/(segun yo estas estan malas)
    @constraint(model, MinEncendido[i in GeneratorSet, t in 1:T-GeneratorMinimumUpTimeInHours[i]], sum(x[i,k] 
    for k in t:(t+GeneratorMinimumUpTimeInHours[i]-1)) >= GeneratorMinimumUpTimeInHours[i]*u[i,t])
    
    @constraint(model, MinEncendido2[i in GeneratorSet, t in T-GeneratorMinimumUpTimeInHours[i]+1:T], sum(x[i,k] - u[i,t] 
    for k in t:T) >= 0)    
    
    #Min Up/Down:(segun yo estas estan malas)
    @constraint(model, MinApagado[i in GeneratorSet, t in 1:T-GeneratorMinimumDownTimeInHours[i]], sum(1-x[i,k] 
    for k in t:(t+GeneratorMinimumDownTimeInHours[i]-1)) >= GeneratorMinimumDownTimeInHours[i]*v[i,t])

    @constraint(model, MinApagado2[i in GeneratorSet, t in T-GeneratorMinimumDownTimeInHours[i]+1:T], sum(1 - x[i,k] - v[i,t] 
    for k in t:T) >= 0)
    
    # #LO QUE YO HICE
    # @constraint(model, MinEncendido[i in GeneratorSet, t in 1:T-GeneratorMinimumUpTimeInHours[i]], sum(x[i,k] 
    # for k in t-:(t+GeneratorMinimumUpTimeInHours[i]-1)) >= GeneratorMinimumUpTimeInHours[i]*u[i,t])

    #Ramp Down 
    @constraint(model, RampasDown[i in GeneratorSet, t in 2:T], -GeneratorRampInMW[i]*x[i,t] 
        - GeneratorStartUpShutDownRampInMW[i]*v[i,t] <= Pg[i,t] - Pg[i,t-1])      
    #Ramp Up
    @constraint(model, RampasUp[i in GeneratorSet, t in 2:T], Pg[i,t] - Pg[i,t-1] <= GeneratorRampInMW[i]*x[i,t-1] + 
        GeneratorStartUpShutDownRampInMW[i]*u[i,t])#se pone t-1 ya que si se pone t cuando se prende se sumarian las dos ramplas

    # transmission line limits
    @constraint(model, CapacidadesLineas[i in LineSet, t in 1:T], -LineMaxFlow[i]<= (1/LineReactance[i]) * (Theta[LineFromBus[i],t] - 
        Theta[LineToBus[i],t]) <= LineMaxFlow[i])
    
    # Optimizacion
    JuMP.optimize!(model)

    return [model,x,u,v,Pg]
end

### Unit commitment example ###



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

LineFromBus = frombus_lines
LineToBus = tobus_lines
LineReactance = Xbus_lines
LineMaxFlow = fmax_lines

Data = [BusSet,TimeSet,GeneratorSet,LineSet,Pd,GeneratorBusLocation,GeneratorPminInMW,
GeneratorPmaxInMW,GeneratorRampInMW,GeneratorStartUpShutDownRampInMW,GeneratorMinimumUpTimeInHours,
GeneratorMinimumDownTimeInHours,GeneratorStartUpCostInUSD,GeneratorFixedCostInUSDperHour,
GeneratorVariableCostInUSDperMWh,GeneratorVariableCostInUSDperMWh,LineFromBus,LineToBus,
LineReactance,LineMaxFlow]

Results = UnitCommitmentFunction(Data)
model = Results[1]; x = Results[2]; u = Results[3]; v = Results[4]; Pg = Results[5];

println("Total cost: ", JuMP.objective_value(model))
for i in GeneratorSet
    for t in TimeSet
        println("i, t, x[i,t], Pg[i,t]: ", i, ", ", t, ", ", JuMP.value(x[i,t]), ", ", JuMP.value(Pg[i,t]))
    end
end
