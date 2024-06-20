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

iteration_limits = [5, 20, 50, 100]
results = DataFrame(iteration_limit = Int[], cost = Float64[], price = Float64[])

for limit in iteration_limits
    println("Training with iteration limit: $limit")
    model = SDDP.LinearPolicyGraph(
        subproblem_builder;
        stages = 100, # cantidad semanas
        sense = :Min,
        lower_bound = 0.0,
        optimizer = Gurobi.Optimizer,
    )
    
    SDDP.train(model; iteration_limit = limit)
    
    V = SDDP.ValueFunction(model; node = 1)
    cost, price_dict = SDDP.evaluate(V, Dict("volume" => 100))
    price = price_dict[:volume]
    
    println("Iteration limit: $limit, Cost: $cost, Price: $price")
    push!(results, (iteration_limit = limit, cost = cost, price = price))
end

# Graficar los resultados
plot()
plot(results.iteration_limit, results.cost, label="Cost", lw=2, marker=:o)
title!("Cost  vs Iteration Limit")
xlabel!("Iteration Limit")
ylabel!("Value")
display(plot!())

plot()
plot!(results.iteration_limit, results.price, label="Price", lw=2, marker=:o)
title!("Price vs Iteration Limit")
xlabel!("Iteration Limit")
ylabel!("Value")
display(plot!())