using Distributions, Plots, Random
include("lectura_datos118.jl")

Random.seed!(69)

# Generar rangos de κ_t utilizando LinRange
κ_t_eolico = LinRange(14.70, 30.92, 24) / 100
κ_t_solar = LinRange(10.20, 14.02, 24) / 100

# Convertir los rangos a arrays para imprimir todos los valores
κ_t_eolico_array = collect(κ_t_eolico)
κ_t_solar_array = collect(κ_t_solar)





#println(lectura_ren_generacion[1,2]) #(gen,hora)
dev_estandar_eolico = lectura_ren_generacion[1:40, 1:24]
dev_estandar_solar = lectura_ren_generacion[41:60, 1:24]
#eolico
for i in 1:40 
    for t in 1:24
        dev_estandar_eolico[i,t] = lectura_ren_generacion[i,t]*κ_t_eolico_array[t]
    end
end
#solar
for i in 1:20 
    for t in 1:24
        dev_estandar_solar[i,t] = lectura_ren_generacion[i,t]*κ_t_solar_array[t]
    end
end

eolico_pronostico = lectura_ren_generacion[1:40, 1:24]
solar_pronostico = lectura_ren_generacion[41:60, 1:24]

eolico_montecarlo=[]
solar_montecarlo=[]
#finalmente cada lista tiene cada simulacion para todos los generadores en cada tiempo
suma_eolico_montecarlo=[]#arreglar que sea para cada t
suma_solar_montecarlo=[]
for semilla in 1:100
    Random.seed!(semilla)
    #eolico
    suma_eolico=0
    for j in 1:40
        for t in 1:24
            dist = Normal(0, dev_estandar_eolico[j,t])
            epsilon = rand(dist, 1)
            global eolico_pronostico[j,t] = max(0.0, lectura_ren_generacion[j,t] + epsilon[1])
            suma_eolico=suma_eolico+eolico_pronostico[j,t]
        end 
    end 
    push!(eolico_montecarlo, eolico_pronostico)
    push!(suma_eolico_montecarlo, suma_eolico)
    #solar
    suma_solar=0
    for j in 1:20
        for t in 6:19
            dist = Normal(0, dev_estandar_solar[j,t])
            epsilon = rand(dist, 1)
            global solar_pronostico[j,t] = max(0.0, lectura_ren_generacion[j+40,t] + epsilon[1])
            suma_solar=suma_solar+solar_pronostico[j,t]
        end 
    end 
    vcat(eolico_pronostico,solar_pronostico)
    println(eolico_pronostico)
end
