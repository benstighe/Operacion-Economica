using Distributions, Plots
include("lectura_datos118.jl")

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


#eolico
for j in 1:40
    for t in 1:24
        dist = Normal(0,dev_estandar_eolico[j,t])
        x = rand(dist,1)
        println(x)
    end 
end 




#solar
