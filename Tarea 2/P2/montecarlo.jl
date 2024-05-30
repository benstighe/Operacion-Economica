
using Distributions, Plots, Random

using Distributions, Plots, Random,Statistics

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
        dev_estandar_solar[i, t] = lectura_ren_generacion[i+40, t] * κ_t_solar_array[t]
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
#-----------------------PARA GRAFICAR LOS 100*24 casos------------------

# # Graficar los 100 escenarios de generación eólica
# plot_eolico = plot(title="Escenarios de generación eólica", xlabel="Hora", ylabel="Generación", label=nothing)

# for escenario in 1:100
#     plot!(1:24, eolico_pronostico_escenarios[:, :, escenario]', alpha=0.3, label=nothing)
# end

# display(plot_eolico)

# # Graficar los 100 escenarios de generación solar
# plot_solar = plot(title="Escenarios de generación solar", xlabel="Hora", ylabel="Generación", label=nothing)

# for escenario in 1:100
#     plot!(1:24, solar_pronostico_escenarios[:, 1:24, escenario]', alpha=0.3, label=nothing)
# end

# display(plot_solar)
#--------------------------------FIN graficar---------------------------

#creo sus largos
eolico_pronostico = zeros(40,24)
solar_pronostico = zeros(20,24)
#para obtener cada uno de los pronosticos, cada elemento es uno de los 100
eolico_montecarlo=[]
solar_montecarlo=[]
#finalmente cada lista tiene cada simulacion para todos los generadores en cada tiempo
suma_eolico_montecarlo=[]
suma_solar_montecarlo=[]
suma_total_montecarlo=[]
#Relleno estas lista_renovables
for semilla in 1:100
    Random.seed!(semilla)
    #eolico
    global eolico_pronostico = zeros(40,24)
    semilla_eolico_suma=[]
    for t in 1:24
        suma_eolico=0
        for j in 1:40
            dist = Normal(0, dev_estandar_eolico[j,t])
            epsilon = rand(dist, 1)
            global eolico_pronostico[j,t] = max(0.0, lectura_ren_generacion[j,t] + epsilon[1])
            suma_eolico=suma_eolico+eolico_pronostico[j,t]
        end 
        push!(semilla_eolico_suma, suma_eolico)
    end 
    push!(eolico_montecarlo, deepcopy(eolico_pronostico))
    push!(suma_eolico_montecarlo, deepcopy(semilla_eolico_suma))
    #solar
    semilla_solar_suma=[]
    global solar_pronostico = zeros(20,24)
    for t in 1:24
        suma_solar=0
        for j in 1:20
            dist = Normal(0, dev_estandar_solar[j,t])
            epsilon = rand(dist, 1)
            global solar_pronostico[j,t] = max(0.0, lectura_ren_generacion[j+40,t] + epsilon[1])
            suma_solar=suma_solar+solar_pronostico[j,t]
        end 
        push!(semilla_solar_suma, suma_solar)
    end 
    suma_total=deepcopy(semilla_solar_suma) .+ deepcopy(semilla_eolico_suma)
    push!(solar_montecarlo, deepcopy(solar_pronostico))
    push!(suma_solar_montecarlo, deepcopy(semilla_solar_suma))
    push!(suma_total_montecarlo, deepcopy(suma_total))
end
#Obtengo los percentiles de cada una
eol_percentil_90_sup=[]
eol_percentil_90_inf=[]
eol_percentil_99_sup=[]
eol_percentil_99_inf=[]
eol_promedio=[]
sol_percentil_90_sup=[]
sol_percentil_90_inf=[]
sol_percentil_99_sup=[]
sol_percentil_99_inf=[]
sol_promedio=[]
tot_percentil_90_sup=[]
tot_percentil_90_inf=[]
tot_percentil_99_sup=[]
tot_percentil_99_inf=[]
tot_promedio=[]
eol_90_sup=[]
for t in 1:24
    push!(eol_percentil_90_sup, mean([lista[t] for lista in suma_eolico_montecarlo])+(std([lista[t] for lista in suma_eolico_montecarlo])*1.645))
    push!(eol_percentil_90_inf,mean([lista[t] for lista in suma_eolico_montecarlo])-(std([lista[t] for lista in suma_eolico_montecarlo])*1.645))
    push!(eol_percentil_99_sup,mean([lista[t] for lista in suma_eolico_montecarlo])+(std([lista[t] for lista in suma_eolico_montecarlo])*2.575))
    push!(eol_percentil_99_inf ,mean([lista[t] for lista in suma_eolico_montecarlo])-(std([lista[t] for lista in suma_eolico_montecarlo])*2.575))
    push!(eol_promedio , mean([lista[t] for lista in suma_eolico_montecarlo]))
    push!(sol_percentil_90_sup,  mean([lista[t] for lista in suma_solar_montecarlo])+(std([lista[t] for lista in suma_solar_montecarlo])*1.645))
    push!(sol_percentil_90_inf , mean([lista[t] for lista in suma_solar_montecarlo])-(std([lista[t] for lista in suma_solar_montecarlo])*1.645))
    push!(sol_percentil_99_sup , mean([lista[t] for lista in suma_solar_montecarlo])+(std([lista[t] for lista in suma_solar_montecarlo])*2.575))
    push!(sol_percentil_99_inf , mean([lista[t] for lista in suma_solar_montecarlo])-(std([lista[t] for lista in suma_solar_montecarlo])*2.575))
    push!(sol_promedio , mean([lista[t] for lista in suma_solar_montecarlo]))
    push!(tot_percentil_90_sup , mean([lista[t] for lista in suma_total_montecarlo])+(std([lista[t] for lista in suma_total_montecarlo])*1.645))
    push!(tot_percentil_90_inf , mean([lista[t] for lista in suma_total_montecarlo])-(std([lista[t] for lista in suma_total_montecarlo])*1.645))
    push!(tot_percentil_99_sup , mean([lista[t] for lista in suma_total_montecarlo])+(std([lista[t] for lista in suma_total_montecarlo])*2.575))
    push!(tot_percentil_99_inf , mean([lista[t] for lista in suma_total_montecarlo])-(std([lista[t] for lista in suma_total_montecarlo])*2.575))
    push!(tot_promedio , mean([lista[t] for lista in suma_total_montecarlo]))
    # push!(eol_percentil_90_sup, quantile([lista[t] for lista in suma_eolico_montecarlo], 0.90))
    # push!(eol_percentil_90_inf,quantile([lista[t] for lista in suma_eolico_montecarlo], 0.10))
    # push!(eol_percentil_99_sup,quantile([lista[t] for lista in suma_eolico_montecarlo], 0.99))
    # push!(eol_percentil_99_inf ,quantile([lista[t] for lista in suma_eolico_montecarlo], 0.01))
    # push!(eol_promedio , mean([lista[t] for lista in suma_eolico_montecarlo]))
    # push!(sol_percentil_90_sup, quantile([lista[t] for lista in suma_solar_montecarlo], 0.90))
    # push!(sol_percentil_90_inf , quantile([lista[t] for lista in suma_solar_montecarlo], 0.10))
    # push!(sol_percentil_99_sup , quantile([lista[t] for lista in suma_solar_montecarlo], 0.99))
    # push!(sol_percentil_99_inf , quantile([lista[t] for lista in suma_solar_montecarlo], 0.01))
    # push!(sol_promedio , mean([lista[t] for lista in suma_solar_montecarlo]))
    # push!(tot_percentil_90_sup , quantile([lista[t] for lista in suma_total_montecarlo], 0.90))
    # push!(tot_percentil_90_inf , quantile([lista[t] for lista in suma_total_montecarlo], 0.10))
    # push!(tot_percentil_99_sup , quantile([lista[t] for lista in suma_total_montecarlo], 0.99))
    # push!(tot_percentil_99_inf , quantile([lista[t] for lista in suma_total_montecarlo], 0.01))
    # push!(tot_promedio , mean([lista[t] for lista in suma_total_montecarlo]))
end

# Iniciar el gráfico
horas = 1:24
plot()
plot(title = "Generación Eólica")
for lista in suma_eolico_montecarlo
    plot!(horas, lista, label="", lw=1)  # `label=""` para no mostrar etiquetas y `lw=1` para líneas delgadas
end
plot!(horas,eol_percentil_90_inf,label="percentil_90(inf)",lw=5,color=:blue)
plot!(horas,eol_percentil_90_sup,label="percentil_90(sup)",lw=5,color=:blue)
plot!(horas,eol_percentil_99_inf,label="percentil_99(inf)",lw=5,color=:green)
plot!(horas,eol_percentil_99_sup,label="percentil_99(sup)",lw=5,color=:green)
plot!(horas,eol_promedio,label="Media",lw=3,color=:red)
display(plot!())
#Solar
plot()
plot(title = "Generación Solar")
for lista in suma_solar_montecarlo
    plot!(horas, lista, label="", lw=1)  # `label=""` para no mostrar etiquetas y `lw=1` para líneas delgadas
end
plot!(horas,sol_percentil_90_inf,label="percentil_90(inf)",lw=2,color=:blue)
plot!(horas,sol_percentil_90_sup,label="percentil_90(sup)",lw=2,color=:blue)
plot!(horas,sol_percentil_99_inf,label="percentil_99(inf)",lw=2,color=:green)
plot!(horas,sol_percentil_99_sup,label="percentil_99(sup)",lw=2,color=:green)
plot!(horas,sol_promedio,label="Media",lw=2,color=:red)
display(plot!())
plot()
plot(title = "Generación Total")
for lista in suma_total_montecarlo
    plot!(horas, lista, label="", lw=1)  # `label=""` para no mostrar etiquetas y `lw=1` para líneas delgadas
end
plot!(horas,tot_percentil_90_inf,label="percentil_90(inf)",lw=3,color=:blue)
plot!(horas,tot_percentil_90_sup,label="percentil_90(sup)",lw=3,color=:blue)
plot!(horas,tot_percentil_99_inf,label="percentil_99(inf)",lw=3,color=:green)
plot!(horas,tot_percentil_99_sup,label="percentil_99(sup)",lw=3,color=:green)
plot!(horas,tot_promedio,label="Media",lw=3,color=:red)
display(plot!())
reserva_90=tot_promedio.-tot_percentil_90_inf
reserva_99=tot_promedio.-tot_percentil_99_inf


for iter in 1:100
    lista_datos_eolico=collect(eachrow(eolico_montecarlo[iter]))
    
    lista_datos_solar=collect(eachrow(solar_montecarlo[iter]))
   
    global prod_gen1 = [[] for gen in gen_list]
   
    for ren in lista_datos_eolico
        push!(prod_gen1, ren)
    end
    for ren in lista_datos_solar
        push!(prod_gen1, ren)
    end

end
