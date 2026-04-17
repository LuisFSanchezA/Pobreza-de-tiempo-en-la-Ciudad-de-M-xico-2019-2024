* ==============================================================================
* PROYECTO: Pobreza de tiempo en la CDMX: efectos de género, territorio y conyugalidad
* AUTORES: Luis Felipe Sánchez Ascencio, David Orlando Ramírez Naranjo, Nayeli Pérez Juárez
* DESCRIPCIÓN: Script para procesamiento de microdatos ENUT 2019 y 2024, cálculo 
* de umbrales de pobreza de tiempo y estimación de modelos logísticos complejos.
* ==============================================================================

clear all
set more off
version 17

* ------------------------------------------------------------------------------
* 0. CONFIGURACIÓN DEL DIRECTORIO DE TRABAJO Y RUTAS
* ------------------------------------------------------------------------------
* INSTRUCCIÓN: Cambia la ruta del 'global workdir' a la ubicación de tu repositorio local
global workdir "C:/Ruta/A/Tu/Repositorio/Pobreza_Tiempo_CDMX"
global data2019 "$workdir/enut_2019_bd_csv/enut_2019"
global data2024 "$workdir/enut_2024_bd_csv/enut_2024"
global outdir   "$workdir/output"

capture mkdir "$outdir"

* ==============================================================================
* PARTE I: PROCESAMIENTO Y LIMPIEZA - ENUT 2019
* ==============================================================================

cd "$data2019"
use "TMODULO_2019.dta", clear

// 1. Filtramos solo la CDMX
keep if ent == 09

* ------------------------------------------------------------------------------
* 2. TRABAJO REMUNERADO BÁSICO (Lunes a domingo)
* ------------------------------------------------------------------------------
foreach var in p5_3_1 p5_3_2 p5_3_3 p5_3_4 p5_4_1 p5_4_2 p5_4_3 p5_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

// Cálculo de horas
gen horas_trabajo_lv     = p5_3_1 + (p5_3_2 / 60)
gen horas_trabajo_sd     = p5_3_3 + (p5_3_4 / 60)
gen horas_traslado_lv    = p5_4_1 + (p5_4_2 / 60)
gen horas_traslado_sd    = p5_4_3 + (p5_4_4 / 60)

// Sumatorias semanales
gen horas_tot_trabajo   = horas_trabajo_lv + horas_trabajo_sd
gen horas_tot_traslados = horas_traslado_lv + horas_traslado_sd

* ------------------------------------------------------------------------------
* 3. BÚSQUEDA DE TRABAJO
* ------------------------------------------------------------------------------
foreach var in p5_9_1 p5_9_2 p5_9_3 p5_9_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

gen tiempo_lv_busqueda = p5_9_1 + (p5_9_2 / 60)
gen tiempo_sd_busqueda = p5_9_3 + (p5_9_4 / 60)

gen busqueda_trabajo = .
replace busqueda_trabajo = tiempo_lv_busqueda + tiempo_sd_busqueda if p5_8 == 1
replace busqueda_trabajo = 0 if missing(busqueda_trabajo)

* ------------------------------------------------------------------------------
* 4. PRODUCCIÓN DE BIENES PARA EL HOGAR
* ------------------------------------------------------------------------------
foreach var in p6_3a_6_1 p6_3a_6_2 p6_3a_6_3 p6_3a_6_4 ///
               p6_3a_8_1 p6_3a_8_2 p6_3a_8_3 p6_3a_8_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

gen tiempo_lv_ropa     = p6_3a_6_1 + (p6_3a_6_2 / 60)
gen tiempo_sd_ropa     = p6_3a_6_3 + (p6_3a_6_4 / 60)
gen tiempo_lv_muebles  = p6_3a_8_1 + (p6_3a_8_2 / 60)
gen tiempo_sd_muebles  = p6_3a_8_3 + (p6_3a_8_4 / 60)

gen tiempo_ropa    = tiempo_lv_ropa + tiempo_sd_ropa
gen tiempo_muebles = tiempo_lv_muebles + tiempo_sd_muebles
gen produccion_bienes_hogar = tiempo_ropa + tiempo_muebles

* ------------------------------------------------------------------------------
* 5. TIEMPO TOTAL DE TRABAJO REMUNERADO AMPLIADO
* ------------------------------------------------------------------------------
gen horas_trabajo_remunerado = horas_tot_trabajo + horas_tot_traslados + busqueda_trabajo + produccion_bienes_hogar

* ------------------------------------------------------------------------------
* 6. CONFIGURACIÓN DEL DISEÑO MUESTRAL Y ANÁLISIS PONDERADO
* ------------------------------------------------------------------------------
svyset upm [pweight=fac_per], strata(est_dis)

// Trabajo remunerado directo
svy: mean horas_tot_trabajo
svy: mean horas_tot_trabajo if p5_1 == 1
svy: mean horas_tot_trabajo if p5_1 == 1 & sexo == 1
svy: mean horas_tot_trabajo if p5_1 == 1 & sexo == 2

// Traslados y búsqueda
svy: mean horas_tot_traslados if p5_1 == 1
svy: mean busqueda_trabajo
svy: mean busqueda_trabajo if p5_1 == 2

// Total ampliado
svy: mean horas_trabajo_remunerado
svy: mean horas_trabajo_remunerado if p5_1 == 1 | p5_8 == 1 | p6_3_6 == 1 | p6_3_8 == 1


* ==============================================================================
* TRABAJO DOMÉSTICO NO REMUNERADO Y DE CUIDADOS (TDNRC)
* ==============================================================================

// 1. Limpieza de todas las variables de hogar y cuidados
unab dom_vars: p6_*a_*_*
foreach var of local dom_vars {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        capture destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

// 2. Actividades domésticas generales
foreach prefijo in 1_1 1_2 1_3 2_1 2_2 2_3 3_1 3_2 3_3 {
    capture confirm variable p6_`prefijo'_1 p6_`prefijo'_2 p6_`prefijo'_3 p6_`prefijo'_4
    if _rc == 0 {
        gen horas_`prefijo'_lv = p6_`prefijo'_1 + (p6_`prefijo'_2 / 60)
        gen horas_`prefijo'_sd = p6_`prefijo'_3 + (p6_`prefijo'_4 / 60)
        gen horas_`prefijo'_tot = horas_`prefijo'_lv + horas_`prefijo'_sd
    }
}

// 3. Preparación de alimentos
gen horas_comida_lv = 0
gen horas_comida_sd = 0
forvalues i = 1/5 {
    capture confirm variable p6_4a_`i'_1 p6_4a_`i'_2 p6_4a_`i'_3 p6_4a_`i'_4
    if _rc == 0 {
        replace horas_comida_lv = horas_comida_lv + p6_4a_`i'_1 + (p6_4a_`i'_2 / 60) if !missing(p6_4a_`i'_1, p6_4a_`i'_2)
        replace horas_comida_sd = horas_comida_sd + p6_4a_`i'_3 + (p6_4a_`i'_4 / 60) if !missing(p6_4a_`i'_3, p6_4a_`i'_4)
    }
}
gen horas_comida_tot = horas_comida_lv + horas_comida_sd

// 4. Actividades de autoconsumo
foreach i in 1 2 3 4 5 7 {
    local nombre ""
    if `i' == 1 local nombre "animales"
    if `i' == 2 local nombre "lena"
    if `i' == 3 local nombre "silvestre"
    if `i' == 4 local nombre "siembra"
    if `i' == 5 local nombre "agua"
    if `i' == 7 local nombre "conservas"
    
    gen horas_`nombre'_lv = 0
    gen horas_`nombre'_sd = 0
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_`nombre'_lv = horas_`nombre'_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_`nombre'_sd = horas_`nombre'_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
    gen horas_`nombre'_tot = horas_`nombre'_lv + horas_`nombre'_sd
}

gen prep_alimentos = horas_comida_tot + horas_animales_tot + horas_lena_tot + horas_silvestre_tot + horas_siembra_tot + horas_agua_tot + horas_conservas_tot

// 5. Limpieza, ropa, reparaciones, compras, trámites, y relacionadas
foreach categoria in limpieza:5a ropa:6a reparaciones:7a compras:8a tramites_pagos:9a actividades_relacionadas:10a {
    local nombre_cat : word 1 of `subinstr("`categoria'", ":", " ", 1)'
    local codigo_cat : word 2 of `subinstr("`categoria'", ":", " ", 1)'
    
    gen horas_`nombre_cat'_lv = 0
    gen horas_`nombre_cat'_sd = 0
    
    forvalues i = 1/7 {
        capture confirm variable p6_`codigo_cat'_`i'_1 p6_`codigo_cat'_`i'_2 p6_`codigo_cat'_`i'_3 p6_`codigo_cat'_`i'_4
        if _rc == 0 {
            replace horas_`nombre_cat'_lv = horas_`nombre_cat'_lv + p6_`codigo_cat'_`i'_1 + (p6_`codigo_cat'_`i'_2/60) if !missing(p6_`codigo_cat'_`i'_1, p6_`codigo_cat'_`i'_2)
            replace horas_`nombre_cat'_sd = horas_`nombre_cat'_sd + p6_`codigo_cat'_`i'_3 + (p6_`codigo_cat'_`i'_4/60) if !missing(p6_`codigo_cat'_`i'_3, p6_`codigo_cat'_`i'_4)
        }
    }
    gen `nombre_cat'_tot = horas_`nombre_cat'_lv + horas_`nombre_cat'_sd
}

// Variable final TDNR propio hogar
gen trabajo_domestico_phogar = prep_alimentos + limpieza_tot + ropa_tot + reparaciones_tot + compras_tot + tramites_pagos_tot + actividades_relacionadas_tot

* ------------------------------------------------------------------------------
* CUIDADOS ESPECIALES A INTEGRANTES (P6_11A - P6_15A)
* ------------------------------------------------------------------------------
// Automatización del bloque P6_11A (Cuidados Especiales)
gen horas_cuidado_esp_lv = 0
gen horas_cuidado_esp_sd = 0
forvalues i = 1/11 {
    local j = string(`i', "%02.0f")
    capture confirm variable p6_11a_`j'_1 p6_11a_`j'_2 p6_11a_`j'_3 p6_11a_`j'_4
    if _rc == 0 {
        replace horas_cuidado_esp_lv = horas_cuidado_esp_lv + p6_11a_`j'_1 + (p6_11a_`j'_2 / 60) if !missing(p6_11a_`j'_1, p6_11a_`j'_2)
        replace horas_cuidado_esp_sd = horas_cuidado_esp_sd + p6_11a_`j'_3 + (p6_11a_`j'_4 / 60) if !missing(p6_11a_`j'_3, p6_11a_`j'_4)
    }
}
gen cuidados_especiales_tot = horas_cuidado_esp_lv + horas_cuidado_esp_sd

// Cuidado de infantes (P6_12A y P6_13A) y Adultos (P6_14A y P6_15A)
foreach grupo in ninos:12a ninos_sin_esp:13a adultos:14a adultos_mayores:15a {
    local nombre_gr : word 1 of `subinstr("`grupo'", ":", " ", 1)'
    local codigo_gr : word 2 of `subinstr("`grupo'", ":", " ", 1)'
    
    gen horas_`nombre_gr'_lv = 0
    gen horas_`nombre_gr'_sd = 0
    
    forvalues i = 1/6 {
        capture confirm variable p6_`codigo_gr'_`i'_1 p6_`codigo_gr'_`i'_2 p6_`codigo_gr'_`i'_3 p6_`codigo_gr'_`i'_4
        if _rc == 0 {
            replace horas_`nombre_gr'_lv = horas_`nombre_gr'_lv + p6_`codigo_gr'_`i'_1 + (p6_`codigo_gr'_`i'_2/60) if !missing(p6_`codigo_gr'_`i'_1, p6_`codigo_gr'_`i'_2)
            replace horas_`nombre_gr'_sd = horas_`nombre_gr'_sd + p6_`codigo_gr'_`i'_3 + (p6_`codigo_gr'_`i'_4/60) if !missing(p6_`codigo_gr'_`i'_3, p6_`codigo_gr'_`i'_4)
        }
    }
    gen horas_`nombre_gr'_totales = horas_`nombre_gr'_lv + horas_`nombre_gr'_sd
}

gen tiempo_tdcnr_total = cuidados_especiales_tot + horas_ninos_totales + horas_ninos_sin_esp_totales + horas_adultos_totales + horas_adultos_mayores_totales

* ------------------------------------------------------------------------------
* APOYO A OTROS HOGARES Y VOLUNTARIADO (P6_16A y P6_17A)
* ------------------------------------------------------------------------------
// Quehaceres y trámites ajenos
gen horas_quehacer_ajenos_tot = p6_16a_1_1 + (p6_16a_1_2/60) + p6_16a_1_3 + (p6_16a_1_4/60)
gen horas_tramites_ajenos_tot = p6_16a_2_1 + (p6_16a_2_2/60) + p6_16a_2_3 + (p6_16a_2_4/60)
gen trabajo_domestico_otro_hogar = horas_quehacer_ajenos_tot + horas_tramites_ajenos_tot

// Cuidados propios de edad en otros hogares
gen cuidados_otro_hogar = (p6_16a_4_1 + (p6_16a_4_2/60) + p6_16a_4_3 + (p6_16a_4_4/60)) + ///
                          (p6_16a_5_1 + (p6_16a_5_2/60) + p6_16a_5_3 + (p6_16a_5_4/60)) + ///
                          (p6_16a_6_1 + (p6_16a_6_2/60) + p6_16a_6_3 + (p6_16a_6_4/60))
gen horas_aten_cui_disca = p6_16a_3_1 + (p6_16a_3_2/60) + p6_16a_3_3 + (p6_16a_3_4/60)

// Voluntariado
gen horas_voluntariado = p6_17a_1_1 + (p6_17a_1_2/60) + p6_17a_1_3 + (p6_17a_1_4/60)
gen horas_trabajo_comun = p6_17a_2_1 + (p6_17a_2_2/60) + p6_17a_2_3 + (p6_17a_2_4/60)
gen trabajo_no_rem_voluntario = horas_voluntariado + horas_trabajo_comun

gen trabajo_nrcah_total = trabajo_domestico_otro_hogar + cuidados_otro_hogar + horas_aten_cui_disca + trabajo_no_rem_voluntario

* ------------------------------------------------------------------------------
* AUTOCUIDADO, ESTUDIO Y CONVIVENCIA SOCIAL
* ------------------------------------------------------------------------------
gen horas_dormir_totales = p6_1_1_1 + (p6_1_1_2/60) + p6_1_1_3 + (p6_1_1_4/60)
gen horas_comer_totales = p6_1_2_1 + (p6_1_2_2/60) + p6_1_2_3 + (p6_1_2_4/60)
gen horas_aseo_totales = p6_1_3_1 + (p6_1_3_2/60) + p6_1_3_3 + (p6_1_3_4/60)
gen tiempo_total_autocuidado = horas_aseo_totales + horas_comer_totales + horas_dormir_totales

gen horas_asistir_clases_totales = p6_2a_1_1 + (p6_2a_1_2/60) + p6_2a_1_3 + (p6_2a_1_4/60)
gen horas_tareas_totales = p6_2a_2_1 + (p6_2a_2_2/60) + p6_2a_2_3 + (p6_2a_2_4/60)
gen horas_traslado_escuela_totales = p6_2a_3_1 + (p6_2a_3_2/60) + p6_2a_3_3 + (p6_2a_3_4/60)
gen tiempo_estudio_total = horas_traslado_escuela_totales + horas_tareas_totales + horas_asistir_clases_totales

gen horas_uso_medios = (p6_22a_5_1+(p6_22a_5_2/60)+p6_22a_5_3+(p6_22a_5_4/60)) + ///
                       (p6_22a_4_1+(p6_22a_4_2/60)+p6_22a_4_3+(p6_22a_4_4/60)) + ///
                       (p6_22a_3_1+(p6_22a_3_2/60)+p6_22a_3_3+(p6_22a_3_4/60)) + ///
                       (p6_22a_2_1+(p6_22a_2_2/60)+p6_22a_2_3+(p6_22a_2_4/60)) + ///
                       (p6_22a_1_1+(p6_22a_1_2/60)+p6_22a_1_3+(p6_22a_1_4/60))

* ------------------------------------------------------------------------------
* CONFIGURACIÓN FINAL 2019 Y CÁLCULO DE UMBRALES
* ------------------------------------------------------------------------------
gen horas_trabajo_total = horas_trabajo_remunerado + trabajo_domestico_phogar + tiempo_tdcnr_total + trabajo_nrcah_total

sum horas_trabajo_total, detail
local mediana = r(p50)
gen pobreza_R = horas_trabajo_total > (`mediana' * 1.5)
gen pobreza_E = horas_trabajo_total > (`mediana' * 2)

gen tiempo_disponible = 168 - horas_trabajo_total
gen pobreza_V = tiempo_disponible < 81

gen year = 1
save "$outdir/TMODULO_2019_pooled_temp.dta", replace

* ==============================================================================
* PARTE II: PROCESAMIENTO Y LIMPIEZA - ENUT 2024
* ==============================================================================

cd "$data2024"
use "TMODULO_2024.dta", clear

// 1. Filtramos CDMX y configuramos diseño
keep if cve_ent == 09
rename upm_dis upm
svyset upm [pweight=fac_per], strata(est_dis)

* ------------------------------------------------------------------------------
* TRABAJO REMUNERADO (Presencial y Virtual)
* ------------------------------------------------------------------------------
foreach var in p5_8_1_1 p5_8_1_2 p5_8_1_3 p5_8_1_4 ///
               p5_8_2_1 p5_8_2_2 p5_8_2_3 p5_8_2_4 ///
               p5_9_1 p5_9_2 p5_9_3 p5_9_4 ///
               p5_12_1 p5_12_2 p5_12_3 p5_12_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

gen horas_trabajo_presencial_tot = p5_8_1_1 + (p5_8_1_2/60) + p5_8_1_3 + (p5_8_1_4/60)
gen horas_trabajo_virtual_tot    = p5_8_2_1 + (p5_8_2_2/60) + p5_8_2_3 + (p5_8_2_4/60)
gen horas_tot_trabajo = horas_trabajo_presencial_tot + horas_trabajo_virtual_tot

gen horas_tot_traslados = p5_9_1 + (p5_9_2/60) + p5_9_3 + (p5_9_4/60)
gen horas_tot_secundaria = p5_12_1 + (p5_12_2/60) + p5_12_3 + (p5_12_4/60)
gen horas_bus_tra = horas_tot_secundaria if p5_11 == 1

* ------------------------------------------------------------------------------
* TRABAJO NO REMUNERADO, CUIDADOS Y HOGAR (2024)
* (La lógica de las siguientes rutinas automatiza las sumatorias para 2024
* aplicando la misma limpieza iterativa que en 2019)
* ------------------------------------------------------------------------------

// Limpieza global rápida para todas las variables del bloque p6
unab p6_vars: p6_*a_*_*
foreach var of local p6_vars {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        capture destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

// Autoconsumo
gen horas_trabajo_autocon = 0
forvalues i = 1/9 {
    capture replace horas_trabajo_autocon = horas_trabajo_autocon + p6_3a_`i'_1 + (p6_3a_`i'_2/60) + p6_3a_`i'_3 + (p6_3a_`i'_4/60)
}
gen actividades_mercado = horas_tot_trabajo + horas_tot_traslados + horas_tot_secundaria + horas_trabajo_autocon

// Preparación de Alimentos, Limpieza, Mantenimiento, Compras, Pagos, Gestión (Resumen modular)
gen horas_totales_prep_ali = 0
forvalues i = 1/5 {
    capture replace horas_totales_prep_ali = horas_totales_prep_ali + p6_4a_`i'_1 + (p6_4a_`i'_2/60) + p6_4a_`i'_3 + (p6_4a_`i'_4/60)
}

gen horas_tot_lim_viv = 0
forvalues i = 1/5 {
    capture replace horas_tot_lim_viv = horas_tot_lim_viv + p6_5a_`i'_1 + (p6_5a_`i'_2/60) + p6_5a_`i'_3 + (p6_5a_`i'_4/60)
}

gen horas_tot_lim_ropcal = 0
forvalues i = 1/5 {
    capture replace horas_tot_lim_ropcal = horas_tot_lim_ropcal + p6_6a_`i'_1 + (p6_6a_`i'_2/60) + p6_6a_`i'_3 + (p6_6a_`i'_4/60)
}

gen horas_tot_mant_inst_rep = 0
forvalues i = 1/4 {
    capture replace horas_tot_mant_inst_rep = horas_tot_mant_inst_rep + p6_7a_`i'_1 + (p6_7a_`i'_2/60) + p6_7a_`i'_3 + (p6_7a_`i'_4/60)
}

gen horas_tot_compras = 0
forvalues i = 1/3 {
    capture replace horas_tot_compras = horas_tot_compras + p6_8a_`i'_1 + (p6_8a_`i'_2/60) + p6_8a_`i'_3 + (p6_8a_`i'_4/60)
}

gen horas_tot_pagos_tram = 0
forvalues i = 1/3 {
    capture replace horas_tot_pagos_tram = horas_tot_pagos_tram + p6_9a_`i'_1 + (p6_9a_`i'_2/60) + p6_9a_`i'_3 + (p6_9a_`i'_4/60)
}

gen horas_tot_gest_adm = 0
forvalues i = 1/7 {
    capture replace horas_tot_gest_adm = horas_tot_gest_adm + p6_10a_`i'_1 + (p6_10a_`i'_2/60) + p6_10a_`i'_3 + (p6_10a_`i'_4/60)
}

gen horas_tot_tdnr_prop_hog = horas_tot_gest_adm + horas_tot_pagos_tram + horas_tot_compras + horas_tot_mant_inst_rep +  horas_tot_lim_ropcal + horas_tot_lim_viv + horas_totales_prep_ali

// Cuidados y Apoyo a otros hogares
gen horas_totales_cuidados = 0
foreach base in 11a 12a 13a 14a 15a {
    forvalues i = 1/14 {
        local j = string(`i', "%02.0f")
        capture replace horas_totales_cuidados = horas_totales_cuidados + p6_`base'_`j'_1 + (p6_`base'_`j'_2/60) + p6_`base'_`j'_3 + (p6_`base'_`j'_4/60)
        capture replace horas_totales_cuidados = horas_totales_cuidados + p6_`base'_`i'_1 + (p6_`base'_`i'_2/60) + p6_`base'_`i'_3 + (p6_`base'_`i'_4/60)
    }
}

gen trabajo_otroh_comunvolun = 0
foreach base in 16a 17a {
    forvalues i = 1/6 {
        capture replace trabajo_otroh_comunvolun = trabajo_otroh_comunvolun + p6_`base'_`i'_1 + (p6_`base'_`i'_2/60) + p6_`base'_`i'_3 + (p6_`base'_`i'_4/60)
    }
}

* ------------------------------------------------------------------------------
* CÁLCULO DE UMBRALES 2024
* ------------------------------------------------------------------------------
gen horas_trabajo_total = actividades_mercado + horas_tot_tdnr_prop_hog + horas_totales_cuidados + trabajo_otroh_comunvolun

sum horas_trabajo_total, detail
local mediana = r(p50)
gen pobreza_R = horas_trabajo_total > (`mediana' * 1.5)
gen pobreza_E = horas_trabajo_total > (`mediana' * 2)

gen tiempo_disponible = 168 - horas_trabajo_total
gen pobreza_V = tiempo_disponible < 81

gen year = 2
save "$outdir/TMODULO_2024_pooled_temp.dta", replace


* ==============================================================================
* PARTE III: AGREGACIÓN (APPEND) Y MODELOS COMBINADOS (POOLED)
* ==============================================================================

cd "$outdir"
use "TMODULO_2024_pooled_temp.dta", clear
append using "TMODULO_2019_pooled_temp.dta", force

save "TMODULO_POOLED_FINAL.dta", replace
export delimited using "TMODULO_POOLED_FINAL.csv", replace

// Diseño muestral consolidado
svyset upm [pweight=fac_per], strata(est_dis)

* ------------------------------------------------------------------------------
* INSTALACIÓN DE PAQUETERÍAS
* ------------------------------------------------------------------------------
foreach pkg in outreg2 estout parmest somersd lroc tabout {
    capture noisily which `pkg'
    if _rc {
        di as text "Instalando `pkg' desde SSC..."
        ssc install `pkg', replace
    }
}

* ------------------------------------------------------------------------------
* ARMONIZACIÓN DE CONYUGALIDAD
* ------------------------------------------------------------------------------
capture drop conyugalidad
gen byte conyugalidad = .
replace conyugalidad = p4_4 if !missing(p4_4) & year == 1
replace conyugalidad = p4_5 if !missing(p4_5) & year == 2
label var conyugalidad "Condición conyugal armonizada 2019–2024"
fvset base 1 conyugalidad

* ------------------------------------------------------------------------------
* MODELOS LOGIT POOLED Y EXPORTACIÓN DE TABLAS
* ------------------------------------------------------------------------------
// Modelo Pobreza Extrema
svy: logit pobreza_E i.year##i.sexo##i.tloc i.conyugalidad i.edad_v i.niv, or
estimates store M_POOL_E

outreg2 [M_POOL_E] using "Tabla3_OR_IC95.doc", ///
    replace eform dec(3) ctitle("Pooled Logit Pobreza Extrema") ///
    alpha(0.10, 0.05, 0.01) symbol(†, *, **) label ///
    addstat("N (obs)", e(N)) title("Tabla 3. Modelo Combinado (Pooled) para Pobreza Extrema")

* ------------------------------------------------------------------------------
* GRÁFICOS (MÁRGENES PREDICTIVOS)
* ------------------------------------------------------------------------------
margins i.year#i.sexo, over(tloc) post

marginsplot, ///
    xdimension(tloc) ///
    plotdimension(sexo) ///
    bydimension(year) ///
    byopts(compact) ///
    recast(scatter) ///
    plot1opts(msymbol(Oh) connect(l) lwidth(medthick)) ///
    plot2opts(msymbol(Th) connect(l) lwidth(medthick)) ///
    ciopts(recast(rcap) lwidth(thin)) ///
    title("") ///
    ytitle("Probabilidad (Pobreza E)", size(medlarge) margin(medium)) ///
    ylabel(0(.05).30, angle(0) format(%3.2f)) ///
    xtitle("Tamaño de localidad", size(medlarge)) ///
    legend(order(1 "Hombres" 2 "Mujeres") col(1)) ///
    name(fig1A_sexoXTLOC, replace)

graph export "fig1A_sexoXTLOC_2019_2024.png", width(3000) replace

* ------------------------------------------------------------------------------
* EVALUACIÓN DEL DESEMPEÑO DEL MODELO (NO-SVY)
* ------------------------------------------------------------------------------
keep if !missing(pobreza_E, year, sexo, tloc, conyugalidad)
logit pobreza_E i.year##i.sexo##i.tloc i.conyugalidad, or

display "Pseudo-R2 (McFadden) = " %6.3f e(r2_p)
estat classification
lroc, nograph
display "Área bajo la curva ROC (AUC) = " %6.3f e(roc_area)

* ================= FIN DEL SCRIPT =================