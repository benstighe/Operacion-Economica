using XLSX, Statistics

caso_014 = XLSX.readxlsx("Case014.xlsx")

Buses = caso_014["Buses"]
Demand = caso_014["Demand"]
Generators = caso_014["Generators"]
Lines = caso_014["Lines"]
Renewables = caso_014["Renewables"]

