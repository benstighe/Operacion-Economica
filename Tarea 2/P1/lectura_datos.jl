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

for i in eachindex(lectura_lineas_reactancia)
        push!(lines_list, Lines(i, lectura_lineas_from_to[i,1], lectura_lineas_from_to[i,2],
             lectura_lineas_max_flow[i], lectura_lineas_reactancia[i]))
end

#-------LECTURA DE GENERADORES------#

lectura_gen_bus = Generadores["B2:B6"]
lectura_gen_pmax = Generadores["C2:C6"]
lectura_gen_pmin = Generadores["D2:D6"]
lectura_gen_cvariable = Generadores["O2:O6"]
lectura_gen_cfijo = Generadores["N2:N6"]
lectura_gen_con = Generadores["M2:M6"]
lectura_gen_ramp = Generadores["G2:G6"]
lectura_gen_Sramp = Generadores["H2:H6"]
lectura_gen_minup = Generadores["I2:I6"]
lectura_gen_mindown = Generadores["J2:J6"]

gen_list = []

for i in eachindex(lectura_gen_bus)
    lectura_gen_bus[i] = parse(Int, lectura_gen_bus[i][4:end])
end


for i in eachindex(lectura_gen_pmin)
    push!(gen_list, Generador(lectura_gen_bus[i], lectura_gen_pmin[i], lectura_gen_pmax[i], lectura_gen_cvariable[i],
        lectura_gen_cfijo[i], lectura_gen_con[i], lectura_gen_ramp[i],lectura_gen_Sramp[i], lectura_gen_minup[i], lectura_gen_mindown[i]))
end


#------Renovables-----#

lectura_ren_bus = Generadores["B7:B8"]
lectura_ren_pmax = Generadores["C7:C8"]
lectura_ren_pmin = Generadores["D7:D8"]
lectura_ren_cvariable = Generadores["O7:O8"]
lectura_ren_cfijo = Generadores["N7:N8"]
lectura_ren_con = Generadores["M7:M8"]
lectura_ren_ramp = Generadores["G7:G8"]
lectura_ren_Sramp = Generadores["H7:H8"]
lectura_ren_minup = Generadores["I7:I8"]
lectura_ren_mindown = Generadores["J7:J8"]

lectura_ren_generacion = Renovables["B3:Y4"]

lista_renovables = []

for i in eachindex(lectura_ren_bus)
    lectura_ren_bus[i] = parse(Int, lectura_ren_bus[i][4:end])
end

for i in eachindex(lectura_ren_bus)
    lista_generacion = []
    for j in 1:24
        push!(lista_generacion, lectura_ren_generacion[i,j])
    end
    push!(lista_renovables, Renewables(lectura_ren_bus[i], lectura_ren_pmin[i], lectura_ren_pmax[i], lectura_ren_cvariable[i],
    lectura_ren_cfijo[i], lectura_ren_con[i], lectura_ren_ramp[i],lectura_ren_Sramp[i], lectura_ren_minup[i], lectura_ren_mindown[i], lista_generacion ))
end


id_buses = [load.ID_Bus for load in loads_list]

bus_gen = [gen.Bus_Conexion for gen in gen_list]
for ren in lista_renovables
    push!(bus_gen, ren.Bus_Conexion)
end

id_lines = [line.ID for line in lines_list]

Pd=[load.Demanda for load in loads_list]

pmax_gen = [gen.Pmax for gen in gen_list]
for ren in lista_renovables
    push!(pmax_gen, ren.Pmax)
end

tipo_gen = ["No renovable" for gen in gen_list]
for ren in lista_renovables
    push!(tipo_gen, "Renovable")
end

prod_gen = [[] for gen in gen_list]
for ren in lista_renovables
    vect=ren.Generation
    push!(prod_gen, vect)
end

pmin_gen = [gen.Pmin for gen in gen_list]
for ren in lista_renovables
    push!(pmin_gen, ren.Pmin)
end

rampin_gen = [gen.Ramp for gen in gen_list]
for ren in lista_renovables
    push!(rampin_gen, ren.Ramp)
end

Srampin_gen = [gen.SRamp for gen in gen_list]
for ren in lista_renovables
    push!(Srampin_gen, ren.SRamp)
end

minup_gen = [gen.min_up for gen in gen_list]
for ren in lista_renovables
    push!(minup_gen, ren.min_up)
end

mindown_gen = [gen.min_down for gen in gen_list]
for ren in lista_renovables
    push!(mindown_gen, ren.min_down)
end

st_cost_gen = [gen.CEncendido for gen in gen_list]
for ren in lista_renovables
    push!(st_cost_gen, ren.CEncendido)
end

fx_cost_gen = [gen.CFijo for gen in gen_list]
for ren in lista_renovables
    push!(fx_cost_gen, ren.CFijo)
end

v_cost_gen = [gen.Cvariable for gen in gen_list]
for ren in lista_renovables
    push!(v_cost_gen, ren.Cvariable)
end

frombus_lines = [line.FromBus for line in lines_list]

tobus_lines = [line.ToBus for line in lines_list]

Xbus_lines = [line.X for line in lines_list]

fmax_lines = [line.Fmax for line in lines_list]

