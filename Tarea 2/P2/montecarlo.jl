using Distributions, Plots, Random

include("lectura_datos118.jl")

Random.seed!(69)

# Generar rangos de κ_t utilizando LinRange
κ_t_eolico = LinRange(14.70, 30.92, 24) / 100
κ_t_solar = LinRange(10.20, 14.02, 24) / 100

# Convertir los rangos a arrays para imprimir todos los valores
κ_t_eolico_array = collect(κ_t_eolico)
κ_t_solar_array = collect(κ_t_solar)

dev_estandar_eolico = lectura_ren_generacion[1:40, 1:24]
dev_estandar_solar = lectura_ren_generacion[41:60, 1:24]

for i in 1:40
    for t in 1:24
        dev_estandar_eolico[i, t] = lectura_ren_generacion[i, t] * κ_t_eolico_array[t]
    end
end

for i in 1:20
    for t in 1:24
        dev_estandar_solar[i, t] = lectura_ren_generacion[i, t] * κ_t_solar_array[t]
    end
end

# Inicializar matrices para almacenar los escenarios
eolico_pronostico_escenarios = zeros(40, 24, 100)
solar_pronostico_escenarios = zeros(20, 24, 100)

# Generar 100 escenarios para eólica
for escenario in 1:100
    for j in 1:40
        for t in 1:24
            dist = Normal(0, dev_estandar_eolico[j, t])
            epsilon = rand(dist, 1)[1]
            eolico_pronostico_escenarios[j, t, escenario] = max(0.0, lectura_ren_generacion[j, t] + epsilon)
        end
    end
end

# Generar 100 escenarios para solar
for escenario in 1:100
    for j in 1:20
        for t in 6:19
            dist = Normal(0, dev_estandar_solar[j, t])
            epsilon = rand(dist, 1)[1]
            solar_pronostico_escenarios[j, t, escenario] = max(0.0, lectura_ren_generacion[j + 40, t] + epsilon)
        end
    end
end

# Graficar los 100 escenarios de generación eólica
plot_eolico = plot(title="Escenarios de generación eólica", xlabel="Hora", ylabel="Generación", label=nothing)

for escenario in 1:100
    plot!(1:24, eolico_pronostico_escenarios[:, :, escenario]', alpha=0.3, label=nothing)
end

display(plot_eolico)

# Graficar los 100 escenarios de generación solar
plot_solar = plot(title="Escenarios de generación solar", xlabel="Hora", ylabel="Generación", label=nothing)

for escenario in 1:100
    plot!(1:24, solar_pronostico_escenarios[:, 1:24, escenario]', alpha=0.3, label=nothing)
end

display(plot_solar)