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
        50 >= thermal_generation_1 >= 0
        50 >= thermal_generation_2 >= 0
        50 >= thermal_generation_3 >= 0
        150 >= hydro_generation >= 0
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
            demand_constraint, hydro_generation + thermal_generation_1 + thermal_generation_2 + thermal_generation_3 == 150
        end
    )
    # Stage-objective
    @stageobjective(subproblem, 50 * thermal_generation_1 + 100 * thermal_generation_2 + 150 * thermal_generation_3)
    return subproblem
end

model = SDDP.LinearPolicyGraph(
    subproblem_builder;
    stages = 100, # cantidad semanas
    sense = :Min,
    lower_bound = 0.0,
    optimizer = Gurobi.Optimizer,
)

SDDP.train(model; iteration_limit = 20) # ESTE ES EL N QUE PIDEN CAMBIAR

simulations = SDDP.simulate(
    model,
    100,
    [:volume, :thermal_generation_1, :thermal_generation_2, :thermal_generation_3, :hydro_generation],
)

# Extraer el volumen de agua almacenada al final de cada semana para cada replicación
volumen_almacenado = DataFrame(Semana = Int[], Replicación = Int[], Volumen = Float64[])

for replication in 1:100
    for stage in 1:100
        push!(volumen_almacenado, (Semana = stage, Replicación = replication, Volumen = simulations[replication][stage][:volume].out))
    end
end

# Convertir el DataFrame a un formato largo
long_df = stack(volumen_almacenado, [:Volumen], [:Semana, :Replicación])
#juntarlamediaymediana
volumen_summary = combine(groupby(volumen_almacenado, :Semana), 
    :Volumen => mean => :Mean_Volumen,
    :Volumen => median => :Median_Volumen,
    :Volumen => (x -> quantile(x, 0.10)) => :P10_Volumen,
    :Volumen => (x -> quantile(x, 0.90)) => :P90_Volumen)

# media y percentil¿
p1 = plot(volumen_summary.Semana, volumen_summary.Mean_Volumen, 
    label="Mean Volumen", linewidth=2, color=:blue)
plot!(volumen_summary.Semana, volumen_summary.Median_Volumen, 
    label="Median Volumen", linewidth=2, linestyle=:dash, color=:green)
plot!(volumen_summary.Semana, volumen_summary.P10_Volumen, 
    label="10th Percentile Volumen", linewidth=1, linestyle=:dot, color=:red)
plot!(volumen_summary.Semana, volumen_summary.P90_Volumen, 
    label="90th Percentile Volumen", linewidth=1, linestyle=:dot, color=:red)


title!(p1, "Volumen de Agua Almacenada al Final de Cada Semana")
xlabel!(p1, "Semana")
ylabel!(p1, "Volumen Almacenado [MWh]")

# dsitribucion??
heatmap_data = reshape(volumen_almacenado.Volumen, 100, 100)
p2 = heatmap(1:100, 1:100, heatmap_data,
    c=:viridis, xlabel="Semana", ylabel="Replicación", colorbar_title="Volumen",
    title="Distribución del Volumen de Agua Almacenada")

plot(p1, p2, layout=(2, 1), size=(800, 600))

# replication = 1
# stage = 2
# println(simulations[replication][stage])
# outgoing_volume = map(simulations[1]) do node
#     return node[:volume].out
# end

# thermal_generation = map(simulations[1]) do node
#     return node[:thermal_generation]
# end
# objectives = map(simulations) do simulation
#     return sum(stage[:stage_objective] for stage in simulation)
# end

# μ, ci = SDDP.confidence_interval(objectives)
# println("Confidence interval: ", μ, " ± ", ci)