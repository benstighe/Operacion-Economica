using SDDP
using Gurobi
using Plots
using DataFrames
using StatsPlots
using Statistics
function subproblem_builder(subproblem::Model, node::Int)
    # State variables
    @variable(subproblem, 0 <= volume <= 300, SDDP.State, initial_value = 100)
    # Control variables
    @variables(subproblem, begin
        50>=thermal_generation_1 >= 0
        50>=thermal_generation_2 >= 0
        50>=thermal_generation_3 >= 0
        150>=hydro_generation >= 0
    end)
    # Random variables
    @variable(subproblem, inflow)
    Ω = [5 * i for i in 1:20]
    P = [0.05 for _ in 1:20]
    SDDP.parameterize(subproblem, Ω, P) do ω
        return JuMP.fix(inflow, ω)
    end
    # Transition function and constraints
    @constraints(
        subproblem,
        begin
            volume.out == volume.in - hydro_generation + inflow
            demand_constraint, hydro_generation + thermal_generation_1+thermal_generation_2+thermal_generation_3 == 150
        end
    )
    # Stage-objective
    @stageobjective(subproblem, 50* thermal_generation_1+100* thermal_generation_2+150* thermal_generation_3)
    return subproblem
end
model = SDDP.LinearPolicyGraph(
    subproblem_builder;
    stages = 100, #cantidad semanas
    sense = :Min,
    lower_bound = 0.0,
    optimizer = Gurobi.Optimizer,
)
SDDP.train(model; iteration_limit = 50) #ESTE ES EL N QUE PIDEN CAMBIAR
simulations = SDDP.simulate(
    # The trained model to simulate.
    model,
    # The number of replications.
    100,
    # A list of names to record the values of.
    [:volume, :thermal_generation_1,:thermal_generation_2,:thermal_generation_3, :hydro_generation ],
)


# Extraer el volumen de agua almacenada al final de cada semana para cada replicación
volumen_almacenado = DataFrame(Semana = Int[], Replicación = Int[], Volumen = Float64[])

for replication in 1:100
    for stage in 1:100
        push!(volumen_almacenado, (Semana = stage, Replicación = replication, Volumen = simulations[replication][stage][:volume].out))
    end
end
#println(volumen_almacenado)
# Convertir el DataFrame a un formato largo
long_df = stack(volumen_almacenado, [:Volumen], [:Semana, :Replicación])
#println(long_df)
# Graficar
plot()
for replication in 1:100
    data = filter(row -> row[:Replicación] == replication, volumen_almacenado)
    plot!(data[!, :Semana], data[!, :Volumen], label=false)
end

# Configuración de la gráfica
title!("Volumen de Agua Almacenada al Final de Cada Semana")
xlabel!("Semana")
ylabel!("Volumen Almacenado [MWh]")
display(plot!())
semanas = unique(volumen_almacenado[!, :Semana])
mean_volumes = [mean(filter(row -> row[:Semana] == semana, volumen_almacenado)[!, :Volumen]) for semana in semanas]
median_volumes = [median(filter(row -> row[:Semana] == semana, volumen_almacenado)[!, :Volumen]) for semana in semanas]
std_volumes = [std(filter(row -> row[:Semana] == semana, volumen_almacenado)[!, :Volumen]) for semana in semanas]
percentil_90 = [quantile(filter(row -> row[:Semana] == semana, volumen_almacenado)[!, :Volumen],0.9) for semana in semanas]
percentil_10 = [quantile(filter(row -> row[:Semana] == semana, volumen_almacenado)[!, :Volumen],0.1) for semana in semanas]

# Graficar media, mediana e intervalos de confianza
plot()
plot(semanas, mean_volumes, label="Media", lw=2)
plot!(semanas, median_volumes, label="Mediana", lw=2)
plot!(semanas, percentil_90,label="Percentil 90")
plot!(semanas, percentil_10,label="Percentil 10")

# Configuración de la gráfica
title!("Media, Mediana e Intervalos de Confianza del Volumen de Agua Almacenada")
xlabel!("Semana")
ylabel!("Volumen Almacenado [MWh]")
display(plot!())
