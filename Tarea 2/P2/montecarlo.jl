using Distributions, Plots

# Generar rangos de κ_t utilizando LinRange
using Distributions, Plots

# Generar rangos de κ_t utilizando LinRange
κ_t_eolico = LinRange(14.70, 30.92, 24) / 100
κ_t_solar = LinRange(10.20, 14.02, 24) / 100

# Convertir los rangos a arrays para imprimir todos los valores
κ_t_eolico_array = collect(κ_t_eolico)
κ_t_solar_array = collect(κ_t_solar)

# Imprimir los valores de κ_t
println("κ_t_eolico: ", κ_t_eolico_array)
println("κ_t_solar: ", κ_t_solar_array)
