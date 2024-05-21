using XLSX, Statistics
include("Tarea 2/P1/estructuras.jl")

caso_014 = XLSX.readxlsx("Tarea 2/P1/Case014.xlsx")

Buses = caso_014["Buses"]
Demand = caso_014["Demand"]
Generators = caso_014["Generators"]
Lines = caso_014["Lines"]
Renewables = caso_014["Renewables"]

#------ LECTURA DE DEMANDA ----------#

lectura_demanda = Demand["B3:Y16"]

demanda = []

for j in 1:14
    lista_barra = []
    for i in 1:24
        push!(lista_barra, lectura_demanda[14*(i-1)+j])
    end
    push!(loads_list, Loads(j, lista_barra))
end

# Imprimir las instancias creadas para verificar
for load in loads_list
    println(load)
end
