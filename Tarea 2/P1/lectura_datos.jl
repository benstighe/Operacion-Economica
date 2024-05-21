using XLSX, Statistics
include("estructuras.jl")

caso_014 = XLSX.readxlsx("Tarea 2/P1/Case014.xlsx")

Buses = caso_014["Buses"]
Demanda = caso_014["Demand"]
Generadores = caso_014["Generators"]
Lineas = caso_014["Lines"]
Renovables = caso_014["Renewables"]

#------ LECTURA DE DEMANDA ----------#

lectura_demanda = Demanda["B3:Y16"]

demanda = []
loads_list = []

for j in 1:14
    lista_barra = []
    for i in 1:24
        push!(lista_barra, lectura_demanda[14*(i-1)+j])
    end
    push!(loads_list, Loads(j, lista_barra))
end

#Las estructuras de demandas se guardan en una lista. Para acceder a cada demanda, se puede hacer
# loads_list[i], donde i representa el elemento i de la lista. Para acceder a qué bus está conectado
# es loads_list[i].ID_Bus y para su demanda es loads_list[i].Demanda
# loads_list[i].Demanda[j] te indica la demanda de la hora j para el elemento de la lista i.

#--------- LECTURA DE LINEAS ----------#

lectura_lineas_max_flow = Lineas["G2:G21"]
lectura_lineas_from_to = Lineas["B2:C21"]
lectura_lineas_reactancia = Lineas["E2:E21"]

lines_list = []

for i in 1:length(lectura_lineas_reactancia)
    for j in 1:2
        lectura_lineas_from_to[i,j] = parse(Int, lectura_lineas_from_to[i,j][4:end])
    end
end

for i in 1:length(lectura_lineas_reactancia)
        push!(lines_list, Lines(i, lectura_lineas_from_to[i,1], lectura_lineas_from_to[i,2],
             lectura_lineas_max_flow[i], lectura_lineas_reactancia[i]))
end


println(lines_list)

#-------LECTURA DE GENERADORES------#





