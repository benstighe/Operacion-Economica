
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

dev_estandar_eolico = zeros(40,24)
dev_estandar_solar = zeros(20,24)

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

for t in 1:24
    global varianza_tot=0
    global media=0
    for i in 1:40
        global varianza_tot=varianza_tot+(dev_estandar_eolico[i, t]^2)
        global media= media + lectura_ren_generacion[i,t]
    end
    push!(eol_promedio,media)
    push!(eol_percentil_90_sup,media+((varianza_tot^(0.5))*1.645))
    push!(eol_percentil_90_inf,media-((varianza_tot^(0.5))*1.645))
    push!(eol_percentil_99_sup,media+((varianza_tot^(0.5))*2.575))
    push!(eol_percentil_99_inf,media-((varianza_tot^(0.5))*2.575))
end

for t in 1:24
    global varianza_tot=0
    global media=0
    for i in 1:20
        global varianza_tot=varianza_tot+(dev_estandar_solar[i, t]^2)
        global media= media + lectura_ren_generacion[i+40,t]
    end
    push!(sol_promedio,media)
    push!(sol_percentil_90_sup,media+((varianza_tot^(0.5))*1.645))
    push!(sol_percentil_90_inf,media-((varianza_tot^(0.5))*1.645))
    push!(sol_percentil_99_sup,media+((varianza_tot^(0.5))*2.575))
    push!(sol_percentil_99_inf,media-((varianza_tot^(0.5))*2.575))
end

reserva_90_of=[]
reserva_99_of=[]
for t in 1:24
    global varianza_tot=0
    global media=0
    for i in 1:40
        global varianza_tot=varianza_tot+(dev_estandar_eolico[i, t]^2)
        global media= media + lectura_ren_generacion[i,t]
    end
    for i in 1:20
        global varianza_tot=varianza_tot+(dev_estandar_solar[i, t]^2)
        global media= media + lectura_ren_generacion[i+40,t]
    end
    global desv_total=varianza_tot^(0.5)
    push!(tot_promedio,media)
    push!(tot_percentil_90_sup,media+(desv_total*1.645))
    push!(tot_percentil_90_inf,media-(desv_total*1.645))
    push!(tot_percentil_99_sup,media+(desv_total*2.575))
    push!(tot_percentil_99_inf,media-(desv_total*2.575))
    push!(reserva_90_of,desv_total*1.645)
    push!(reserva_99_of,desv_total*2.575)
end

reserva_90_of_rial=[]
reserva_99_of_rial=[]
reserva_90_of_rial_g=[]
reserva_99_of_rial_g=[]
#otra forma
for t in 1:24
    desveol=eol_promedio[t]*κ_t_eolico_array[t]
    desvsol=sol_promedio[t]*κ_t_solar_array[t]
    desvgrande=(eol_promedio[t]+sol_promedio[t])*(((40/60)*κ_t_eolico_array[t])+((20/60)*κ_t_solar_array[t]))
    desv= (((40/60)*((desveol)^2))+((20/60)*((desvsol)^2)))^(0.5)
    push!(reserva_90_of_rial,desv*1.645)
    push!(reserva_99_of_rial,desv*2.575)
    push!(reserva_90_of_rial_g,desvgrande*1.645)
    push!(reserva_99_of_rial_g,desvgrande*2.575)
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



# for iter in 1:100
#     global lista_datos_eolico=collect(eachrow(eolico_montecarlo[iter]))
    
#     global lista_datos_solar=collect(eachrow(solar_montecarlo[iter]))
   
#     global prod_gen1 = [[] for gen in gen_list]
   
#     for ren in lista_datos_eolico
#         push!(prod_gen1, ren)
#     end
#     for ren in lista_datos_solar
#         push!(prod_gen1, ren)
#     end
# end



# println("Reserva 90 antigua",reserva_90)
# println("Reserva 90 nueva",reserva_90_of)
# println("Reserva 99 ",reserva_99_of)
