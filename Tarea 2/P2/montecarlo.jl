using Distributions, Plots
include("lectura_datos118.jl")

# Generar rangos de κ_t utilizando LinRange
κ_t_eolico = LinRange(14.70, 30.92, 24) / 100
κ_t_solar = LinRange(10.20, 14.02, 24) / 100

# Convertir los rangos a arrays para imprimir todos los valores
κ_t_eolico_array = collect(κ_t_eolico)
κ_t_solar_array = collect(κ_t_solar)





#println(lectura_ren_generacion[1,2]) #(gen,hora)
dev_estandar_eolico = lectura_ren_generacion
#eolico
for i in 1:40 
    for t in 1:24
        dev_estandar_eolico[i,t] = lectura_ren_generacion[i,t]*κ_t_eolico_array[t]
    end
end
println(dev_estandar_eolico)
# Imprimir los valores de κ_t
println("κ_t_eolico: ", κ_t_eolico_array)
#println("κ_t_solar: ", κ_t_solar_array)

