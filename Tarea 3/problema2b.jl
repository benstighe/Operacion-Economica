using SDDP
using Gurobi
using Plots
using DataFrames
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

function calculate_bounds(iteration_limit)
    model = SDDP.LinearPolicyGraph(
        subproblem_builder;
        stages = 100, # cantidad semanas
        sense = :Min,
        lower_bound = 0.0,
        optimizer = Gurobi.Optimizer,
    )

    SDDP.train(model; iteration_limit = iteration_limit)

    simulations = SDDP.simulate(
        # The trained model to simulate.
        model,
        # The number of replications.
        2000,
        # A list of names to record the values of.
        [:volume, :thermal_generation_1, :thermal_generation_2, :thermal_generation_3, :hydro_generation],
    )

    objectives = map(simulations) do simulation
        return sum(stage[:stage_objective] for stage in simulation)
    end

    μ, ci = SDDP.confidence_interval(objectives, 1.96) # para el 95%
    lower_bound = SDDP.calculate_bound(model)
    upper_bound = μ + ci

    return lower_bound, upper_bound
end

# Valores de iteration_limit
iteration_limits = [5, 20, 50, 100]

# Almacenar resultados
results = DataFrame(iteration_limit = Int[], lower_bound = Float64[], upper_bound = Float64[])

for limit in iteration_limits
    lower_bound, upper_bound = calculate_bounds(limit)
    push!(results, (iteration_limit = limit, lower_bound = lower_bound, upper_bound = upper_bound))
end

# Graficar resultados
plot(results.iteration_limit, results.lower_bound, label="Lower Bound", lw=2, marker=:o)
plot!(results.iteration_limit, results.upper_bound, label="Upper Bound", lw=2, marker=:o)
title!("Lower Bound y Upper Bound vs Iteration Limit")
xlabel!("Iteration Limit")
ylabel!("Bound Value")
