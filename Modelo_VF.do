/****************************************************************************
  MODELO LOGIT - ENUT 2019
  Elaborado por: Luis Felipe Sánchez Ascencio, David Orlando Ramírez Naranjo y Nayeli Pérez
****************************************************************************/

// 0. DEFINIMOS DIRECTORIO Y ABRIMOS BASE DE DATOS
cd "C:\Users\usuario\Documents\Maestria\Economía_Política\Trabajo_Final\ENUT_2019_ARTICULO\enut_2019_bd_csv\enut_2019"
use "TMODULO_2019.dta", clear

// 1. FILTRAMOS SOLO CDMX
keep if ent == 09

/****************************************************************************
  2. TRABAJO REMUNERADO BÁSICO (lunes a domingo)
****************************************************************************/

// Limpieza y conversión de horas y minutos
foreach var in p5_3_1 p5_3_2 p5_3_3 p5_3_4 p5_4_1 p5_4_2 p5_4_3 p5_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == ""
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


/****************************************************************************
  3. COMPONENTE: BÚSQUEDA DE TRABAJO
****************************************************************************/

foreach var in p5_9_1 p5_9_2 p5_9_3 p5_9_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == ""
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

gen tiempo_lv_busqueda = p5_9_1 + (p5_9_2 / 60)
gen tiempo_sd_busqueda = p5_9_3 + (p5_9_4 / 60)

gen busqueda_trabajo = .
replace busqueda_trabajo = tiempo_lv_busqueda + tiempo_sd_busqueda if p5_8 == 1
replace busqueda_trabajo = 0 if missing(busqueda_trabajo)

/****************************************************************************
  4. COMPONENTE: PRODUCCIÓN DE BIENES PARA EL HOGAR
****************************************************************************/

foreach var in p6_3a_6_1 p6_3a_6_2 p6_3a_6_3 p6_3a_6_4 ///
              p6_3a_8_1 p6_3a_8_2 p6_3a_8_3 p6_3a_8_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == ""
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

/****************************************************************************
  5. SUMATORIA FINAL: TIEMPO TOTAL DE TRABAJO REMUNERADO AMPLIADO
****************************************************************************/

gen horas_trabajo_remunerado = horas_tot_trabajo + horas_tot_traslados + busqueda_trabajo + produccion_bienes_hogar

/****************************************************************************
  6. CONFIGURAMOS DISEÑO MUESTRAL
****************************************************************************/

svyset upm [pweight=fac_per], strata(est_dis)

/****************************************************************************
  7. ANÁLISIS DESCRIPTIVO PONDERADO
****************************************************************************/

// Trabajo remunerado directo
svy: mean horas_tot_trabajo
svy: mean horas_tot_trabajo if p5_1 == 1
svy: mean horas_tot_trabajo if p5_1 == 1 & sexo == 1
svy: mean horas_tot_trabajo if p5_1 == 1 & sexo == 2
svy: mean horas_tot_trabajo if p5_1 == 1 |  p5_8 == 1
// Traslados
svy: mean horas_tot_traslados if p5_1 == 1

// Búsqueda de trabajo
svy: mean busqueda_trabajo
svy: mean busqueda_trabajo if p5_1 == 2

// Producción de bienes para el hogar
svy: mean produccion_bienes_hogar
svy: mean produccion_bienes_hogar if p5_1 == 1
svy: mean produccion_bienes_hogar if p5_1 == 2

// Total de horas trabajadas (remunerado ampliado)
svy: mean horas_trabajo_remunerado
svy: mean horas_trabajo_remunerado if p5_1 == 1 | p5_8 == 1 | p6_3_6 == 1 | p6_3_8 == 1
svy: mean horas_trabajo_remunerado if p5_1 == 1 & edad >= 12
svy: mean horas_trabajo_remunerado if (p5_1 == 1 | p5_8 == 1 | p6_3_6 == 1 | p6_3_8 == 1) & edad >= 12






// ================================================================
// Cálculo del tiempo destinado al trabajo doméstico no remunerado
// y de cuidados, incluyendo actividades de autoconsumo
// ================================================================


// ------------------------------------------------------------
// 1. Limpieza de todas las variables p6_*a_*_*
// Estas son las que registran actividades del hogar y cuidados
// ------------------------------------------------------------
unab dom_vars: p6_*a_*_*

foreach var of local dom_vars {
    capture confirm string variable `var'
    if _rc == 0 {
        // Solo si la variable es string, la limpiamos y convertimos
        replace `var' = "0" if `var' == "b" | `var' == ""
        capture destring `var', replace
    }

    // Ahora, si queda como numérica, aseguramos que missing sea 0
    replace `var' = 0 if missing(`var')
}

// ------------------------------------------------------------
// 2. Cálculo de tiempo en actividades domésticas generales
// Agrupadas en prefijos como 1_1, 1_2... 3_3 según tipo de tarea
// ------------------------------------------------------------

foreach prefijo in 1_1 1_2 1_3 2_1 2_2 2_3 3_1 3_2 3_3 {
    capture confirm variable p6_`prefijo'_1 p6_`prefijo'_2 p6_`prefijo'_3 p6_`prefijo'_4
    if _rc == 0 {
        gen horas_`prefijo'_lv = p6_`prefijo'_1 + (p6_`prefijo'_2 / 60)
        gen horas_`prefijo'_sd = p6_`prefijo'_3 + (p6_`prefijo'_4 / 60)
        gen horas_`prefijo'_tot = horas_`prefijo'_lv + horas_`prefijo'_sd
    }
}


// ------------------------------------------------------------
// 3. Preparación de alimentos (conjunto p6_4a)
// Se suman 5 actividades distintas
// ------------------------------------------------------------
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


// ------------------------------------------------------------
// 4. Actividades de autoconsumo
// (como crianza de animales, recolección, siembra, etc.)
// ------------------------------------------------------------

// 4.1 Crianza de animales (actividad 1)
gen horas_animales_lv = 0
gen horas_animales_sd = 0
forvalues i = 1/1 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_animales_lv = horas_animales_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_animales_sd = horas_animales_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_animales_tot = horas_animales_lv + horas_animales_sd

// 4.2 Recolección de leña (actividad 2)
gen horas_lena_lv = 0
gen horas_lena_sd = 0
forvalues i = 2/2 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_lena_lv = horas_lena_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_lena_sd = horas_lena_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_lena_tot = horas_lena_lv + horas_lena_sd

// 4.3 Comida silvestre (actividad 3)
gen horas_silvestre_lv = 0
gen horas_silvestre_sd = 0
forvalues i = 3/3 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_silvestre_lv = horas_silvestre_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_silvestre_sd = horas_silvestre_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_silvestre_tot = horas_silvestre_lv + horas_silvestre_sd

// 4.4 Siembra (actividad 4)
gen horas_siembra_lv = 0
gen horas_siembra_sd = 0
forvalues i = 4/4 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_siembra_lv = horas_siembra_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_siembra_sd = horas_siembra_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_siembra_tot = horas_siembra_lv + horas_siembra_sd

// 4.5 Acarreo de agua (actividad 5)
gen horas_agua_lv = 0
gen horas_agua_sd = 0
forvalues i = 5/5 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_agua_lv = horas_agua_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_agua_sd = horas_agua_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_agua_tot = horas_agua_lv + horas_agua_sd

// 4.6 Conservas (actividad 7)
gen horas_conservas_lv = 0
gen horas_conservas_sd = 0
forvalues i = 7/7 {
    capture confirm variable p6_3a_`i'_1 p6_3a_`i'_2 p6_3a_`i'_3 p6_3a_`i'_4
    if _rc == 0 {
        replace horas_conservas_lv = horas_conservas_lv + p6_3a_`i'_1 + (p6_3a_`i'_2 / 60) if !missing(p6_3a_`i'_1, p6_3a_`i'_2)
        replace horas_conservas_sd = horas_conservas_sd + p6_3a_`i'_3 + (p6_3a_`i'_4 / 60) if !missing(p6_3a_`i'_3, p6_3a_`i'_4)
    }
}
gen horas_conservas_tot = horas_conservas_lv + horas_conservas_sd

// 5,0 Realizamos los totales y obtenemos la estadística descriptiva //
gen prep_alimentos =  horas_comida_tot + horas_animales_tot + horas_lena_tot + horas_silvestre_tot + horas_siembra_tot + horas_agua_tot + horas_conservas_tot

svy: mean prep_alimentos  // 7.81 horas en promedio dedicadas a la preparación de alimentos. 1.3 horas menos que lo reportado por INEGI. 
svy: mean prep_alimentos if edad_v >= 12 // Ajustando a mayores de 12 años, el promedio es de 7.81, una hora menos que lo reportado por INEGI. 
svy: mean prep_alimentos if sexo == 1 // Cuando es hombre, el promedio es de 4.2, 1.7 horas menos que lo reportado por INEGI. 
svy: mean prep_alimentos if sexo == 2  // Cuando es mujer, el promedio es de 11.10 horas, 0.04 horas menos que lo reportado por INEGI. 

svy: mean prep_alimentos if  p6_4_1 == 2 | p6_3_7 == 2 | p6_3_5 == 2 | p6_3_4 == 2 | p6_3_4 == 2

// ------------------------------------------------------------
// 5. Cálculo del tiempo dedicado a limpieza
// ------------------------------------------------------------
gen horas_limpieza_lv = 0
gen horas_limpieza_sd = 0

forvalues i = 1/5 {
    capture confirm variable p6_5a_`i'_1 p6_5a_`i'_2 p6_5a_`i'_3 p6_5a_`i'_4
    if _rc == 0 {
        replace horas_limpieza_lv = horas_limpieza_lv + p6_5a_`i'_1 + (p6_5a_`i'_2/60) if !missing(p6_5a_`i'_1, p6_5a_`i'_2)
        replace horas_limpieza_sd = horas_limpieza_sd + p6_5a_`i'_3 + (p6_5a_`i'_4/60) if !missing(p6_5a_`i'_3, p6_5a_`i'_4)
    }
}

gen limpieza_tot = horas_limpieza_lv + horas_limpieza_sd

// Comparación con INEGI
svy: mean limpieza_tot
svy: mean limpieza_tot if sexo == 1
svy: mean limpieza_tot if sexo == 2


// ------------------------------------------------------------
// 6. Cálculo del tiempo dedicado al lavado de ropa
// ------------------------------------------------------------
gen horas_ropa_lv = 0
gen horas_ropa_sd = 0

forvalues i = 1/5 {
    capture confirm variable p6_6a_`i'_1 p6_6a_`i'_2 p6_6a_`i'_3 p6_6a_`i'_4
    if _rc == 0 {
        replace horas_ropa_lv = horas_ropa_lv + p6_6a_`i'_1 + (p6_6a_`i'_2/60) if !missing(p6_6a_`i'_1, p6_6a_`i'_2)
        replace horas_ropa_sd = horas_ropa_sd + p6_6a_`i'_3 + (p6_6a_`i'_4/60) if !missing(p6_6a_`i'_3, p6_6a_`i'_4)
    }
}

gen ropa_tot = horas_ropa_lv + horas_ropa_sd

// Comparación con INEGI
svy: mean ropa_tot
svy: mean ropa_tot if sexo == 1
svy: mean ropa_tot if sexo == 2

// ======================================================
// 7. Cálculo de tiempo dedicado a reparaciones, compras, trámites y actividades varias.
// ======================================================


// -----------------------------------------------------
// 1. Reparaciones menores en el hogar (p6_7a)
// -----------------------------------------------------
gen horas_reparaciones_lv = 0
gen horas_reparaciones_sd = 0

forvalues i = 1/4 {
    capture confirm variable p6_7a_`i'_1 p6_7a_`i'_2 p6_7a_`i'_3 p6_7a_`i'_4
    if _rc == 0 {
        replace horas_reparaciones_lv = horas_reparaciones_lv + p6_7a_`i'_1 + (p6_7a_`i'_2 / 60) if !missing(p6_7a_`i'_1, p6_7a_`i'_2)
        replace horas_reparaciones_sd = horas_reparaciones_sd + p6_7a_`i'_3 + (p6_7a_`i'_4 / 60) if !missing(p6_7a_`i'_3, p6_7a_`i'_4)
    }
}
gen reparaciones_tot = horas_reparaciones_lv + horas_reparaciones_sd

svy: mean reparaciones_tot
svy: mean reparaciones_tot if sexo == 1
svy: mean reparaciones_tot if sexo == 2


// -----------------------------------------------------
// 2. Compras (p6_8a)
// -----------------------------------------------------
gen horas_compras_lv = 0 
gen horas_compras_sd = 0 

forvalues i = 1/3 {
    capture confirm variable p6_8a_`i'_1 p6_8a_`i'_2 p6_8a_`i'_3 p6_8a_`i'_4
    if _rc == 0 {
        replace horas_compras_lv = horas_compras_lv + p6_8a_`i'_1 + (p6_8a_`i'_2 / 60) if !missing(p6_8a_`i'_1, p6_8a_`i'_2)
        replace horas_compras_sd = horas_compras_sd + p6_8a_`i'_3 + (p6_8a_`i'_4 / 60) if !missing(p6_8a_`i'_3, p6_8a_`i'_4)
    }
}
gen compras_tot = horas_compras_lv + horas_compras_sd

svy: mean compras_tot
svy: mean compras_tot if sexo == 1
svy: mean compras_tot if sexo == 2


// -----------------------------------------------------
// 3. Trámites y pagos (p6_9a)
// -----------------------------------------------------
gen horas_tramites_pagos_lv = 0
gen horas_tramites_pagos_sd = 0 

forvalues i = 1/3 {
    capture confirm variable p6_9a_`i'_1 p6_9a_`i'_2 p6_9a_`i'_3 p6_9a_`i'_4
    if _rc == 0 {
        replace horas_tramites_pagos_lv = horas_tramites_pagos_lv + p6_9a_`i'_1 + (p6_9a_`i'_2 / 60) if !missing(p6_9a_`i'_1, p6_9a_`i'_2)
        replace horas_tramites_pagos_sd = horas_tramites_pagos_sd + p6_9a_`i'_3 + (p6_9a_`i'_4 / 60) if !missing(p6_9a_`i'_3, p6_9a_`i'_4)
    }
}
gen tramites_tot = horas_tramites_pagos_lv + horas_tramites_pagos_sd

svy: mean tramites_tot
svy: mean tramites_tot if sexo == 1
svy: mean tramites_tot if sexo == 2


// -----------------------------------------------------
// 4. Actividades relacionadas diversas (p6_10a)
// -----------------------------------------------------
gen actividades_relacionadas_lv = 0
gen actividades_relacionadas_sd = 0 

forvalues i = 1/7 {
    capture confirm variable p6_10a_`i'_1 p6_10a_`i'_2 p6_10a_`i'_3 p6_10a_`i'_4
    if _rc == 0 {
        replace actividades_relacionadas_lv = actividades_relacionadas_lv + p6_10a_`i'_1 + (p6_10a_`i'_2 / 60) if !missing(p6_10a_`i'_1, p6_10a_`i'_2)
        replace actividades_relacionadas_sd = actividades_relacionadas_sd + p6_10a_`i'_3 + (p6_10a_`i'_4 / 60) if !missing(p6_10a_`i'_3, p6_10a_`i'_4)
    }
}
gen actividades_relacionadas_tot = actividades_relacionadas_lv + actividades_relacionadas_sd

svy: mean actividades_relacionadas_tot
svy: mean actividades_relacionadas_tot if sexo == 1
svy: mean actividades_relacionadas_tot if sexo == 2
* =============================================================
* VARIABLE FINAL: Tiempo total de trabajo doméstico no remunerado
* =============================================================
gen trabajo_domestico_phogar =  prep_alimentos + limpieza_tot +  ropa_tot +  reparaciones_tot + compras_tot + tramites_tot + actividades_relacionadas_tot

* =============================================================
* ESTADÍSTICAS DESCRIPTIVAS
* =============================================================

svy: mean trabajo_domestico_phogar
svy: mean trabajo_domestico_phogar if sexo == 1
svy: mean trabajo_domestico_phogar if sexo == 2

* =============================================================
* CÁLCULO DEL TIEMPO DEDICADO A CUIDADOS ESPECIALES
* Basado en el bloque P6_11A de la ENUT 2019
* =============================================================

* -----------------------------
* 1. Ayuda para comer (p6_11a_01)
* -----------------------------
gen horas_ayudar_comer_lv = 0
gen horas_ayudar_comer_sd = 0

capture confirm variable p6_11a_01_1 p6_11a_01_2 p6_11a_01_3 p6_11a_01_4
if _rc == 0 {
    replace horas_ayudar_comer_lv = p6_11a_01_1 + (p6_11a_01_2/60) if !missing(p6_11a_01_1, p6_11a_01_2)
    replace horas_ayudar_comer_sd = p6_11a_01_3 + (p6_11a_01_4/60) if !missing(p6_11a_01_3, p6_11a_01_4)
}
gen ayudar_comer_tot = horas_ayudar_comer_lv + horas_ayudar_comer_sd


* -----------------------------
* 2. Aseo personal a personas dependientes (p6_11a_02)
* -----------------------------
gen horas_aseo_lv = 0 
gen horas_aseo_sd = 0 

capture confirm variable p6_11a_02_1 p6_11a_02_2 p6_11a_02_3 p6_11a_02_4
if _rc == 0 {
    foreach var in p6_11a_02_1 p6_11a_02_2 p6_11a_02_3 p6_11a_02_4 {
        capture confirm string variable `var'
        if !_rc {
            replace `var' = "0" if inlist(`var', "b", "", " ", ".")
            destring `var', replace
        }
        replace `var' = 0 if missing(`var')  
    }
    replace horas_aseo_lv = p6_11a_02_1 + (p6_11a_02_2/60) if !missing(p6_11a_02_1, p6_11a_02_2)
    replace horas_aseo_sd = p6_11a_02_3 + (p6_11a_02_4/60) if !missing(p6_11a_02_3, p6_11a_02_4)
}
gen aseo_tot = horas_aseo_lv + horas_aseo_sd


* -----------------------------
* 3. Cargar, acostar o movilizar (p6_11a_03)
* -----------------------------
gen horas_cargar_lv = 0
gen horas_cargar_sd = 0

capture confirm variable p6_11a_03_1 p6_11a_03_2 p6_11a_03_3 p6_11a_03_4
if _rc == 0 {
    replace horas_cargar_lv = p6_11a_03_1 + (p6_11a_03_2/60) if !missing(p6_11a_03_1, p6_11a_03_2)
    replace horas_cargar_sd = p6_11a_03_3 + (p6_11a_03_4/60) if !missing(p6_11a_03_3, p6_11a_03_4)
}
gen cargar_tot = horas_cargar_lv + horas_cargar_sd


* -----------------------------
* 4. Preparación de remedios o comida especial (p6_11a_04)
* -----------------------------
gen horas_remedios_lv = 0
gen horas_remedios_sd = 0

capture confirm variable p6_11a_04_1 p6_11a_04_2 p6_11a_04_3 p6_11a_04_4
if _rc == 0 {
    replace horas_remedios_lv = p6_11a_04_1 + (p6_11a_04_2/60) if !missing(p6_11a_04_1, p6_11a_04_2)
    replace horas_remedios_sd = p6_11a_04_3 + (p6_11a_04_4/60) if !missing(p6_11a_04_3, p6_11a_04_4)
}
gen remedios_tot = horas_remedios_lv + horas_remedios_sd


* -----------------------------
* 5. Administración de medicamentos (p6_11a_05)
* -----------------------------
gen horas_medicamentos_lv = 0
gen horas_medicamentos_sd = 0

capture confirm variable p6_11a_05_1 p6_11a_05_2 p6_11a_05_3 p6_11a_05_4
if _rc == 0 {
    replace horas_medicamentos_lv = p6_11a_05_1 + (p6_11a_05_2/60) if !missing(p6_11a_05_1, p6_11a_05_2)
    replace horas_medicamentos_sd = p6_11a_05_3 + (p6_11a_05_4/60) if !missing(p6_11a_05_3, p6_11a_05_4)
}
gen medicamentos_tot = horas_medicamentos_lv + horas_medicamentos_sd


* -----------------------------
* 6. Transporte y acompañamiento médico (p6_11a_06)
* -----------------------------
gen horas_transporte_salud_lv = 0
gen horas_transporte_salud_sd = 0

capture confirm variable p6_11a_06_1 p6_11a_06_2 p6_11a_06_3 p6_11a_06_4
if _rc == 0 {
    replace horas_transporte_salud_lv = p6_11a_06_1 + (p6_11a_06_2/60) if !missing(p6_11a_06_1, p6_11a_06_2)
    replace horas_transporte_salud_sd = p6_11a_06_3 + (p6_11a_06_4/60) if !missing(p6_11a_06_3, p6_11a_06_4)
}
gen transporte_salud_tot = horas_transporte_salud_lv + horas_transporte_salud_sd


* -----------------------------
* 7. Terapia o ejercicios (p6_11a_07)
* -----------------------------
gen horas_terapia_lv = 0 
gen horas_terapia_sd = 0

capture confirm variable p6_11a_07_1 p6_11a_07_2 p6_11a_07_3 p6_11a_07_4
if _rc == 0 {
    replace horas_terapia_lv = p6_11a_07_1 + (p6_11a_07_2/60) if !missing(p6_11a_07_1, p6_11a_07_2)
    replace horas_terapia_sd = p6_11a_07_3 + (p6_11a_07_4/60) if !missing(p6_11a_07_3, p6_11a_07_4)
}
gen terapia_tot = horas_terapia_lv + horas_terapia_sd


* -----------------------------
* 8. Transporte a clases o trabajo (p6_11a_08)
* -----------------------------
gen horas_transporte_clases_lv = 0
gen horas_transporte_clases_sd = 0

capture confirm variable p6_11a_08_1 p6_11a_08_2 p6_11a_08_3 p6_11a_08_4
if _rc == 0 {
    replace horas_transporte_clases_lv = p6_11a_08_1 + (p6_11a_08_2/60) if !missing(p6_11a_08_1, p6_11a_08_2)
    replace horas_transporte_clases_sd = p6_11a_08_3 + (p6_11a_08_4/60) if !missing(p6_11a_08_3, p6_11a_08_4)
}
gen transporte_clases_tot = horas_transporte_clases_lv + horas_transporte_clases_sd


* -----------------------------
* 9. Apoyo en tareas escolares (p6_11a_09)
* -----------------------------
gen horas_apoyo_tareas_lv = 0
gen horas_apoyo_tareas_sd = 0

capture confirm variable p6_11a_09_1 p6_11a_09_2 p6_11a_09_3 p6_11a_09_4
if _rc == 0 {
    replace horas_apoyo_tareas_lv = p6_11a_09_1 + (p6_11a_09_2/60) if !missing(p6_11a_09_1, p6_11a_09_2)
    replace horas_apoyo_tareas_sd = p6_11a_09_3 + (p6_11a_09_4/60) if !missing(p6_11a_09_3, p6_11a_09_4)
}
gen apoyo_tareas_tot = horas_apoyo_tareas_lv + horas_apoyo_tareas_sd


* -----------------------------
* 10. Asistencia a eventos escolares (p6_11a_10)
* -----------------------------
gen horas_eventos_esc_lv = 0
gen horas_eventos_esc_sd = 0

capture confirm variable p6_11a_10_1 p6_11a_10_2 p6_11a_10_3 p6_11a_10_4
if _rc == 0 {
    replace horas_eventos_esc_lv = p6_11a_10_1 + (p6_11a_10_2/60) if !missing(p6_11a_10_1, p6_11a_10_2)
    replace horas_eventos_esc_sd = p6_11a_10_3 + (p6_11a_10_4/60) if !missing(p6_11a_10_3, p6_11a_10_4)
}
gen eventos_esc_tot = horas_eventos_esc_lv + horas_eventos_esc_sd


* -----------------------------
* 11. Cuidado simultáneo (p6_11a_11)
* -----------------------------
gen horas_cuidado_simultaneo_lv = 0
gen horas_cuidado_simultaneo_sd = 0

capture confirm variable p6_11a_11_1 p6_11a_11_2 p6_11a_11_3 p6_11a_11_4
if _rc == 0 {
    replace horas_cuidado_simultaneo_lv = p6_11a_11_1 + (p6_11a_11_2/60) if !missing(p6_11a_11_1, p6_11a_11_2)
    replace horas_cuidado_simultaneo_sd = p6_11a_11_3 + (p6_11a_11_4/60) if !missing(p6_11a_11_3, p6_11a_11_4)
}
gen cuidado_simultaneo_tot = horas_cuidado_simultaneo_lv + horas_cuidado_simultaneo_sd


* =============================================================
* VARIABLE FINAL: Tiempo total en cuidados especiales
* =============================================================
gen cuidados_especiales_tot = ///
    ayudar_comer_tot + aseo_tot + cargar_tot + remedios_tot + medicamentos_tot + ///
    transporte_salud_tot + terapia_tot + transporte_clases_tot + ///
    apoyo_tareas_tot + eventos_esc_tot + cuidado_simultaneo_tot

* =============================================================
* ESTADÍSTICAS DESCRIPTIVAS
* =============================================================
svy: mean cuidados_especiales_tot
svy: mean cuidados_especiales_tot if p5_1 == 1 & p6_11_01 == 1
svy: mean cuidados_especiales_tot if p5_1 == 2
svy: mean cuidados_especiales_tot if p6_11_01 == 1

* =============================================================
* CÁLCULO DEL TIEMPO TOTAL DEDICADO A CUIDADOS ESPECIALES (P6_11A)
* Este bloque calcula el tiempo total semanal (L-V y S-D) destinado a
* 11 actividades de cuidados especiales según la ENUT 2019.
* =============================================================

* Inicializamos acumuladores para lunes a viernes y fin de semana
gen horas_cuidado_esp_lv = 0
gen horas_cuidado_esp_sd = 0

* Bucle sobre los 11 tipos de cuidado especial (p6_11a_01 a p6_11a_11)
forvalues i = 1/11 {
    
    * Formato con ceros a la izquierda (01, 02, ..., 11)
    local j = string(`i', "%02.0f")
    
    * Validamos que existan las 4 variables necesarias por actividad
    capture confirm variable p6_11a_`j'_1 p6_11a_`j'_2 p6_11a_`j'_3 p6_11a_`j'_4
    if _rc == 0 {
        
        * Sumamos horas y minutos para lunes a viernes
        replace horas_cuidado_esp_lv = horas_cuidado_esp_lv + ///
            p6_11a_`j'_1 + (p6_11a_`j'_2 / 60) if !missing(p6_11a_`j'_1, p6_11a_`j'_2)
        
        * Sumamos horas y minutos para sábado y domingo
        replace horas_cuidado_esp_sd = horas_cuidado_esp_sd + ///
            p6_11a_`j'_3 + (p6_11a_`j'_4 / 60) if !missing(p6_11a_`j'_3, p6_11a_`j'_4)
    }
}

* Variable final: tiempo total en cuidados especiales por semana
gen horas_cuidado_esp_totales = horas_cuidado_esp_lv + horas_cuidado_esp_sd

* =============================================================
* ESTADÍSTICAS DESCRIPTIVAS
* =============================================================

* Promedio general de horas semanales dedicadas a cuidados especiales
summarize horas_cuidado_esp_totales
svy: mean horas_cuidado_esp_totales
* Promedio entre quienes reportaron tener personas que requieren cuidados
summarize horas_cuidado_esp_totales if fp6_11 == 1
svy: mean horas_cuidado_esp_totales if fp6_11 == 1
* Nota: fp6_11 indica que en el hogar hay una persona que requiere cuidados

* Promedio entre quienes declararon haber brindado los cuidados
summarize horas_cuidado_esp_totales if p6_11_01 == 1
svy: mean horas_cuidado_esp_totales if p6_11_01 == 1
* Nota: p6_11_01 indica que el informante fue quien proporcionó los cuidados

* =============================================================
* CÁLCULO DEL TIEMPO SEMANAL DESTINADO AL CUIDADO DE INFANTES
* Variables: p6_12a_1_* a p6_12a_3_*
* =============================================================

* Inicializamos acumuladores para lunes a viernes (LV) y sábado/domingo (SD)
gen horas_cuidado_ninos_lv = 0
gen horas_cuidado_ninos_sd = 0

* Iteramos sobre las 3 actividades del bloque p6_12a
forvalues i = 1/3 {
    
    * Validamos que existan las 4 variables necesarias para cada ítem
    capture confirm variable p6_12a_`i'_1 p6_12a_`i'_2 p6_12a_`i'_3 p6_12a_`i'_4
    if _rc == 0 {
        * Sumamos horas y minutos para Lunes a Viernes
        replace horas_cuidado_ninos_lv = horas_cuidado_ninos_lv + ///
            p6_12a_`i'_1 + (p6_12a_`i'_2 / 60) if !missing(p6_12a_`i'_1, p6_12a_`i'_2)

        * Sumamos horas y minutos para Sábado y Domingo
        replace horas_cuidado_ninos_sd = horas_cuidado_ninos_sd + ///
            p6_12a_`i'_3 + (p6_12a_`i'_4 / 60) if !missing(p6_12a_`i'_3, p6_12a_`i'_4)
    }
    else {
        display "Error: Variables p6_12a_`i'_* no encontradas"
    }
}

* Creamos la variable final: tiempo total semanal dedicado a cuidado infantil
gen horas_cuidado_ninos_totales = horas_cuidado_ninos_lv + horas_cuidado_ninos_sd

* =============================================================
* ESTADÍSTICAS DESCRIPTIVAS
* =============================================================

* Promedio general de horas dedicadas al cuidado de infantes
summarize horas_cuidado_ninos_totales
svy: mean horas_cuidado_ninos_totales
* Promedio solo entre hogares donde hay infantes
* (fp6_12 == 1 indica presencia de al menos un niño o niña en el hogar)
summarize horas_cuidado_ninos_totales if fp6_12 == 1
svy: mean horas_cuidado_ninos_totales if fp6_12 == 1
*  resultado: promedio = 10.5 h/semana, 3.2 h por debajo del dato INEGI
* Confirmación de que no hay observaciones donde no hay infantes
summarize horas_cuidado_ninos_totales if fp6_12 == 2
svy: mean horas_cuidado_ninos_totales if fp6_12 == 2

* ================================================================================
* 	CÁLCULO DEL TIEMPO SEMANAL DESTINADO AL CUIDADO DE INFANTES DE 0 A 14 SIN CUIDADOS ESPECIALES
* que no requieren cuidados especiales (guardería, tareas, atención médica, etc.)
* ================================================================================

* -----------------------
* 1. HORAS EN GUARDERÍA
* -----------------------
gen horas_guarderia_lv = 0  
gen horas_guarderia_sd = 0

foreach var in p6_13a_1_1 p6_13a_1_2 p6_13a_1_3 p6_13a_1_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_13a_1_1 p6_13a_1_2 p6_13a_1_3 p6_13a_1_4
if _rc == 0 {
    replace horas_guarderia_lv = p6_13a_1_1 + (p6_13a_1_2/60) if !missing(p6_13a_1_1, p6_13a_1_2)
    replace horas_guarderia_sd = p6_13a_1_3 + (p6_13a_1_4/60) if !missing(p6_13a_1_3, p6_13a_1_4)
}
else {
    display "⚠️ Error: Variables p6_13a_1_* no encontradas"
}

gen horas_guarderia_totales = horas_guarderia_lv + horas_guarderia_sd


* ----------------------------------------
* 2. HORAS EN APOYO EN TAREAS ESCOLARES
* ----------------------------------------
gen horas_tareas_escolares_lv = 0  
gen horas_tareas_escolares_sd = 0  

foreach var in p6_13a_3_1 p6_13a_3_2 p6_13a_3_3 p6_13a_3_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_13a_3_1 p6_13a_3_2 p6_13a_3_3 p6_13a_3_4
if _rc == 0 {
    replace horas_tareas_escolares_lv = p6_13a_3_1 + (p6_13a_3_2/60) if !missing(p6_13a_3_1, p6_13a_3_2)
    replace horas_tareas_escolares_sd = p6_13a_3_3 + (p6_13a_3_4/60) if !missing(p6_13a_3_3, p6_13a_3_4)
}
else {
    display "⚠️ Error: Variables p6_13a_3_* no encontradas"
}

gen horas_tareas_escolares_totales = horas_tareas_escolares_lv + horas_tareas_escolares_sd


* -------------------------------------------
* 3. HORAS EN ACTIVIDADES ESCOLARES GENERALES
* -------------------------------------------
gen horas_actividades_esc_lv = 0  
gen horas_actividades_esc_sd = 0  

foreach var in p6_13a_4_1 p6_13a_4_2 p6_13a_4_3 p6_13a_4_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_13a_4_1 p6_13a_4_2 p6_13a_4_3 p6_13a_4_4
if _rc == 0 {
    replace horas_actividades_esc_lv = p6_13a_4_1 + (p6_13a_4_2/60) if !missing(p6_13a_4_1, p6_13a_4_2)
    replace horas_actividades_esc_sd = p6_13a_4_3 + (p6_13a_4_4/60) if !missing(p6_13a_4_3, p6_13a_4_4)
}
else {
    display "⚠️ Error: Variables p6_13a_4_* no encontradas"
}

gen horas_actividades_esc_totales = horas_actividades_esc_lv + horas_actividades_esc_sd


* ----------------------------------
* 4. HORAS EN ATENCIÓN MÉDICA
* ----------------------------------
gen horas_atencion_medica_lv = 0
gen horas_atencion_medica_sd = 0

foreach var in p6_13a_5_1 p6_13a_5_2 p6_13a_5_3 p6_13a_5_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_13a_5_1 p6_13a_5_2 p6_13a_5_3 p6_13a_5_4
if _rc == 0 {
    replace horas_atencion_medica_lv = p6_13a_5_1 + (p6_13a_5_2/60) if !missing(p6_13a_5_1, p6_13a_5_2)
    replace horas_atencion_medica_sd = p6_13a_5_3 + (p6_13a_5_4/60) if !missing(p6_13a_5_3, p6_13a_5_4)
}
else {
    display "⚠️ Error: Variables p6_13a_5_* no encontradas"
}

gen horas_atencion_medica_totales = horas_atencion_medica_lv + horas_atencion_medica_sd


* ----------------------------------
* 5. HORAS EN CUIDADO GENERAL DE NIÑOS
* ----------------------------------
gen horas_cuidado_general_lv = 0
gen horas_cuidado_general_sd = 0

foreach var in p6_13a_6_1 p6_13a_6_2 p6_13a_6_3 p6_13a_6_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_13a_6_1 p6_13a_6_2 p6_13a_6_3 p6_13a_6_4
if _rc == 0 {
    replace horas_cuidado_general_lv = p6_13a_6_1 + (p6_13a_6_2/60) if !missing(p6_13a_6_1, p6_13a_6_2)
    replace horas_cuidado_general_sd = p6_13a_6_3 + (p6_13a_6_4/60) if !missing(p6_13a_6_3, p6_13a_6_4)
}
else {
    display "⚠️ Error: Variables p6_13a_6_* no encontradas"
}

gen horas_cuidado_general_totales = horas_cuidado_general_lv + horas_cuidado_general_sd


* =============================================================
* VARIABLE FINAL: TIEMPO TOTAL EN CUIDADOS DE INFANTES (0–14)
* =============================================================
gen horas_cuidados_esp_14_tot = horas_guarderia_totales + horas_tareas_escolares_totales + ///
                                horas_actividades_esc_totales + horas_atencion_medica_totales + ///
                                horas_cuidado_general_totales

* -------------------------------------------------------------
* ESTADÍSTICA DESCRIPTIVA FINAL
* -------------------------------------------------------------
* Solo se calcula para hogares con infantes (fp6_13 == 1)
summarize horas_cuidados_esp_14_tot if fp6_13 == 1
svy: mean horas_cuidados_esp_14_tot if fp6_13 == 1
* Resultado observado: 16.29 h/semana
* Según INEGI: 22 h/semana ➤ Diferencia: 5.7 h menos

* ============================================================================
* 	CÁLCULO DEL TIEMPO SEMANAL DESTINADO AL CUIDADO DE PERSONAS DE 15 A 60 AÑOS
* BLOQUE P6_14A: Tiempo semanal destinado al cuidado de personas de 15 a 60 años
* ============================================================================

* Inicializamos acumuladores para lunes-viernes y sábado-domingo
gen horas_cuidados_adultos_lv = 0  
gen horas_cuidados_adultos_sd = 0  

* Recorremos las 3 actividades de cuidado para adultos (índice 1 a 3)
forvalues i = 1/3 {  

    * Verificamos existencia de las 4 variables asociadas a cada actividad (horas/min LV y SD)
    capture confirm variable p6_14a_`i'_1 p6_14a_`i'_2 p6_14a_`i'_3 p6_14a_`i'_4
    if _rc == 0 {

        * Limpieza de datos: convertir strings a numéricos y tratar valores vacíos o 'b'
        foreach suf in 1 2 3 4 {
            capture confirm string variable p6_14a_`i'_`suf'
            if !_rc {
                replace p6_14a_`i'_`suf' = "0" if inlist(p6_14a_`i'_`suf', "b", "", " ", ".")
                destring p6_14a_`i'_`suf', replace
            }
            replace p6_14a_`i'_`suf' = 0 if missing(p6_14a_`i'_`suf')
        }

        * Sumar al total de lunes-viernes si no hay valores perdidos
        replace horas_cuidados_adultos_lv = horas_cuidados_adultos_lv + ///
            p6_14a_`i'_1 + (p6_14a_`i'_2 / 60) if !missing(p6_14a_`i'_1, p6_14a_`i'_2)

        * Sumar al total de sábado-domingo si no hay valores perdidos
        replace horas_cuidados_adultos_sd = horas_cuidados_adultos_sd + ///
            p6_14a_`i'_3 + (p6_14a_`i'_4 / 60) if !missing(p6_14a_`i'_3, p6_14a_`i'_4)

    }
    else {
        display "⚠️ Advertencia: Variables p6_14a_`i'_* no encontradas para actividad `i'"
    }
}

* Sumamos todas las horas semanales dedicadas al cuidado de adultos (15–60 años)
gen horas_cuidados_adultos_totales = horas_cuidados_adultos_lv + horas_cuidados_adultos_sd 

* ---------------------------------------------------------------------------
* ESTADÍSTICA DESCRIPTIVA FINAL
* ---------------------------------------------------------------------------
* Solo para hogares donde se identificaron personas de 15–60 años con necesidad de cuidado
summarize horas_cuidados_adultos_totales if fp6_14 == 1
svy: mean horas_cuidados_adultos_totales if fp6_14 == 1
* Resultado observado: 0.54 h/semana
* Según INEGI: 3.0 h/semana ➤ Diferencia: 2.5 h menos

* ============================================================================
* CÁLCULO DEL TIEMPO SEMANAL DESTINADO AL CUIDADO DE PERSONAS DE  60 AÑOS Ó MÁS.
* de 60 años, por actividad específica y por día de la semana.
* ============================================================================

* Inicializamos acumuladores para lunes-viernes y sábado-domingo
gen horas_cuidados_60plus_lv = 0  
gen horas_cuidados_60plus_sd = 0  

* Recorremos las 4 actividades reportadas en la ENUT para este grupo etario
forvalues i = 1/4 {

    * Verificamos existencia de todas las variables asociadas a la actividad i
    capture confirm variable p6_15a_`i'_1 p6_15a_`i'_2 p6_15a_`i'_3 p6_15a_`i'_4
    if _rc == 0 {

        * Limpieza de datos: conversiones de string a numérico y tratamiento de vacíos
        foreach suf in 1 2 3 4 {
            capture {
                confirm string variable p6_15a_`i'_`suf'
                if !_rc replace p6_15a_`i'_`suf' = "0" if inlist(p6_15a_`i'_`suf', "b", "", " ", ".")
                destring p6_15a_`i'_`suf', replace
                replace p6_15a_`i'_`suf' = 0 if missing(p6_15a_`i'_`suf')
            }
        }

        * Acumulamos tiempo de lunes a viernes si hay datos válidos
        replace horas_cuidados_60plus_lv = horas_cuidados_60plus_lv + ///
            p6_15a_`i'_1 + (p6_15a_`i'_2 / 60) if !missing(p6_15a_`i'_1, p6_15a_`i'_2)

        * Acumulamos tiempo de sábado y domingo si hay datos válidos
        replace horas_cuidados_60plus_sd = horas_cuidados_60plus_sd + ///
            p6_15a_`i'_3 + (p6_15a_`i'_4 / 60) if !missing(p6_15a_`i'_3, p6_15a_`i'_4)

    }
    else {
        display "⚠️ Advertencia: Variables p6_15a_`i'_* no encontradas (actividad `i')"
    }
}

* Sumamos el total semanal de horas destinadas al cuidado de adultos mayores
gen horas_cuidados_60_totales = horas_cuidados_60plus_lv + horas_cuidados_60plus_sd

* ---------------------------------------------------------------------------
* ESTADÍSTICAS DESCRIPTIVAS
* ---------------------------------------------------------------------------

* Sólo aplicamos resumen a hogares donde hay personas de 60 años que requieren cuidado
summarize horas_cuidados_60_totales if fp6_15 == 1
svy: mean horas_cuidados_60_totales if fp6_15 == 1
* Resultado observado: 4.4 horas semanales por hogar con adulto mayor que requiere cuidados
* Cifra reportada por INEGI: 16.9 horas ➤ Diferencia: 12.5 horas menos.

* ============================================================================
* VARIABLE TOTAL DE TRABAJO NO REMUNERADO DE CUIDADO A INTEGRANTES DEL HOGAR. 
* ============================================================================

gen tiempo_tdcnr_total = horas_cuidados_60_totales + horas_cuidados_adultos_totales + horas_cuidados_esp_14_tot + horas_cuidado_ninos_totales + horas_cuidado_esp_totales + cuidados_especiales_tot
svy: mean tiempo_tdcnr_total 

* ============================================================================
* TRABAJO DOMÉSTICO NO REMUNERADO PARA OTRO HOGAR (P6_16A)
* Componentes:
*   - Quehaceres domésticos (p6_16a_1_1 a p6_16a_1_4)
*   - Trámites, pagos y reparaciones (p6_16a_2_1 a p6_16a_2_4)
* ============================================================================

* Limpieza y conversión: convertimos strings y missing a cero
foreach i in 1 2 {
    foreach suf in 1 2 3 4 {
        capture confirm string variable p6_16a_`i'_`suf'
        if !_rc {
            replace p6_16a_`i'_`suf' = "0" if inlist(p6_16a_`i'_`suf', "b", "", " ", ".")
            destring p6_16a_`i'_`suf', replace
        }
        replace p6_16a_`i'_`suf' = 0 if missing(p6_16a_`i'_`suf')
    }
}

* ───── COMPONENTE 1: Quehaceres domésticos para otro hogar ─────

gen horas_quehacer_ajenos_lv = p6_16a_1_1 + (p6_16a_1_2 / 60)   // Lunes a viernes
gen horas_quehacer_ajenos_sd = p6_16a_1_3 + (p6_16a_1_4 / 60)   // Sábado y domingo
gen horas_quehacer_ajenos_tot = horas_quehacer_ajenos_lv + horas_quehacer_ajenos_sd

* ───── COMPONENTE 2: Trámites, pagos y reparaciones para otro hogar ─────

gen horas_tramites_ajenos_lv = p6_16a_2_1 + (p6_16a_2_2 / 60)   // Lunes a viernes
gen horas_tramites_ajenos_sd = p6_16a_2_3 + (p6_16a_2_4 / 60)   // Sábado y domingo
gen horas_tramites_ajenos_tot = horas_tramites_ajenos_lv + horas_tramites_ajenos_sd

* ───── VARIABLE FINAL ─────

gen trabajo_domestico_otro_hogar = horas_quehacer_ajenos_tot + horas_tramites_ajenos_tot

* ───── ESTADÍSTICAS DESCRIPTIVAS ─────

summarize trabajo_domestico_otro_hogar
svy: mean horas_quehacer_ajenos_tot if p6_16_1 == 1 & p6_16_2 == 1 
svy: mean horas_tramites_ajenos_to
svy: mean trabajo_domestico_otro_hogar

* ============================================================================
* CUIDADOS ESPECIALES A PERSONAS DE OTRO HOGAR 
* Incluye cuidado de personas con discapacidad, menores, adultos y adultos mayores.
* ============================================================================

* Primero limpiamos y convertimos las variables de cada componente
forvalues i = 3/6 {
    foreach suf in 1 2 3 4 {
        capture confirm string variable p6_16a_`i'_`suf'
        if !_rc {
            replace p6_16a_`i'_`suf' = "0" if inlist(p6_16a_`i'_`suf', "b", "", " ", ".")
            destring p6_16a_`i'_`suf', replace
        }
        replace p6_16a_`i'_`suf' = 0 if missing(p6_16a_`i'_`suf')
    }
}

* ───── COMPONENTE 1: Atención o cuidado a personas con discapacidad ─────
gen horas_aten_cui_disca_lv = p6_16a_3_1 + (p6_16a_3_2 / 60)
gen horas_aten_cui_disca_sd = p6_16a_3_3 + (p6_16a_3_4 / 60)
gen horas_aten_cui_disca = horas_aten_cui_disca_lv + horas_aten_cui_disca_sd 

* ============================================================================
* CUIDADOS PROPIOS DE LA EDAD A PERSONAS DE OTRO HOGAR 
* Incluye cuidado de personas con discapacidad, menores, adultos y adultos mayores.
* ===========================================================================

* ───── COMPONENTE 1: Cuidado de niñas/niños ─────
gen horas_cui_menores_lv = p6_16a_4_1 + (p6_16a_4_2 / 60)
gen horas_cui_menores_sd = p6_16a_4_3 + (p6_16a_4_4 / 60)
gen horas_cui_menores = horas_cui_menores_lv + horas_cui_menores_sd

* ───── COMPONENTE 2: Cuidado de adultos ─────
gen horas_cui_adultos_lv = p6_16a_5_1 + (p6_16a_5_2 / 60)
gen horas_cui_adultos_sd = p6_16a_5_3 + (p6_16a_5_4 / 60)
gen horas_cui_adultos = horas_cui_adultos_lv + horas_cui_adultos_sd

* ───── COMPONENTE 3: Cuidado de adultos mayores ─────
gen horas_adultos_mayores_lv = p6_16a_6_1 + (p6_16a_6_2 / 60)
gen horas_adultos_mayores_sd = p6_16a_6_3 + (p6_16a_6_4 / 60)
gen horas_adultos_mayores = horas_adultos_mayores_lv + horas_adultos_mayores_sd

* ───── VARIABLE FINAL: Total cuidados propios de la edad a personas de otro hogar ─────
gen cuidados_otro_hogar =  horas_cui_menores + horas_cui_adultos + horas_adultos_mayores

* ───── ESTADÍSTICAS DESCRIPTIVAS ─────
summarize cuidados_otro_hogar
svy: mean cuidados_otro_hogar if p6_16_4 == 1 | p6_16_5 == 1 | p6_16_6 == 1
svy: mean horas_aten_cui_disca if p6_16_3 == 1
svy: mean horas_cui_menores if p6_16_4 == 1
svy: mean horas_cui_adultos if p6_16_5 == 1
svy: mean horas_adultos_mayores if p6_16_6 == 1

*---------------------------------------------------------------*
* TRABAJO NO REMUNERADO VOLUNTARIO                             *
*---------------------------------------------------------------*

* Componente 1: Trabajo voluntario en organizaciones (p6_17a_1)
gen horas_voluntariado_lv = 0
gen horas_voluntariado_sd = 0

foreach var in p6_17a_1_1 p6_17a_1_2 p6_17a_1_3 p6_17a_1_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_17a_1_1 p6_17a_1_2 p6_17a_1_3 p6_17a_1_4
if _rc == 0 {
    replace horas_voluntariado_lv = p6_17a_1_1 + (p6_17a_1_2 / 60) if !missing(p6_17a_1_1, p6_17a_1_2)
    replace horas_voluntariado_sd = p6_17a_1_3 + (p6_17a_1_4 / 60) if !missing(p6_17a_1_3, p6_17a_1_4)
} 
else {
    display "Advertencia: Variables p6_17a_1_* no encontradas"
}

gen horas_voluntariado = horas_voluntariado_lv + horas_voluntariado_sd

* Componente 2: Trabajo comunitario o en beneficio del entorno (p6_17a_2)
gen horas_trabajo_comun_lv = 0
gen horas_trabajo_comun_sd = 0

foreach var in p6_17a_2_1 p6_17a_2_2 p6_17a_2_3 p6_17a_2_4 {
    capture confirm string variable `var'
    if !_rc {
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

capture confirm variable p6_17a_2_1 p6_17a_2_2 p6_17a_2_3 p6_17a_2_4
if _rc == 0 {
    replace horas_trabajo_comun_lv = p6_17a_2_1 + (p6_17a_2_2 / 60) if !missing(p6_17a_2_1, p6_17a_2_2)
    replace horas_trabajo_comun_sd = p6_17a_2_3 + (p6_17a_2_4 / 60) if !missing(p6_17a_2_3, p6_17a_2_4)
}
else {
    display "Advertencia: Variables p6_17a_2_* no encontradas"
}

gen horas_trabajo_comun = horas_trabajo_comun_lv + horas_trabajo_comun_sd

* Variable total: Trabajo no remunerado voluntario
gen trabajo_no_rem_voluntario = horas_voluntariado + horas_trabajo_comun

* Exploración de resultados
summarize trabajo_no_rem_voluntario
svy: mean trabajo_no_rem_voluntario if p6_17_1 == 1 | p6_17_2 == 1

*---------------------------------------------------------------------------------------------------------------------*
* VARIABLE TOOTAL: Trabajo no remunerado como apoyo  a otros hogares y trabajo voluntario
*----------------------------------------------------------------------------------------------------------------------*
gen trabajo_nrcah_total = trabajo_domestico_otro_hogar + cuidados_otro_hogar + horas_aten_cui_disca + trabajo_no_rem_voluntario
svy: mean trabajo_nrcah_total
*-------------------------------------------------------------*
* Tiempo dedicado a dormir
* Compuesto por p6_1_1_1 a p6_1_1_4
*-------------------------------------------------------------*

* Inicializamos variables para horas de lunes-viernes (lv) y sábado-domingo (sd)
gen horas_dormir_lv = 0
gen horas_dormir_sd = 0

* Aseguramos que las variables de horas y minutos estén limpias y en formato numérico
foreach var in p6_1_1_1 p6_1_1_2 p6_1_1_3 p6_1_1_4 {
    capture confirm string variable `var'
    if !_rc {                               // Si la variable es de tipo string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")  // Reemplaza blancos o puntos por 0
        destring `var', replace                              // Convierte a numérico
    }
    replace `var' = 0 if missing(`var')                      // Si es missing, poner 0
}

* Sumamos horas y minutos para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_1_1_1 p6_1_1_2 p6_1_1_3 p6_1_1_4
if _rc == 0 {
    replace horas_dormir_lv = p6_1_1_1 + (p6_1_1_2/60) if !missing(p6_1_1_1, p6_1_1_2)
    replace horas_dormir_sd = p6_1_1_3 + (p6_1_1_4/60) if !missing(p6_1_1_3, p6_1_1_4)
}
else {
    di as error "Error: Variables p6_1_1_* no encontradas"
}

* Variable total de horas dedicadas a dormir
gen horas_dormir_totales = horas_dormir_lv + horas_dormir_sd

* Resumen estadístico general
summarize horas_dormir_totales
svy: mean horas_dormir_totales // Es exactamente el mismo que el reportado por INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado a comer alimentos
* Compuesto por p6_1_2_1 a p6_1_2_4
*-------------------------------------------------------------*

* Inicializamos variables para horas lunes-viernes (lv) y sábado-domingo (sd)
gen horas_comer_lv = 0
gen horas_comer_sd = 0

* Limpieza y conversión de las variables de horas y minutos
foreach var in p6_1_2_1 p6_1_2_2 p6_1_2_3 p6_1_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                  // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".") // Reemplazar blancos/puntos por 0
        destring `var', replace                                // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                        // Reemplazar missing por 0
}

* Sumar horas y minutos para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_1_2_1 p6_1_2_2 p6_1_2_3 p6_1_2_4
if _rc == 0 {
    replace horas_comer_lv = p6_1_2_1 + (p6_1_2_2/60) if !missing(p6_1_2_1, p6_1_2_2)
    replace horas_comer_sd = p6_1_2_3 + (p6_1_2_4/60) if !missing(p6_1_2_3, p6_1_2_4)
}
else {
    di as error "Error: Variables p6_1_2_* no encontradas"
}

* Variable total de horas dedicadas a comer alimentos
gen horas_comer_totales = horas_comer_lv + horas_comer_sd

* Resumen estadístico general
summarize horas_comer_totales
svy: mean horas_comer_totales // Es exactamete el mismo que INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado al aseo personal
* Compuesto por p6_1_3_1 a p6_1_3_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_aseo_propio_lv = 0
gen horas_aseo_propio_sd = 0

* Limpieza y conversión de las variables de horas y minutos
foreach var in p6_1_3_1 p6_1_3_2 p6_1_3_3 p6_1_3_4 {
    capture confirm string variable `var'
    if !_rc {                                                  // Si es tipo string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".") // Reemplazar blancos/puntos por 0
        destring `var', replace                                // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                        // Reemplazar missing por 0
}

* Sumar horas y minutos para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_1_3_1 p6_1_3_2 p6_1_3_3 p6_1_3_4
if _rc == 0 {
    replace horas_aseo_propio_lv = p6_1_3_1 + (p6_1_3_2/60) if !missing(p6_1_3_1, p6_1_3_2)
    replace horas_aseo_propio_sd = p6_1_3_3 + (p6_1_3_4/60) if !missing(p6_1_3_3, p6_1_3_4)
}
else {
    di as error "Error: Variables p6_1_3_* no encontradas"
}

* Variable total de horas dedicadas al aseo personal
gen horas_aseo_totales = horas_aseo_propio_lv + horas_aseo_propio_sd

* Resumen estadístico general
summarize horas_aseo_totales
svy: mean horas_aseo_totales // Da el mismo resultado que INEGI. 

*----------------------------------------------------------------------------*
* VARIABLE TOTAL: TIEMPO TOTAL DE AUTOCUIDADO
*----------------------------------------------------------------------------*
gen tiempo_total_autocuidado = horas_aseo_totales + horas_comer_totales + horas_dormir_totales
svy: mean tiempo_total_autocuidado // Da un total de 67.51 horas. Con la misma población reportada por INEGI. 
*-------------------------------------------------------------*
* Tiempo dedicado a asistir a clases
* Compuesto por p6_2a_1_1 a p6_2a_1_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_asistir_clases_lv = 0
gen horas_asistir_clases_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_2a_1_1 p6_2a_1_2 p6_2a_1_3 p6_2a_1_4 {
    capture confirm string variable `var'
    if !_rc {                                                   // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".") // Reemplazar vacíos por 0
        destring `var', replace                                 // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                         // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_2a_1_1 p6_2a_1_2 p6_2a_1_3 p6_2a_1_4
if _rc == 0 {
    replace horas_asistir_clases_lv = p6_2a_1_1 + (p6_2a_1_2/60) if !missing(p6_2a_1_1, p6_2a_1_2)
    replace horas_asistir_clases_sd = p6_2a_1_3 + (p6_2a_1_4/60) if !missing(p6_2a_1_3, p6_2a_1_4)
}
else {
    di as error "Error: Variables p6_2a_1_* no encontradas"
}

* Variable total de horas dedicadas a asistir a clases
gen horas_asistir_clases_totales = horas_asistir_clases_lv + horas_asistir_clases_sd

* Resumen estadístico general
summarize horas_asistir_clases_totales
svy: mean horas_asistir_clases_totales if p6_2_1 == 1 // Es el mismo que el reportado por INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado a tareas y trabajos escolares
* Compuesto por p6_2a_2_1 a p6_2a_2_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_tareas_lv = 0
gen horas_tareas_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_2a_2_1 p6_2a_2_2 p6_2a_2_3 p6_2a_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                   // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".") // Reemplazar vacíos por 0
        destring `var', replace                                 // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                         // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_2a_2_1 p6_2a_2_2 p6_2a_2_3 p6_2a_2_4
if _rc == 0 {
    replace horas_tareas_lv = p6_2a_2_1 + (p6_2a_2_2/60) if !missing(p6_2a_2_1, p6_2a_2_2)
    replace horas_tareas_sd = p6_2a_2_3 + (p6_2a_2_4/60) if !missing(p6_2a_2_3, p6_2a_2_4)
}
else {
    di as error "Error: Variables p6_2a_2_* no encontradas"
}

* Variable total de horas dedicadas a tareas escolares
gen horas_tareas_totales = horas_tareas_lv + horas_tareas_sd

* Resumen estadístico general
summarize horas_tareas_totales
svy: mean horas_tareas_totales if p6_2_2 == 1 // Es exactatamente el mismo dato que INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado a traslados a la escuela
* Compuesto por p6_2a_3_1 a p6_2a_3_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_traslado_escuela_lv = 0
gen horas_traslado_escuela_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_2a_3_1 p6_2a_3_2 p6_2a_3_3 p6_2a_3_4 {
    capture confirm string variable `var'
    if !_rc {                                                        // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")      // Reemplazar vacíos por 0
        destring `var', replace                                      // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                              // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_2a_3_1 p6_2a_3_2 p6_2a_3_3 p6_2a_3_4
if _rc == 0 {
    replace horas_traslado_escuela_lv = p6_2a_3_1 + (p6_2a_3_2/60) if !missing(p6_2a_3_1, p6_2a_3_2)
    replace horas_traslado_escuela_sd = p6_2a_3_3 + (p6_2a_3_4/60) if !missing(p6_2a_3_3, p6_2a_3_4)
}
else {
    di as error "Error: Variables p6_2a_3_* no encontradas"
}

* Variable total de horas dedicadas a traslados a la escuela
gen horas_traslado_escuela_totales = horas_traslado_escuela_lv + horas_traslado_escuela_sd

* Resumen estadístico general
summarize horas_traslado_escuela_totales
svy: mean horas_traslado_escuela_totales if p6_2_3 == 1 // Es el mismo dato que INEGI. 


*-------------------------------------------------------------*
* VARIABLE TOTAL: TIEMPO ESTUDIO
*-------------------------------------------------------------*

gen tiempo_estudio_total =  horas_traslado_escuela_totales + horas_tareas_totales + horas_asistir_clases_totales
svy: mean tiempo_estudio_total if p6_2_3 == 1 | p6_2_2 == 1 | p6_2_1 == 1 // Da un total de 43.22 horas con la población reportada para INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado a hacer deporte
* Compuesto por p6_18a_1 a p6_18a_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_deporte_lv = 0
gen horas_deporte_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_18a_1 p6_18a_2 p6_18a_3 p6_18a_4 {
    capture confirm string variable `var'
    if !_rc {                                                        // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")      // Reemplazar vacíos por 0
        destring `var', replace                                      // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                              // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_18a_1 p6_18a_2 p6_18a_3 p6_18a_4
if _rc == 0 {
    replace horas_deporte_lv = p6_18a_1 + (p6_18a_2/60) if !missing(p6_18a_1, p6_18a_2)
    replace horas_deporte_sd = p6_18a_3 + (p6_18a_4/60) if !missing(p6_18a_3, p6_18a_4)
}
else {
    di as error "Error: Variables p6_18a_* no encontradas"
}

* Variable total de horas dedicadas a hacer deporte
gen horas_deporte_totales = horas_deporte_lv + horas_deporte_sd

* Resumen estadístico general
summarize horas_deporte_totales
svy: mean horas_deporte_totales 

*-------------------------------------------------------------*
* Tiempo dedicado a juegos de mesa y azar
* Compuesto por p6_19a_2_1 a p6_19a_2_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_juegos_mesa_lv = 0
gen horas_juegos_mesa_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_19a_2_1 p6_19a_2_2 p6_19a_2_3 p6_19a_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                        // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")      // Vacíos o "b" → 0
        destring `var', replace                                      // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                              // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_19a_2_1 p6_19a_2_2 p6_19a_2_3 p6_19a_2_4
if _rc == 0 {
    replace horas_juegos_mesa_lv = p6_19a_2_1 + (p6_19a_2_2/60) if !missing(p6_19a_2_1, p6_19a_2_2)
    replace horas_juegos_mesa_sd = p6_19a_2_3 + (p6_19a_2_4/60) if !missing(p6_19a_2_3, p6_19a_2_4)
}
else {
    di as error "Error: Variables p6_19a_2_* no encontradas"
}

* Variable total de horas dedicadas a juegos de mesa y azar
gen horas_juegos_mesa_totales = horas_juegos_mesa_lv + horas_juegos_mesa_sd

* Resumen estadístico general
summarize horas_juegos_mesa_totales
svy: mean horas_juegos_mesa_totales if p6_19_2 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a actividades artísticas
* Compuesto por p6_19a_1_1 a p6_19a_1_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_actividades_artisticas_lv = 0
gen horas_actividades_artisticas_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_19a_1_1 p6_19a_1_2 p6_19a_1_3 p6_19a_1_4 {
    capture confirm string variable `var'
    if !_rc {                                                        // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")      // Vacíos o "b" → 0
        destring `var', replace                                      // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                              // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_19a_1_1 p6_19a_1_2 p6_19a_1_3 p6_19a_1_4
if _rc == 0 {
    replace horas_actividades_artisticas_lv = p6_19a_1_1 + (p6_19a_1_2/60) if !missing(p6_19a_1_1, p6_19a_1_2)
    replace horas_actividades_artisticas_sd = p6_19a_1_3 + (p6_19a_1_4/60) if !missing(p6_19a_1_3, p6_19a_1_4)
}
else {
    di as error "Error: Variables p6_19a_1_* no encontradas"
}

* Variable total de horas dedicadas a actividades artísticas
gen horas_actividades_art_tot = horas_actividades_artisticas_lv + horas_actividades_artisticas_sd

* Resumen estadístico general
summarize horas_actividades_art_tot
svy: mean horas_actividades_art_tot if p6_19_1 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a cultura y entretenimiento
* Compuesto por p6_20a_1 a p6_20a_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_cultura_entretenimiento_lv = 0
gen horas_cultura_entretenimiento_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_20a_1 p6_20a_2 p6_20a_3 p6_20a_4 {
    capture confirm string variable `var'
    if !_rc {                                                        // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")      // Vacíos o "b" → 0
        destring `var', replace                                      // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                              // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_20a_1 p6_20a_2 p6_20a_3 p6_20a_4
if _rc == 0 {
    replace horas_cultura_entretenimiento_lv = p6_20a_1 + (p6_20a_2/60) if !missing(p6_20a_1, p6_20a_2)
    replace horas_cultura_entretenimiento_sd = p6_20a_3 + (p6_20a_4/60) if !missing(p6_20a_3, p6_20a_4)
}
else {
    di as error "Error: Variables p6_20a_* no encontradas"
}

* Variable total de horas dedicadas a cultura y entretenimiento
gen horas_cultura_entre_total = horas_cultura_entretenimiento_lv + horas_cultura_entretenimiento_sd

* Resumen estadístico general
summarize horas_cultura_entre_total
svy: mean horas_cultura_entre_total if p6_20 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a ver películas, series, etc.
* Compuesto por p6_22a_1_1 a p6_22a_1_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_peliculas_series_lv = 0
gen horas_peliculas_series_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_22a_1_1 p6_22a_1_2 p6_22a_1_3 p6_22a_1_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Reemplazar vacíos o "b" por 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_22a_1_1 p6_22a_1_2 p6_22a_1_3 p6_22a_1_4
if _rc == 0 {
    replace horas_peliculas_series_lv = p6_22a_1_1 + (p6_22a_1_2/60) if !missing(p6_22a_1_1, p6_22a_1_2)
    replace horas_peliculas_series_sd = p6_22a_1_3 + (p6_22a_1_4/60) if !missing(p6_22a_1_3, p6_22a_1_4)
}
else {
    di as error "Error: Variables p6_22a_1_* no encontradas"
}

* Variable total de horas dedicadas a ver películas y series
gen horas_pelis_ser_tot = horas_peliculas_series_lv + horas_peliculas_series_sd

* Resumen estadístico general
summarize horas_pelis_ser_tot
svy: mean horas_pelis_ser_tot if p6_22_1 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a escuchar música, noticias, etc.
* Compuesto por p6_22a_2_1 a p6_22a_2_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_musica_noticias_lv = 0
gen horas_musica_noticias_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_22a_2_1 p6_22a_2_2 p6_22a_2_3 p6_22a_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Reemplazar vacíos o "b" por 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_22a_2_1 p6_22a_2_2 p6_22a_2_3 p6_22a_2_4
if _rc == 0 {
    replace horas_musica_noticias_lv = p6_22a_2_1 + (p6_22a_2_2/60) if !missing(p6_22a_2_1, p6_22a_2_2)
    replace horas_musica_noticias_sd = p6_22a_2_3 + (p6_22a_2_4/60) if !missing(p6_22a_2_3, p6_22a_2_4)
}
else {
    di as error "Error: Variables p6_22a_2_* no encontradas"
}

* Variable total de horas dedicadas a escuchar música y noticias
gen horas_musica_noticias_totales = horas_musica_noticias_lv + horas_musica_noticias_sd

* Resumen estadístico general
summarize horas_musica_noticias_totales
svy: mean horas_musica_noticias_totales if p6_22_2 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a redes sociales
* Compuesto por p6_22a_3_1 a p6_22a_3_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_redes_sociales_lv = 0
gen horas_redes_sociales_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_22a_3_1 p6_22a_3_2 p6_22a_3_3 p6_22a_3_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Reemplazar vacíos o "b" por 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_22a_3_1 p6_22a_3_2 p6_22a_3_3 p6_22a_3_4
if _rc == 0 {
    replace horas_redes_sociales_lv = p6_22a_3_1 + (p6_22a_3_2/60) if !missing(p6_22a_3_1, p6_22a_3_2)
    replace horas_redes_sociales_sd = p6_22a_3_3 + (p6_22a_3_4/60) if !missing(p6_22a_3_3, p6_22a_3_4)
}
else {
    di as error "Error: Variables p6_22a_3_* no encontradas"
}

* Variable total de horas dedicadas a redes sociales
gen horas_redes_sociales_totales = horas_redes_sociales_lv + horas_redes_sociales_sd

* Resumen estadístico general
summarize horas_redes_sociales_totales
svy: mean horas_redes_sociales_totales if p6_22_3 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a la lectura
* Incluye actividades como leer el periódico, artículos en línea,
* libros, revistas u otros materiales impresos o digitales.
* Compuesto por: p6_22a_4_1 a p6_22a_4_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_lectura_lv = 0
gen horas_lectura_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_22a_4_1 p6_22a_4_2 p6_22a_4_3 p6_22a_4_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Reemplazar valores no válidos por 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_22a_4_1 p6_22a_4_2 p6_22a_4_3 p6_22a_4_4
if _rc == 0 {
    replace horas_lectura_lv = p6_22a_4_1 + (p6_22a_4_2/60) if !missing(p6_22a_4_1, p6_22a_4_2)
    replace horas_lectura_sd = p6_22a_4_3 + (p6_22a_4_4/60) if !missing(p6_22a_4_3, p6_22a_4_4)
}
else {
    di as error "Error: Variables p6_22a_4_* no encontradas"
}

* Variable total de horas dedicadas a la lectura
gen horas_lectura_totales = horas_lectura_lv + horas_lectura_sd

* Resumen estadístico general
summarize horas_lectura_totales
svy: mean horas_lectura_totales if p6_22_4 == 1

*-------------------------------------------------------------*
* Tiempo dedicado al uso de internet (fines recreativos)
* Incluye actividades como descargas o búsquedas de información
* que NO están relacionadas con el estudio o el trabajo.
* Compuesto por: p6_22a_5_1 a p6_22a_5_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_internet_recreativo_lv = 0
gen horas_internet_recreativo_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_22a_5_1 p6_22a_5_2 p6_22a_5_3 p6_22a_5_4 {
    capture confirm string variable `var'
    if !_rc {                                                                // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")              // Reemplazar valores no válidos por 0
        destring `var', replace                                              // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                      // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_22a_5_1 p6_22a_5_2 p6_22a_5_3 p6_22a_5_4
if _rc == 0 {
    replace horas_internet_recreativo_lv = p6_22a_5_1 + (p6_22a_5_2/60) if !missing(p6_22a_5_1, p6_22a_5_2)
    replace horas_internet_recreativo_sd = p6_22a_5_3 + (p6_22a_5_4/60) if !missing(p6_22a_5_3, p6_22a_5_4)
}
else {
    di as error "Error: Variables p6_22a_5_* no encontradas"
}

* Variable total de horas dedicadas a internet recreativo
gen horas_internet_recrea_tot = horas_internet_recreativo_lv + horas_internet_recreativo_sd

* Resumen estadístico general
summarize horas_internet_recrea_tot
svy: mean horas_internet_recrea_tot if p6_22_5 == 1

*------------------------------------------------------------------------------------------*
* VARIABLE: USO DE MEDIOS MASIVOS DE COMUNICACIÓN:
*------------------------------------------------------------------------------------------*

gen horas_uso_medios = horas_internet_recrea_tot + horas_lectura_totales + horas_redes_sociales_totales + horas_musica_noticias_totales + horas_pelis_ser_tot
svy:mean horas_uso_medios if p6_22_5 == 1 | p6_22_4 == 1 | p6_22_3 == 1 | p6_22_2 == 1 | p6_22_1 == 1


*-------------------------------------------------------------*
* Tiempo dedicado a actividades religiosas
* Compuesto por p6_21a_2_1 a p6_21a_2_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_actividades_religiosas_lv = 0
gen horas_actividades_religiosas_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_21a_2_1 p6_21a_2_2 p6_21a_2_3 p6_21a_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Vacíos o "b" → 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_21a_2_1 p6_21a_2_2 p6_21a_2_3 p6_21a_2_4
if _rc == 0 {
    replace horas_actividades_religiosas_lv = p6_21a_2_1 + (p6_21a_2_2/60) if !missing(p6_21a_2_1, p6_21a_2_2)
    replace horas_actividades_religiosas_sd = p6_21a_2_3 + (p6_21a_2_4/60) if !missing(p6_21a_2_3, p6_21a_2_4)
}
else {
    di as error "Error: Variables p6_21a_2_* no encontradas"
}

* Variable total de horas dedicadas a actividades religiosas
gen horas_act_reli_tot = horas_actividades_religiosas_lv + horas_actividades_religiosas_sd

* Resumen estadístico general
summarize horas_act_reli_tot
svy: mean horas_act_reli_tot if p6_21_2 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a celebraciones cívicas
* Compuesto por p6_21a_3_1 a p6_21a_3_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_celeb_civ_lv = 0
gen horas_celeb_civ_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_21a_3_1 p6_21a_3_2 p6_21a_3_3 p6_21a_3_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Vacíos o "b" → 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_21a_3_1 p6_21a_3_2 p6_21a_3_3 p6_21a_3_4
if _rc == 0 {
    replace horas_celeb_civ_lv = p6_21a_3_1 + (p6_21a_3_2/60) if !missing(p6_21a_3_1, p6_21a_3_2)
    replace horas_celeb_civ_sd = p6_21a_3_3 + (p6_21a_3_4/60) if !missing(p6_21a_3_3, p6_21a_3_4)
}
else {
    di as error "Error: Variables p6_21a_3_* no encontradas"
}

* Variable total de horas dedicadas a celebraciones cívicas
gen horas_celebs_civ_tot = horas_celeb_civ_lv + horas_celeb_civ_sd

* Resumen estadístico general
summarize horas_celebs_civ_tot
svy: mean horas_celebs_civ_tot if p6_21_3 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a eventos sociales (bares, salidas, etc.)
* Compuesto por p6_21a_4_1 a p6_21a_4_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_eventos_sociales_lv = 0
gen horas_eventos_sociales_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_21a_4_1 p6_21a_4_2 p6_21a_4_3 p6_21a_4_4 {
    capture confirm string variable `var'
    if !_rc {                                                            // Si es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")          // Vacíos o "b" → 0
        destring `var', replace                                          // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                  // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_21a_4_1 p6_21a_4_2 p6_21a_4_3 p6_21a_4_4
if _rc == 0 {
    replace horas_eventos_sociales_lv = p6_21a_4_1 + (p6_21a_4_2/60) if !missing(p6_21a_4_1, p6_21a_4_2)
    replace horas_eventos_sociales_sd = p6_21a_4_3 + (p6_21a_4_4/60) if !missing(p6_21a_4_3, p6_21a_4_4)
}
else {
    di as error "Error: Variables p6_21a_4_* no encontradas"
}

* Variable total de horas dedicadas a eventos sociales
gen horas_even_soc_tot = horas_eventos_sociales_lv + horas_eventos_sociales_sd

* Resumen estadístico general
summarize horas_even_soc_tot
svy: mean horas_even_soc_tot if p6_21_4 == 1

*-----------------------------------------------------------------------------------------------------------------*
* V4RIABLE: TIEMPO DE CONVIVENCIA SOCIAL, Y PRACTICAS SOCIALES Y RELiGIOSAS
*-----------------------------------------------------------------------------------------------------------------*

gen conv_soc_relig_civic = horas_even_soc_tot + horas_celebs_civ_tot + horas_act_reli_tot
svy: mean conv_soc_relig_civic if p6_21_4 == 1| p6_21_3 == 1 | p6_21_2 == 1

*-------------------------------------------------------------*
* Tiempo dedicado a rezar, meditar o descansar
* Incluye actividades como oración, meditación, descanso breve
* o pausas de relajación durante el día.
* Compuesto por: p6_23a_1_1 a p6_23a_1_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_rezar_meditar_descansar_lv = 0
gen horas_rezar_meditar_descansar_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_23a_1_1 p6_23a_1_2 p6_23a_1_3 p6_23a_1_4 {
    capture confirm string variable `var'
    if !_rc {                                                                // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")              // Reemplazar valores no válidos por 0
        destring `var', replace                                              // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                      // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_23a_1_1 p6_23a_1_2 p6_23a_1_3 p6_23a_1_4
if _rc == 0 {
    replace horas_rezar_meditar_descansar_lv = p6_23a_1_1 + (p6_23a_1_2/60) if !missing(p6_23a_1_1, p6_23a_1_2)
    replace horas_rezar_meditar_descansar_sd = p6_23a_1_3 + (p6_23a_1_4/60) if !missing(p6_23a_1_3, p6_23a_1_4)
}
else {
    di as error "Error: Variables p6_23a_1_* no encontradas"
}

* Variable total de horas dedicadas a rezar, meditar o descansar
gen horas_rezar_meditar_desc_tot = horas_rezar_meditar_descansar_lv + horas_rezar_meditar_descansar_sd

* Resumen estadístico general
summarize horas_rezar_meditar_desc_tot
svy: mean horas_rezar_meditar_desc_tot if p6_23_1 == 1 // Es exactamente el mismo que el obtendo por INEGI. 

*-------------------------------------------------------------*
* Tiempo dedicado a recibir atención de salud
* Incluye actividades como terapias (físicas, psicológicas, ocupacionales),
* asistir a grupos de ayuda, rehabilitación o recuperación de alguna enfermedad.
* Compuesto por: p6_23a_2_1 a p6_23a_2_4
*-------------------------------------------------------------*

* Inicializamos variables para lunes-viernes (lv) y sábado-domingo (sd)
gen horas_atencion_salud_lv = 0
gen horas_atencion_salud_sd = 0

* Limpieza y conversión de variables (horas y minutos)
foreach var in p6_23a_2_1 p6_23a_2_2 p6_23a_2_3 p6_23a_2_4 {
    capture confirm string variable `var'
    if !_rc {                                                                // Si la variable es string
        replace `var' = "0" if inlist(`var', "b", "", " ", ".")              // Reemplazar valores no válidos por 0
        destring `var', replace                                              // Convertir a numérico
    }
    replace `var' = 0 if missing(`var')                                      // Missing → 0
}

* Cálculo de horas para días de semana (lv) y fines de semana (sd)
capture confirm variable p6_23a_2_1 p6_23a_2_2 p6_23a_2_3 p6_23a_2_4
if _rc == 0 {
    replace horas_atencion_salud_lv = p6_23a_2_1 + (p6_23a_2_2/60) if !missing(p6_23a_2_1, p6_23a_2_2)
    replace horas_atencion_salud_sd = p6_23a_2_3 + (p6_23a_2_4/60) if !missing(p6_23a_2_3, p6_23a_2_4)
}
else {
    di as error "Error: Variables p6_23a_2_* no encontradas"
}

* Variable total de horas dedicadas a recibir atención de salud
gen horas_atencion_salud_totales = horas_atencion_salud_lv + horas_atencion_salud_sd

* Resumen estadístico general
summarize horas_atencion_salud_totales
svy: mean horas_atencion_salud_totales if p6_23_2 == 1 // Es exactamente el mismo dato de INEGI. 

*-----------------------------------------------------------------------------------------------------------------------------------*
* PROCESO DE CONSTRUCCIÓN DEL MODELO LOGIT
*-----------------------------------------------------------------------------------------------------------------------------------*

*--------------------------------------------------------------------*
* Cálculo de carga total de trabajo
*--------------------------------------------------------------------*
gen horas_trabajo_total = horas_trabajo_remunerado + trabajo_domestico_phogar + ///
                          tiempo_tdcnr_total + trabajo_nrcah_total

*--------------------------------------------------------------------*
* 1) Medidas relativas (Covarrubias 2019, p.8)
*--------------------------------------------------------------------*
sum horas_trabajo_total, detail
local mediana = r(p50)

* Pobreza R: 1.5 × mediana
local umbral_R = `mediana' * 1.5
gen pobreza_R = horas_trabajo_total > `umbral_R'

* Pobreza E: 2 × mediana
local umbral_E = `mediana' * 2
gen pobreza_E = horas_trabajo_total > `umbral_E'

*--------------------------------------------------------------------*
* 2) Medida absoluta (Pobreza V)
*--------------------------------------------------------------------*
* Tiempo disponible = 168 - carga total de trabajo
gen tiempo_disponible = 168 - horas_trabajo_total
gen pobreza_V = tiempo_disponible < 81

*--------------------------------------------------------------------*
* 3) Modelo LOGIT
*--------------------------------------------------------------------*
// 3.1) DISEÑO MUESTRAL
svyset upm [pweight=fac_per], strata(est_dis)

// 3.2) MODELOS LOGIT AJUSTADOS (svy)
svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_R

svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_V

svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_E

// 3.3) EFECTOS MARGINALES / PROBABILIDADES (svy)
est restore M_E
margins sexo, predict(pr)
margins, dydx(sexo)
margins sexo#p4_4, predict(pr)
margins tloc, predict(pr)

// 3.4) INTERACCIONES (E como ejemplo)
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
estimates store M_E_cony
svy: logit pobreza_E i.sexo##i.tloc  i.edad_v i.niv i.p4_4 i.p4_5
estimates store M_E_loc

// 3.5) Ajuste por cada modelo derivado de que lroc es para stata 16.
*** Estimamos los modelos de manera individual con su estat gof:

svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 

svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 

svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 
/* Para el modelo de Pobreza_R se obtiene un  P-value de 0.8542 por lo que el modelo está bien específicado. */
/* Para el modelo de Pobreza_V se obtiene un P.Value de 0.6859 po lo que el modelo esta bien especificado */
/* Para el modelo de Pobreza_E se obtiene un P.Value de 0.9308 por lo que el modelo esta bien especificado */

/* Modelos alternativos */
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
estat gof, group(10) 
/* Se obtiene un  P-value de 0.8164 por lo que el modelo está bien específicado. */

svy: logit pobreza_E i.sexo##i.tloc  i.edad_v i.niv i.p4_4 i.p4_5
estat gof, group(10) 
/* Se obtiene un  P-value de 0.8980 por lo que el modelo está bien específicado. */


// (Opcional) si está instalado spost13, se puede usar:
// fitstat

// ----------------------------------------------------------
// Notas:
// - pobreza_R: 1.5× mediana semanal de horas trabajadas totales
// - pobreza_V: menos de 81 horas semanales de tiempo disponible
// - pobreza_E: 2× mediana semanal de horas trabajadas totales
// - Variables de control: sexo, edad (categorías), nivel educativo,
//   estado conyugal, hijos, tamaño de localidad.
// ----------------------------------------------------------

// ----------------------------------------------------------
// EXPORTACIÓN AUTOMÁTICA DE TABLAS Y GRÁFICAS
// Requisitos: outreg2 (SSC) o estout (esttab) y marginsplot
// Crea carpeta /output y guarda tablas (.doc/.csv) y gráficas (.png)
// ----------------------------------------------------------

capture noisily which outreg2
if _rc {
    di as text "Instalando outreg2 desde SSC..."
    ssc install outreg2, replace
}
capture noisily which esttab
if _rc {
    di as text "Instalando estout (esttab) desde SSC..."
    ssc install estout, replace
}
capture noisily which parmest
if _rc {
    di as text "Instalando parmest desde SSC..."
    ssc install parmest, replace
}
capture noisily which somersd
if _rc {
	di as text "Instalando somersd desde SSC..."
	ssc install somersd, replace
}
 capture noisily which lroc
if _rc {
	di as text "Instalando lroc desde SSC..."
	ssc install lroc, replace
}

// 1) Carpeta de salida
cap mkdir "output"

// 2) Reestimar y almacenar modelos (si no se han almacenado)
capture confirm estimate M_R
if _rc { 
    svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_R 
}

capture confirm estimate M_V
if _rc { 
    svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_V 
}

capture confirm estimate M_E
if _rc { 
    svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_E 
}
* Nuevos modelos con interacciones
capture confirm estimate M_E_cony
if _rc { 
    svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
    estimates store M_E_cony 
}

capture confirm estimate M_E_loc
if _rc { 
    svy: logit pobreza_E i.sexo##i.tloc i.edad_v i.niv i.p4_4 i.p4_5
    estimates store M_E_loc 
}


// 3) Tablas con outreg2 (OR, IC95%, p-val)
outreg2 [M_R M_V M_E] using "output/resultados_logit.doc", ///
    replace ctitle("Modelo R" "Modelo V" "Modelo E") eform dec(2) ///
    alpha(0.1, 0.05, 0.01) addstat("Pseudo-R2", e(r2_p)) ///
    title("Resultados Logit (Odds Ratios)") label
	
outreg2 [M_R M_V M_E] using "output/resultados_logit.doc", ///
    replace ctitle("Modelo R" "Modelo V" "Modelo E") eform dec(2) ///
    alpha(0.1, 0.05, 0.01) title("Resultados Logit (Odds Ratios)") label


// 3b) Alternativa con esttab (si se prefiere .csv)
esttab M_R M_V M_E using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes // Sólo para Stata 16
	
esttab M_R M_V M_E using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes

esttab M_R M_V M_E using "output/resultados_logit_pvalues.csv", replace ///
    eform wide b(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, p-valores)") nonotes
/* Para resultados completos */
esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes // Sólo para Stata 16
	
esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit_completos.csv", replace ///
    eform wide b(2) ci(2) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes

esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit_pvalues_completos.csv", replace ///
    eform wide b(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, p-valores)") nonotes
	
// 4) Indicadores de ajuste: AUC y matriz de clasificación por modelo
// Se exportan como PNG (gráficas) y TXT (resumen)
tempname fh
file open `fh' using "output/ajuste_resumen.txt", text write replace

// Modelo R
est restore M_R
lroc
graph export "output/roc_R.png", replace width(2000)
quietly estat classification
return list
file write `fh' "=== Modelo R ===" _n
file write `fh' "AUC (ver roc_R.png). Ver detalles en resultados de Stata." _n
// Modelo V
est restore M_V
lroc
graph export "output/roc_V.png", replace width(2000)
quietly estat classification
file write `fh' "=== Modelo V ===" _n
file write `fh' "AUC (ver roc_V.png). Ver detalles en resultados de Stata." _n
// Modelo E
est restore M_E
lroc
graph export "output/roc_E.png", replace width(2000)
quietly estat classification
file write `fh' "=== Modelo E ===" _n
file write `fh' "AUC (ver roc_E.png). Ver detalles en resultados de Stata." _n

file close `fh'

// 4.1) Otra alternativa si lo anterior no corre: 

// Modelo R
est restore M_R
predict p_R
roctab pobreza_R p_R [pweight=peso], graph
graph export "output/roc_R.png", replace width(2000)
local auc_R = r(area)
di "AUC Modelo R: `auc_R'"
drop p_R

// Modelo V  
est restore M_V
predict p_V
roctab pobreza_V p_V [pweight=peso], graph
graph export "output/roc_V.png", replace width(2000)
local auc_V = r(area)
di "AUC Modelo V: `auc_V'"
drop p_V

// Modelo E
est restore M_E
predict p_E
roctab pobreza_E p_E [pweight=peso], graph
graph export "output/roc_E.png", replace width(2000)
local auc_E = r(area)
di "AUC Modelo E: `auc_E'"
drop p_E

**** Sin pweights. Para Stata 15

// Modelo R
est restore M_R
predict phat_R if e(sample), pr
roctab pobreza_R phat_R, graph
graph export "output/roc_R.png", replace width(2000)

// Modelo V
est restore M_V
predict phat_V if e(sample), pr
roctab pobreza_V phat_V, graph
graph export "output/roc_V.png", replace width(2000)

// Modelo E
est restore M_E
predict phat_E if e(sample), pr
roctab pobreza_E phat_E, graph
graph export "output/roc_E.png", replace width(2000)

// 5) Probabilidades predichas y márgenes (sexo, conyugalidad, localidad)
est restore M_E
margins sexo, predict(pr)
marginsplot, recastci(rarea) title("Figura 1: Probabilidad predicha por sexo (E)") ///
    name(g_sexo_E, replace)
graph export "output/prob_sexo_E.png", replace width(2000)

margins sexo#p4_4, predict(pr)
marginsplot, recastci(rarea) title("Figura 2: Probabilidad por sexo x conyugalidad (E)") ///
    name(g_sexo_cony_E, replace)
graph export "output/prob_sexo_cony_E.png", replace width(2000)

margins tloc, predict(pr)
marginsplot, recastci(rarea) title("Figura 3: Probabilidad por tamaño de localidad (E)") ///
    name(g_loc_E, replace)
graph export "output/prob_localidad_E.png", replace width(2000)

// 6) Exportar márgenes a CSV para reproducibilidad
// Sexo
// Exportar márgenes a CSV (parmest)
margins, dydx(sexo) post
parmest, saving("output/margins_dydx_sexo_E.dta", replace)
preserve
use "output/margins_dydx_sexo_E.dta", clear
export delimited using "output/margins_dydx_sexo_E.csv", replace
restore

est restore M_E
margins sexo, post
parmest, saving("output/margins_sexo_levels_E.dta", replace)
preserve
use "output/margins_sexo_levels_E.dta", clear
export delimited using "output/margins_sexo_levels_E.csv", replace
restore

di as result "Exportación completa. Revise la carpeta /output."

// Otra alternativa por si no corre: Efectos marginales para sexo (dydx)
margins, dydx(sexo) post
parmest, saving("output/margins_dydx_sexo_E.dta", replace)
preserve
use "output/margins_dydx_sexo_E.dta", clear
export delimited using "output/margins_dydx_sexo_E.csv", replace
restore

// Margins por niveles de sexo
est restore M_E
margins sexo, post
parmest, saving("output/margins_sexo_levels_E.dta", replace)
preserve
use "output/margins_sexo_levels_E.dta", clear
export delimited using "output/margins_sexo_levels_E.csv", replace
restore

di as result "Exportación completa. Revise la carpeta /output."


* === 1. Re-estimar modelo ===
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc

* === 2. Márgenes sexo × estado civil ===
margins sexo#p4_4, predict(pr)
margins, post
export delimited using "output/margins_sexo_p4_4.csv", replace

* === 3. Re-estimar modelo otra vez ===
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc

* === 4. Contrastes de estado civil dentro de sexo ===
margins r.p4_4, over(sexo)
margins, post
export delimited using "output/contrastes_sexo_p4_4.csv", replace

************************************************************************
* === 1. Re-estimar modelo Pobreza_E, Sexo y Localidad controlados=== *
svy: logit pobreza_E i.sexo##i.p4_4 i.sexo##i.tloc i.edad_v i.niv i.p4_5
est store M_E2

* === 2. Probabilidades predichas: Sexo x estado conyugal. ===*
margins sexo#p4_4, predict(pr)
marginsplot, xdimension(p4_4) by(sexo) ///
    title("Probabilidad de pobreza de tiempo extrema por sexo y estado conyugal") ///
    ytitle("Pr(pobreza_E)") xtitle("Estado conyugal")
graph export "output/prob_sexo_p4_4.png", replace width(2000)

margins sexo#p4_4
marginsplot, by(sexo) ///
    title("Probabilidad de Pobreza por Estado Conyugal") ///
    xtitle("Estado Conyugal") ///
    ytitle("Probabilidad de Pobreza") ///
    xlabel(1 "Soltero" 2 "Unión libre" 3 "Casado" 4 "Separado" 5 "Viudo" 6 "Divorciado", angle(45)) ///
    graphregion(color(white))


* === 3. Probabilidades predichas para sexo x tamaño localidad ===*
margins sexo#tloc, predict(pr)
marginsplot, xdimension(tloc) by(sexo) ///
    title("Probabilidad de pobreza de tiempo extrema por sexo y tipo de localidad") ///
    ytitle("Pr(pobreza_E)") xtitle("Tipo de localidad")
graph export "output/prob_sexo_tloc.png", replace width(2000)


* === 4. Contrastes de diferencias ====*
margins r.p4_4, over(sexo)
margins r.tloc, over(sexo)

margins r.tloc, over(sexo) saving("output/margins_tloc_sexo.dta", replace)
use "output/margins_tloc_sexo.dta", clear
export delimited using "output/margins_tloc_sexo.csv", replace


* ===========================
* Diagnóstico rápido pobreza de tiempo (E)
* ===========================

* 1. Revisar categorías base (por default la más baja, pero lo mostramos)
tabulate sexo
tabulate p4_4
tabulate tloc

* Opcional: definir explícitamente bases de referencia
fvset base 1 sexo   // 1 = hombres
fvset base 1 p4_4   // 1 = soltero
fvset base 1 tloc   // 1 = localidad pequeña

* 2. Distribución pobreza extrema por variables clave
tabulate pobreza_E sexo, row col
tabulate pobreza_E p4_4, row col
tabulate pobreza_E tloc, row col

* 3. Revisar combinaciones sexo × conyugalidad
tabulate sexo p4_4 if e(sample), missing

* 4. Revisar combinaciones sexo × localidad
tabulate sexo tloc if e(sample), missing

* 5. Revisar combinaciones con el desenlace (pobreza extrema)
table sexo p4_4 pobreza_E
table sexo tloc pobreza_E

/* Podemos concuir que no hay perfect prediction, sin embargo, hay variables que muestran
cierto nivel de desbalance */


/****************************************************************************
  MODELO LOGIT - ENUT 2024
  Elaborado por: Luis Felipe Sánchez Ascencio, David Orlando Ramírez Naranjo y Nayeli Pérez
****************************************************************************/

// 0. DEFINIMOS DIRECTORIO Y ABRIMOS BASE DE DATOS
cd "C:\Users\usuario\Documents\Maestria\Economía_Política\Trabajo_Final\ENUT_2024_ARTICULO\enut_2024_bd_csv\enut_2024
use "TMODULO_2024.dta", clear


/****************************************************************************
  Actividad 1: Diseño Muestral y filtro para la CDMX
****************************************************************************/
keep if cve_ent == 09
describe upm
tabulate upm, missing
rename upm_dis upm
svyset upm [pweight=fac_per], strata(est_dis)

/****************************************************************************
TRABAJO REMUNERADO BÁSICO (ENUT 2024)
     Incluye: Modalidad Presencial (P5_8_1_X) y Virtual (P5_8_2_X)
****************************************************************************/

// 1. LIMPIEZA Y CONVERSIÓN DE HORAS Y MINUTOS
// Trabajo Presencial (P5_8_1_1 a P5_8_1_4) y Virtual (P5_8_2_1 a P5_8_2_4)
foreach var in p5_8_1_1 p5_8_1_2 p5_8_1_3 p5_8_1_4 ///
              p5_8_2_1 p5_8_2_2 p5_8_2_3 p5_8_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == "" // Limpia códigos no numéricos
        destring `var', replace
    }
    replace `var' = 0 if missing(`var') // Convierte missing a 0
}

// 2. CÁLCULO DEL TIEMPO PRESENCIAL

// Trabajo Presencial (Lunes a Viernes)
gen horas_trabajo_presencial_lv = p5_8_1_1 + (p5_8_1_2 / 60)
// Trabajo Presencial (Sábado y Domingo)
gen horas_trabajo_presencial_sd = p5_8_1_3 + (p5_8_1_4 / 60)

// Total Presencial Semanal
gen horas_trabajo_presencial_tot = horas_trabajo_presencial_lv + horas_trabajo_presencial_sd


// 3. CÁLCULO DEL TIEMPO VIRTUAL

// Trabajo Virtual (Lunes a Viernes)
gen horas_trabajo_virtual_lv = p5_8_2_1 + (p5_8_2_2 / 60)
// Trabajo Virtual (Sábado y Domingo)
gen horas_trabajo_virtual_sd = p5_8_2_3 + (p5_8_2_4 / 60)

// Total Virtual Semanal
gen horas_trabajo_virtual_tot = horas_trabajo_virtual_lv + horas_trabajo_virtual_sd


// 4. SUMATORIA FINAL DEL TRABAJO EFECTIVO (BÁSICO)

// Suma de ambas modalidades de trabajo (Presencial + Virtual)
gen horas_tot_trabajo = horas_trabajo_presencial_tot + horas_trabajo_virtual_tot


// Comprobación: 
svy: mean horas_tot_trabajo if p5_1 == 1 
/* El resultado es de 45.03 horas, el de INEGI es de 44.4 horas, sobreestimamos ligeramente. */

/****************************************************************************
TRASLADOS AL TRABAJO (ENUT 2024 - p5_9_X)
****************************************************************************/

// 1. LIMPIEZA Y CONVERSIÓN DE HORAS Y MINUTOS
// Traslados (p5_9_1 a p5_9_4)
foreach var in p5_9_1 p5_9_2 p5_9_3 p5_9_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == ""
        destring `var', replace
    }
    replace `var' = 0 if missing(`var')
}

// 2. CÁLCULO DEL TIEMPO DE TRASLADOS
gen horas_traslado_lv = p5_9_1 + (p5_9_2 / 60)
gen horas_traslado_sd = p5_9_3 + (p5_9_4 / 60)

// Total Traslados Semanal
gen horas_tot_traslados = horas_traslado_lv + horas_traslado_sd

// Comprobación: 
svy: mean horas_tot_traslados
svy: mean horas_tot_traslados if  p5_1 == 1

/* El resultado es de 7.41 hrs, el de INEGI es de 7.6 faltan 0.2 hrs */

/****************************************************************************
BÚSQUEDA DE TRABAJO (ENUT 2024 - p5_12_X)
****************************************************************************/

// 1. LIMPIEZA Y CONVERSIÓN DE HORAS Y MINUTOS
// Actividad Secundaria (p5_12_1 a p5_12_4)
foreach var in p5_12_1 p5_12_2 p5_12_3 p5_12_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "0" if `var' == "b" | `var' == "" // Limpia códigos no numéricos
        destring `var', replace
    }
    replace `var' = 0 if missing(`var') // Convierte missing a 0
}

// 2. CÁLCULO DEL TIEMPO

// Actividad Secundaria (Lunes a Viernes)
gen horas_secundaria_lv = p5_12_1 + (p5_12_2 / 60)
// Actividad Secundaria (Sábado y Domingo)
gen horas_secundaria_sd = p5_12_3 + (p5_12_4 / 60)

// Total Actividad Secundaria Semanal
gen horas_tot_secundaria = horas_secundaria_lv + horas_secundaria_sd

// Comprobación y construción de búsqueda de trabajo
svy: mean horas_tot_secundaria if p5_11 == 1 
/* El resultado es de 8.28  muy cerca del 8.40  propuesto por INEGI */
gen horas_bus_tra = horas_tot_secundaria if p5_11 == 1

/****************************************************************************
TRABAJO NO REMUNERADO DE PRODUCCIÓN DE AUTOCONSUMO
****************************************************************************/
// Cuidado y cría de animales de corral


// 1. Limpieza de variables específicas (Aunque se hace globalmente, se incluyen para contexto)
foreach var in p6_3a_1_1 p6_3a_1_2 p6_3a_1_3 p6_3a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_animales_lv = 0
gen horas_animales_sd = 0

capture confirm variable p6_3a_1_1 p6_3a_1_2 p6_3a_1_3 p6_3a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_animales_lv = p6_3a_1_1 + (p6_3a_1_2 / 60) if !missing(p6_3a_1_1, p6_3a_1_2)
    // Sábado y Domingo
    replace horas_animales_sd = p6_3a_1_3 + (p6_3a_1_4 / 60) if !missing(p6_3a_1_3, p6_3a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_animales_tot = horas_animales_lv + horas_animales_sd


**************************
// Recolección de leña
**************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_2_1 p6_3a_2_2 p6_3a_2_3 p6_3a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_lena_lv = 0
gen horas_lena_sd = 0

capture confirm variable p6_3a_2_1 p6_3a_2_2 p6_3a_2_3 p6_3a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_lena_lv = p6_3a_2_1 + (p6_3a_2_2 / 60) if !missing(p6_3a_2_1, p6_3a_2_2)
    // Sábado y Domingo
    replace horas_lena_sd = p6_3a_2_3 + (p6_3a_2_4 / 60) if !missing(p6_3a_2_3, p6_3a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_lena_tot = horas_lena_lv + horas_lena_sd


************************
// Recolección, pesca o caza
************************
// 1. Limpieza de variables específicas (PASO CRUCIAL FALTANTE)
foreach var in p6_3a_3_1 p6_3a_3_2 p6_3a_3_3 p6_3a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace // Convierte de STRING a NUMÉRICO
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
// Inicializamos con gen, el paso siguiente es replace
gen horas_silvestre_lv = 0
gen horas_silvestre_sd = 0

capture confirm variable p6_3a_3_1 p6_3a_3_2 p6_3a_3_3 p6_3a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_silvestre_lv = p6_3a_3_1 + (p6_3a_3_2 / 60)
    
    // Sábado y Domingo
    replace horas_silvestre_sd = p6_3a_3_3 + (p6_3a_3_4 / 60)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_silvestre_tot = horas_silvestre_lv + horas_silvestre_sd



*********************************
// Sembrar o plantar
*********************************


// 1. Limpieza de variables específicas
foreach var in p6_3a_4_1 p6_3a_4_2 p6_3a_4_3 p6_3a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_siembra_lv = 0
gen horas_siembra_sd = 0

capture confirm variable p6_3a_4_1 p6_3a_4_2 p6_3a_4_3 p6_3a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_siembra_lv = p6_3a_4_1 + (p6_3a_4_2 / 60) if !missing(p6_3a_4_1, p6_3a_4_2)
    // Sábado y Domingo
    replace horas_siembra_sd = p6_3a_4_3 + (p6_3a_4_4 / 60) if !missing(p6_3a_4_3, p6_3a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_siembra_tot = horas_siembra_lv + horas_siembra_sd

******************************
// Acarrear o almacenar agua
******************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_5_1 p6_3a_5_2 p6_3a_5_3 p6_3a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_agua_lv = 0
gen horas_agua_sd = 0

capture confirm variable p6_3a_5_1 p6_3a_5_2 p6_3a_5_3 p6_3a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_agua_lv = p6_3a_5_1 + (p6_3a_5_2 / 60) if !missing(p6_3a_5_1, p6_3a_5_2)
    // Sábado y Domingo
    replace horas_agua_sd = p6_3a_5_3 + (p6_3a_5_4 / 60) if !missing(p6_3a_5_3, p6_3a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_agua_tot = horas_agua_lv + horas_agua_sd

********************************
/// Tejer ropa, textiles
*******************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_6_1 p6_3a_6_2 p6_3a_6_3 p6_3a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_textiles_lv = 0
gen horas_textiles_sd = 0

capture confirm variable p6_3a_6_1 p6_3a_6_2 p6_3a_6_3 p6_3a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_textiles_lv = p6_3a_6_1 + (p6_3a_6_2 / 60) if !missing(p6_3a_6_1, p6_3a_6_2)
    // Sábado y Domingo
    replace horas_textiles_sd = p6_3a_6_3 + (p6_3a_6_4 / 60) if !missing(p6_3a_6_3, p6_3a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_textiles_tot = horas_textiles_lv + horas_textiles_sd

******************************
// Elaborar alimentos como conservar, mermeladas
*******************************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_7_1 p6_3a_7_2 p6_3a_7_3 p6_3a_7_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_conservas_lv = 0
gen horas_conservas_sd = 0

capture confirm variable p6_3a_7_1 p6_3a_7_2 p6_3a_7_3 p6_3a_7_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_conservas_lv = p6_3a_7_1 + (p6_3a_7_2 / 60) if !missing(p6_3a_7_1, p6_3a_7_2)
    // Sábado y Domingo
    replace horas_conservas_sd = p6_3a_7_3 + (p6_3a_7_4 / 60) if !missing(p6_3a_7_3, p6_3a_7_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_conservas_tot = horas_conservas_lv + horas_conservas_sd

********************************
// Hacer muebles, utensilios, etc.
********************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_8_1 p6_3a_8_2 p6_3a_8_3 p6_3a_8_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_muebles_lv = 0
gen horas_muebles_sd = 0

capture confirm variable p6_3a_8_1 p6_3a_8_2 p6_3a_8_3 p6_3a_8_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_muebles_lv = p6_3a_8_1 + (p6_3a_8_2 / 60) if !missing(p6_3a_8_1, p6_3a_8_2)
    // Sábado y Domingo
    replace horas_muebles_sd = p6_3a_8_3 + (p6_3a_8_4 / 60) if !missing(p6_3a_8_3, p6_3a_8_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_muebles_tot = horas_muebles_lv + horas_muebles_sd

*********************************
// Construir, remodelar o ampliar la vivienda.
*************************************

// 1. Limpieza de variables específicas
foreach var in p6_3a_9_1 p6_3a_9_2 p6_3a_9_3 p6_3a_9_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_remodelar_lv = 0
gen horas_remodelar_sd = 0

capture confirm variable p6_3a_9_1 p6_3a_9_2 p6_3a_9_3 p6_3a_9_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_remodelar_lv = p6_3a_9_1 + (p6_3a_9_2 / 60) if !missing(p6_3a_9_1, p6_3a_9_2)
    // Sábado y Domingo
    replace horas_remodelar_sd = p6_3a_9_3 + (p6_3a_9_4 / 60) if !missing(p6_3a_9_3, p6_3a_9_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_remodelar_tot = horas_remodelar_lv + horas_remodelar_sd

********************************************************
// SUMA TRABAJO NO REMUNERADO DE AUTOCONSUMO
********************************************************

gen horas_trabajo_autocon = horas_animales_tot + horas_lena_tot  +  horas_silvestre_tot + horas_siembra_tot  + ///
												horas_agua_tot +  horas_textiles_tot + horas_conservas_tot + horas_muebles_tot + horas_remodelar_tot

												
svy: mean horas_trabajo_autocon if  p6_3_1 == 1 | p6_3_2 == 1 | p6_3_3 == 1 | p6_3_4 == 1 | p6_3_5 == 1| p6_3_6 == 1| p6_3_7 == 1 | p6_3_8 ==1 | p6_3_9 == 1
/* Nos da un resultado el mismo resultado que INEGI */

********************************************************
// SUMA ACTIVIDADES PARA EL MERCADO Y BIENES DE AUTOCONSUMO
********************************************************

gen actividades_mercado = horas_tot_trabajo + horas_tot_traslados + horas_tot_secundaria + horas_trabajo_autocon
svy:mean actividades_mercado if p5_1 == 1 | p5_11 == 1| p6_3_1 == 1 | p6_3_2 == 1 | p6_3_3 == 1 | p6_3_4 == 1 | p6_3_5 == 1| p6_3_6 == 1| p6_3_7 == 1 | p6_3_8 ==1 | p6_3_9 == 1 
/* Nos da un resultado de 48.57 muy cerca del 48.1 de INEGI */

**************************************************************************************************************
// BLOQUE DE TRABAJO DOMÉSTICO NO REMUNERADO PARA EL PROPIO HOGAR
**************************************************************************************************************

/****************************************************************************
  PREPARACIÓN DE ALIMENTOS
  1. Desgranar/Cocer/Moler Nixtamal o Hacer Tortillas (p6_4a_1_1 a p6_4a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_4a_1_1 p6_4a_1_2 p6_4a_1_3 p6_4a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_nixtamal_lv = 0
gen horas_nixtamal_sd = 0

capture confirm variable p6_4a_1_1 p6_4a_1_2 p6_4a_1_3 p6_4a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_nixtamal_lv = p6_4a_1_1 + (p6_4a_1_2 / 60) if !missing(p6_4a_1_1, p6_4a_1_2)
    // Sábado y Domingo
    replace horas_nixtamal_sd = p6_4a_1_3 + (p6_4a_1_4 / 60) if !missing(p6_4a_1_3, p6_4a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_nixtamal_tot = horas_nixtamal_lv + horas_nixtamal_sd

/****************************************************************************
  PREPARACIÓN DE ALIMENTOS
  2. Encender Fogon/Horno/Anafre de Leña (p6_4a_2_1 a p6_4a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_4a_2_1 p6_4a_2_2 p6_4a_2_3 p6_4a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_fogon_lv = 0
gen horas_fogon_sd = 0

capture confirm variable p6_4a_2_1 p6_4a_2_2 p6_4a_2_3 p6_4a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_fogon_lv = p6_4a_2_1 + (p6_4a_2_2 / 60) if !missing(p6_4a_2_1, p6_4a_2_2)
    // Sábado y Domingo
    replace horas_fogon_sd = p6_4a_2_3 + (p6_4a_2_4 / 60) if !missing(p6_4a_2_3, p6_4a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_fogon_tot = horas_fogon_lv + horas_fogon_sd

/****************************************************************************
  PREPARACIÓN DE ALIMENTOS
  3. Cocinar, Preparar, Calentar Alimentos o Bebidas (p6_4a_3_1 a p6_4a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_4a_3_1 p6_4a_3_2 p6_4a_3_3 p6_4a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cocinar_lv = 0
gen horas_cocinar_sd = 0

capture confirm variable p6_4a_3_1 p6_4a_3_2 p6_4a_3_3 p6_4a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cocinar_lv = p6_4a_3_1 + (p6_4a_3_2 / 60) if !missing(p6_4a_3_1, p6_4a_3_2)
    // Sábado y Domingo
    replace horas_cocinar_sd = p6_4a_3_3 + (p6_4a_3_4 / 60) if !missing(p6_4a_3_3, p6_4a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_cocinar_tot = horas_cocinar_lv + horas_cocinar_sd

/****************************************************************************
  PREPARACIÓN DE ALIMENTOS
  4. Servir Comida, Recoger y Lavar Trastes (p6_4a_4_1 a p6_4a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_4a_4_1 p6_4a_4_2 p6_4a_4_3 p6_4a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_trastes_lv = 0
gen horas_trastes_sd = 0

capture confirm variable p6_4a_4_1 p6_4a_4_2 p6_4a_4_3 p6_4a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_trastes_lv = p6_4a_4_1 + (p6_4a_4_2 / 60) if !missing(p6_4a_4_1, p6_4a_4_2)
    // Sábado y Domingo
    replace horas_trastes_sd = p6_4a_4_3 + (p6_4a_4_4 / 60) if !missing(p6_4a_4_3, p6_4a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_trastes_tot = horas_trastes_lv + horas_trastes_sd

/****************************************************************************
  PREPARACIÓN DE ALIMENTOS
  5. Llevar Comida a Integrante del Hogar (p6_4a_5_1 a p6_4a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_4a_5_1 p6_4a_5_2 p6_4a_5_3 p6_4a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_llevar_comida_lv = 0
gen horas_llevar_comida_sd = 0

capture confirm variable p6_4a_5_1 p6_4a_5_2 p6_4a_5_3 p6_4a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_llevar_comida_lv = p6_4a_5_1 + (p6_4a_5_2 / 60) if !missing(p6_4a_5_1, p6_4a_5_2)
    // Sábado y Domingo
    replace horas_llevar_comida_sd = p6_4a_5_3 + (p6_4a_5_4 / 60) if !missing(p6_4a_5_3, p6_4a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_llevar_comida_tot = horas_llevar_comida_lv + horas_llevar_comida_sd


/*****************************************************************
COMPONENTE FINAL: PREPARACIÓN Y SERVICIOS DE ALIMENTOS
*****************************************************************/

gen horas_totales_prep_ali = horas_nixtamal_tot + horas_fogon_tot + horas_cocinar_tot + horas_trastes_tot + horas_llevar_comida_tot
svy:mean horas_totales_prep_ali if p6_4_1 == 1 | p6_4_2 == 1 | p6_4_3 == 1 | p6_4_4 == 1 | p6_4_5 == 1
/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  LIMPIEZA DE LA VIVIENDA
  1. Barrer Banqueta, Cochera o Patio (p6_5a_1_1 a p6_5a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_5a_1_1 p6_5a_1_2 p6_5a_1_3 p6_5a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_barrer_lv = 0
gen horas_barrer_sd = 0

capture confirm variable p6_5a_1_1 p6_5a_1_2 p6_5a_1_3 p6_5a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_barrer_lv = p6_5a_1_1 + (p6_5a_1_2 / 60) if !missing(p6_5a_1_1, p6_5a_1_2)
    // Sábado y Domingo
    replace horas_barrer_sd = p6_5a_1_3 + (p6_5a_1_4 / 60) if !missing(p6_5a_1_3, p6_5a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_barrer_tot = horas_barrer_lv + horas_barrer_sd

/****************************************************************************
  LIMPIEZA DE LA VIVIENDA
  2. Limpiar o Recoger el Interior de la Vivienda (p6_5a_2_1 a p6_5a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_5a_2_1 p6_5a_2_2 p6_5a_2_3 p6_5a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_limpieza_int_lv = 0
gen horas_limpieza_int_sd = 0

capture confirm variable p6_5a_2_1 p6_5a_2_2 p6_5a_2_3 p6_5a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_limpieza_int_lv = p6_5a_2_1 + (p6_5a_2_2 / 60) if !missing(p6_5a_2_1, p6_5a_2_2)
    // Sábado y Domingo
    replace horas_limpieza_int_sd = p6_5a_2_3 + (p6_5a_2_4 / 60) if !missing(p6_5a_2_3, p6_5a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_limpieza_int_tot = horas_limpieza_int_lv + horas_limpieza_int_sd

/****************************************************************************
  LIMPIEZA DE LA VIVIENDA
  3. Recoger, Separar, Tirar o Quemar Basura (p6_5a_3_1 a p6_5a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_5a_3_1 p6_5a_3_2 p6_5a_3_3 p6_5a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_basura_lv = 0
gen horas_basura_sd = 0

capture confirm variable p6_5a_3_1 p6_5a_3_2 p6_5a_3_3 p6_5a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_basura_lv = p6_5a_3_1 + (p6_5a_3_2 / 60) if !missing(p6_5a_3_1, p6_5a_3_2)
    // Sábado y Domingo
    replace horas_basura_sd = p6_5a_3_3 + (p6_5a_3_4 / 60) if !missing(p6_5a_3_3, p6_5a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_basura_tot = horas_basura_lv + horas_basura_sd

/****************************************************************************
   LIMPIEZA DE LA VIVIENDA
  4. Cuidar o Regar Macetas (p6_5a_4_1 a p6_5a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_5a_4_1 p6_5a_4_2 p6_5a_4_3 p6_5a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_macetas_lv = 0
gen horas_macetas_sd = 0

capture confirm variable p6_5a_4_1 p6_5a_4_2 p6_5a_4_3 p6_5a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_macetas_lv = p6_5a_4_1 + (p6_5a_4_2 / 60) if !missing(p6_5a_4_1, p6_5a_4_2)
    // Sábado y Domingo
    replace horas_macetas_sd = p6_5a_4_3 + (p6_5a_4_4 / 60) if !missing(p6_5a_4_3, p6_5a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_macetas_tot = horas_macetas_lv + horas_macetas_sd

/****************************************************************************
  LIMPIEZA DE LA VIVIENDA
  5. Limpiar, Alimentar y Cuidar Mascotas (p6_5a_5_1 a p6_5a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_5a_5_1 p6_5a_5_2 p6_5a_5_3 p6_5a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_mascotas_lv = 0
gen horas_mascotas_sd = 0

capture confirm variable p6_5a_5_1 p6_5a_5_2 p6_5a_5_3 p6_5a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_mascotas_lv = p6_5a_5_1 + (p6_5a_5_2 / 60) if !missing(p6_5a_5_1, p6_5a_5_2)
    // Sábado y Domingo
    replace horas_mascotas_sd = p6_5a_5_3 + (p6_5a_5_4 / 60) if !missing(p6_5a_5_3, p6_5a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_mascotas_tot = horas_mascotas_lv + horas_mascotas_sd

/*****************************************************************
COMPONENTE FINAL: LIMPIEZA DE LA VIVIENDA
*****************************************************************/

gen horas_tot_lim_viv = horas_barrer_tot + horas_limpieza_int_tot + horas_basura_tot + horas_macetas_tot + horas_mascotas_tot
svy:mean horas_tot_lim_viv if p6_5_1 == 1 | p6_5_2 == 1 | p6_5_3 == 1 | p6_5_4 == 1 | p6_5_5 == 1

/* Nos da el mismo resultdo que INEGI */

/****************************************************************************
  LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
  1. Lavar, Tender o Secar Ropa (p6_6a_1_1 a p6_6a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_6a_1_1 p6_6a_1_2 p6_6a_1_3 p6_6a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_lavar_ropa_lv = 0
gen horas_lavar_ropa_sd = 0

capture confirm variable p6_6a_1_1 p6_6a_1_2 p6_6a_1_3 p6_6a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_lavar_ropa_lv = p6_6a_1_1 + (p6_6a_1_2 / 60) if !missing(p6_6a_1_1, p6_6a_1_2)
    // Sábado y Domingo
    replace horas_lavar_ropa_sd = p6_6a_1_3 + (p6_6a_1_4 / 60) if !missing(p6_6a_1_3, p6_6a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_lavar_ropa_tot = horas_lavar_ropa_lv + horas_lavar_ropa_sd

/****************************************************************************
   LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
  2. Planchar Ropa (p6_6a_2_1 a p6_6a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_6a_2_1 p6_6a_2_2 p6_6a_2_3 p6_6a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_planchar_lv = 0
gen horas_planchar_sd = 0

capture confirm variable p6_6a_2_1 p6_6a_2_2 p6_6a_2_3 p6_6a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_planchar_lv = p6_6a_2_1 + (p6_6a_2_2 / 60) if !missing(p6_6a_2_1, p6_6a_2_2)
    // Sábado y Domingo
    replace horas_planchar_sd = p6_6a_2_3 + (p6_6a_2_4 / 60) if !missing(p6_6a_2_3, p6_6a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_planchar_tot = horas_planchar_lv + horas_planchar_sd

/****************************************************************************
  LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
  3. Separar, Doblar o Acomodar Ropa (p6_6a_3_1 a p6_6a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_6a_3_1 p6_6a_3_2 p6_6a_3_3 p6_6a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_acomodar_ropa_lv = 0
gen horas_acomodar_ropa_sd = 0

capture confirm variable p6_6a_3_1 p6_6a_3_2 p6_6a_3_3 p6_6a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_acomodar_ropa_lv = p6_6a_3_1 + (p6_6a_3_2 / 60) if !missing(p6_6a_3_1, p6_6a_3_2)
    // Sábado y Domingo
    replace horas_acomodar_ropa_sd = p6_6a_3_3 + (p6_6a_3_4 / 60) if !missing(p6_6a_3_3, p6_6a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_acomodar_ropa_tot = horas_acomodar_ropa_lv + horas_acomodar_ropa_sd

/****************************************************************************
  LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
  4. Arreglar o Remodelar Ropa, Manteles o Cortinas (p6_6a_4_1 a p6_6a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_6a_4_1 p6_6a_4_2 p6_6a_4_3 p6_6a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_arreglar_ropa_lv = 0
gen horas_arreglar_ropa_sd = 0

capture confirm variable p6_6a_4_1 p6_6a_4_2 p6_6a_4_3 p6_6a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_arreglar_ropa_lv = p6_6a_4_1 + (p6_6a_4_2 / 60) if !missing(p6_6a_4_1, p6_6a_4_2)
    // Sábado y Domingo
    replace horas_arreglar_ropa_sd = p6_6a_4_3 + (p6_6a_4_4 / 60) if !missing(p6_6a_4_3, p6_6a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_arreglar_ropa_tot = horas_arreglar_ropa_lv + horas_arreglar_ropa_sd

/****************************************************************************
  LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
  5. Limpiar, Bolear o Pintar Calzado (p6_6a_5_1 a p6_6a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_6a_5_1 p6_6a_5_2 p6_6a_5_3 p6_6a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_calzado_lv = 0
gen horas_calzado_sd = 0

capture confirm variable p6_6a_5_1 p6_6a_5_2 p6_6a_5_3 p6_6a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_calzado_lv = p6_6a_5_1 + (p6_6a_5_2 / 60) if !missing(p6_6a_5_1, p6_6a_5_2)
    // Sábado y Domingo
    replace horas_calzado_sd = p6_6a_5_3 + (p6_6a_5_4 / 60) if !missing(p6_6a_5_3, p6_6a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_calzado_tot = horas_calzado_lv + horas_calzado_sd

/*****************************************************************
COMPONENTE FINAL: LIMPIEZA Y CUIDADO DE ROPA Y CALZADO
*****************************************************************/

gen horas_tot_lim_ropcal =  horas_lavar_ropa_tot + horas_planchar_tot + horas_acomodar_ropa_tot + horas_arreglar_ropa_tot + horas_calzado_tot
svy:mean horas_tot_lim_ropcal if p6_6_1 == 1 | p6_6_2 == 1 | p6_6_3 == 1 | p6_6_4 == 1 | p6_6_5 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  MANTENIMIENTO, INSTALACIÓN Y REPARACIONES
  1. Reparar o Hacer Instalación Menor (p6_7a_1_1 a p6_7a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_7a_1_1 p6_7a_1_2 p6_7a_1_3 p6_7a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_rep_instal_lv = 0
gen horas_rep_instal_sd = 0

capture confirm variable p6_7a_1_1 p6_7a_1_2 p6_7a_1_3 p6_7a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_rep_instal_lv = p6_7a_1_1 + (p6_7a_1_2 / 60) if !missing(p6_7a_1_1, p6_7a_1_2)
    // Sábado y Domingo
    replace horas_rep_instal_sd = p6_7a_1_3 + (p6_7a_1_4 / 60) if !missing(p6_7a_1_3, p6_7a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_rep_instal_tot = horas_rep_instal_lv + horas_rep_instal_sd

/****************************************************************************
   MANTENIMIENTO, INSTALACIÓN Y REPARACIONES
  2. Reparar Muebles, Juguetes o Aparatos Domésticos (p6_7a_2_1 a p6_7a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_7a_2_1 p6_7a_2_2 p6_7a_2_3 p6_7a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_rep_muebles_lv = 0
gen horas_rep_muebles_sd = 0

capture confirm variable p6_7a_2_1 p6_7a_2_2 p6_7a_2_3 p6_7a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_rep_muebles_lv = p6_7a_2_1 + (p6_7a_2_2 / 60) if !missing(p6_7a_2_1, p6_7a_2_2)
    // Sábado y Domingo
    replace horas_rep_muebles_sd = p6_7a_2_3 + (p6_7a_2_4 / 60) if !missing(p6_7a_2_3, p6_7a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_rep_muebles_tot = horas_rep_muebles_lv + horas_rep_muebles_sd

/****************************************************************************
   MANTENIMIENTO, INSTALACIÓN Y REPARACIONES
  3. Lavar o Limpiar Medios de Transporte (p6_7a_3_1 a p6_7a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_7a_3_1 p6_7a_3_2 p6_7a_3_3 p6_7a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_limp_transporte_lv = 0
gen horas_limp_transporte_sd = 0

capture confirm variable p6_7a_3_1 p6_7a_3_2 p6_7a_3_3 p6_7a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_limp_transporte_lv = p6_7a_3_1 + (p6_7a_3_2 / 60) if !missing(p6_7a_3_1, p6_7a_3_2)
    // Sábado y Domingo
    replace horas_limp_transporte_sd = p6_7a_3_3 + (p6_7a_3_4 / 60) if !missing(p6_7a_3_3, p6_7a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_limp_transporte_tot = horas_limp_transporte_lv + horas_limp_transporte_sd

/****************************************************************************
   MANTENIMIENTO, INSTALACIÓN Y REPARACIONES
  4. Reparar o Dar Mantenimiento a Medios de Transporte (p6_7a_4_1 a p6_7a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_7a_4_1 p6_7a_4_2 p6_7a_4_3 p6_7a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_rep_transporte_lv = 0
gen horas_rep_transporte_sd = 0

capture confirm variable p6_7a_4_1 p6_7a_4_2 p6_7a_4_3 p6_7a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_rep_transporte_lv = p6_7a_4_1 + (p6_7a_4_2 / 60) if !missing(p6_7a_4_1, p6_7a_4_2)
    // Sábado y Domingo
    replace horas_rep_transporte_sd = p6_7a_4_3 + (p6_7a_4_4 / 60) if !missing(p6_7a_4_3, p6_7a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_rep_transporte_tot = horas_rep_transporte_lv + horas_rep_transporte_sd

/*****************************************************************
COMPONENTE FINAL: MANTENIMIENTO, INSTALACIÓN Y REPARACIONES MENORES
*****************************************************************/

gen horas_tot_mant_inst_rep = horas_rep_instal_tot + horas_rep_muebles_tot + horas_limp_transporte_tot + horas_rep_transporte_tot
svy:mean horas_tot_mant_inst_rep if p6_7_1 == 1 | p6_7_2 == 1 | p6_7_3 == 1 | p6_7_4 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  COMPRAS Y ADQUISICIÓN DE BIENES
  1. Buscar o Comprar Refacciones (p6_8a_1_1 a p6_8a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_8a_1_1 p6_8a_1_2 p6_8a_1_3 p6_8a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_refacciones_lv = 0
gen horas_refacciones_sd = 0

capture confirm variable p6_8a_1_1 p6_8a_1_2 p6_8a_1_3 p6_8a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_refacciones_lv = p6_8a_1_1 + (p6_8a_1_2 / 60) if !missing(p6_8a_1_1, p6_8a_1_2)
    // Sábado y Domingo
    replace horas_refacciones_sd = p6_8a_1_3 + (p6_8a_1_4 / 60) if !missing(p6_8a_1_3, p6_8a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_refacciones_tot = horas_refacciones_lv + horas_refacciones_sd



/****************************************************************************
  COMPRAS Y ADQUISICIÓN DE BIENES
  2. Buscar o Hacer Compras del Mandado, etc. (p6_8a_2_1 a p6_8a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_8a_2_1 p6_8a_2_2 p6_8a_2_3 p6_8a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_mandado_lv = 0
gen horas_mandado_sd = 0

capture confirm variable p6_8a_2_1 p6_8a_2_2 p6_8a_2_3 p6_8a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_mandado_lv = p6_8a_2_1 + (p6_8a_2_2 / 60) if !missing(p6_8a_2_1, p6_8a_2_2)
    // Sábado y Domingo
    replace horas_mandado_sd = p6_8a_2_3 + (p6_8a_2_4 / 60) if !missing(p6_8a_2_3, p6_8a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_mandado_tot = horas_mandado_lv + horas_mandado_sd

/****************************************************************************
  COMPRAS Y ADQUISICIÓN DE BIENES
  3. Buscar o Comprar Artículos o Bienes para el Hogar (p6_8a_3_1 a p6_8a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_8a_3_1 p6_8a_3_2 p6_8a_3_3 p6_8a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_articulos_hogar_lv = 0
gen horas_articulos_hogar_sd = 0

capture confirm variable p6_8a_3_1 p6_8a_3_2 p6_8a_3_3 p6_8a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_articulos_hogar_lv = p6_8a_3_1 + (p6_8a_3_2 / 60) if !missing(p6_8a_3_1, p6_8a_3_2)
    // Sábado y Domingo
    replace horas_articulos_hogar_sd = p6_8a_3_3 + (p6_8a_3_4 / 60) if !missing(p6_8a_3_3, p6_8a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_articulos_hogar_tot = horas_articulos_hogar_lv + horas_articulos_hogar_sd

/*****************************************************************
COMPONENTE FINAL: COMPRAS
*****************************************************************/

gen horas_tot_compras = horas_refacciones_tot + horas_mandado_tot + horas_articulos_hogar_tot
svy:mean horas_tot_compras if p6_8_1 == 1 | p6_8_2 == 1 | p6_8_3 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  PAGOS Y TRÁMITES
  1. Hacer Pagos o Trámites de Servicios (p6_9a_1_1 a p6_9a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_9a_1_1 p6_9a_1_2 p6_9a_1_3 p6_9a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_pagos_servicios_lv = 0
gen horas_pagos_servicios_sd = 0

capture confirm variable p6_9a_1_1 p6_9a_1_2 p6_9a_1_3 p6_9a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_pagos_servicios_lv = p6_9a_1_1 + (p6_9a_1_2 / 60) if !missing(p6_9a_1_1, p6_9a_1_2)
    // Sábado y Domingo
    replace horas_pagos_servicios_sd = p6_9a_1_3 + (p6_9a_1_4 / 60) if !missing(p6_9a_1_3, p6_9a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_pagos_servicios_tot = horas_pagos_servicios_lv + horas_pagos_servicios_sd

/****************************************************************************
  PAGOS Y TRÁMITES
  2. Planear u Organizar Gastos (p6_9a_2_1 a p6_9a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_9a_2_1 p6_9a_2_2 p6_9a_2_3 p6_9a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_organizar_gastos_lv = 0
gen horas_organizar_gastos_sd = 0

capture confirm variable p6_9a_2_1 p6_9a_2_2 p6_9a_2_3 p6_9a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_organizar_gastos_lv = p6_9a_2_1 + (p6_9a_2_2 / 60) if !missing(p6_9a_2_1, p6_9a_2_2)
    // Sábado y Domingo
    replace horas_organizar_gastos_sd = p6_9a_2_3 + (p6_9a_2_4 / 60) if !missing(p6_9a_2_3, p6_9a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_organizar_gastos_tot = horas_organizar_gastos_lv + horas_organizar_gastos_sd

/****************************************************************************
   PAGOS Y TRÁMITES
  3. Tramitar o Cobrar Algún Programa Social (p6_9a_3_1 a p6_9a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_9a_3_1 p6_9a_3_2 p6_9a_3_3 p6_9a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_prog_social_lv = 0
gen horas_prog_social_sd = 0

capture confirm variable p6_9a_3_1 p6_9a_3_2 p6_9a_3_3 p6_9a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_prog_social_lv = p6_9a_3_1 + (p6_9a_3_2 / 60) if !missing(p6_9a_3_1, p6_9a_3_2)
    // Sábado y Domingo
    replace horas_prog_social_sd = p6_9a_3_3 + (p6_9a_3_4 / 60) if !missing(p6_9a_3_3, p6_9a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_prog_social_tot = horas_prog_social_lv + horas_prog_social_sd

/*****************************************************************
COMPONENTE FINAL: PAGOS Y TRÁMITES
*****************************************************************/

gen horas_tot_pagos_tram = horas_pagos_servicios_tot + horas_organizar_gastos_tot + horas_prog_social_tot
svy:mean horas_tot_pagos_tram if p6_9_1 == 1 | p6_9_2 == 1 | p6_9_3 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  GESTIÓN Y ADMINISTRACIÓN
  1. Recoger o Llevar Ropa para Limpieza/Reparación (p6_10a_1_1 a p6_10a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_1_1 p6_10a_1_2 p6_10a_1_3 p6_10a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_ropa_ext_lv = 0
gen horas_ropa_ext_sd = 0

capture confirm variable p6_10a_1_1 p6_10a_1_2 p6_10a_1_3 p6_10a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_ropa_ext_lv = p6_10a_1_1 + (p6_10a_1_2 / 60) if !missing(p6_10a_1_1, p6_10a_1_2)
    // Sábado y Domingo
    replace horas_ropa_ext_sd = p6_10a_1_3 + (p6_10a_1_4 / 60) if !missing(p6_10a_1_3, p6_10a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_ropa_ext_tot = horas_ropa_ext_lv + horas_ropa_ext_sd

/****************************************************************************
  GESTIÓN Y ADMINISTRACIÓN
  2. Supervisar Construcción o Reparación de Vivienda (p6_10a_2_1 a p6_10a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_2_1 p6_10a_2_2 p6_10a_2_3 p6_10a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_superv_const_lv = 0
gen horas_superv_const_sd = 0

capture confirm variable p6_10a_2_1 p6_10a_2_2 p6_10a_2_3 p6_10a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_superv_const_lv = p6_10a_2_1 + (p6_10a_2_2 / 60) if !missing(p6_10a_2_1, p6_10a_2_2)
    // Sábado y Domingo
    replace horas_superv_const_sd = p6_10a_2_3 + (p6_10a_2_4 / 60) if !missing(p6_10a_2_3, p6_10a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_superv_const_tot = horas_superv_const_lv + horas_superv_const_sd

/****************************************************************************
   GESTIÓN Y ADMINISTRACIÓN
  3. Llevar o Supervisar Reparación de Muebles/Aparatos (p6_10a_3_1 a p6_10a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_3_1 p6_10a_3_2 p6_10a_3_3 p6_10a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_superv_rep_muebles_lv = 0
gen horas_superv_rep_muebles_sd = 0

capture confirm variable p6_10a_3_1 p6_10a_3_2 p6_10a_3_3 p6_10a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_superv_rep_muebles_lv = p6_10a_3_1 + (p6_10a_3_2 / 60) if !missing(p6_10a_3_1, p6_10a_3_2)
    // Sábado y Domingo
    replace horas_superv_rep_muebles_sd = p6_10a_3_3 + (p6_10a_3_4 / 60) if !missing(p6_10a_3_3, p6_10a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_superv_rep_muebles_tot = horas_superv_rep_muebles_lv + horas_superv_rep_muebles_sd

/****************************************************************************
 GESTIÓN Y ADMINISTRACIÓN
  4. Llevar a Lavar, Reparar o Mantenimiento a Transporte (p6_10a_4_1 a p6_10a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_4_1 p6_10a_4_2 p6_10a_4_3 p6_10a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_gest_transporte_lv = 0
gen horas_gest_transporte_sd = 0

capture confirm variable p6_10a_4_1 p6_10a_4_2 p6_10a_4_3 p6_10a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_gest_transporte_lv = p6_10a_4_1 + (p6_10a_4_2 / 60) if !missing(p6_10a_4_1, p6_10a_4_2)
    // Sábado y Domingo
    replace horas_gest_transporte_sd = p6_10a_4_3 + (p6_10a_4_4 / 60) if !missing(p6_10a_4_3, p6_10a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_gest_transporte_tot = horas_gest_transporte_lv + horas_gest_transporte_sd

/****************************************************************************
   GESTIÓN Y ADMINISTRACIÓN
  5. Cerrar Puertas, Ventanas o Poner Seguridad (p6_10a_5_1 a p6_10a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_5_1 p6_10a_5_2 p6_10a_5_3 p6_10a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_seguridad_lv = 0
gen horas_seguridad_sd = 0

capture confirm variable p6_10a_5_1 p6_10a_5_2 p6_10a_5_3 p6_10a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_seguridad_lv = p6_10a_5_1 + (p6_10a_5_2 / 60) if !missing(p6_10a_5_1, p6_10a_5_2)
    // Sábado y Domingo
    replace horas_seguridad_sd = p6_10a_5_3 + (p6_10a_5_4 / 60) if !missing(p6_10a_5_3, p6_10a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_seguridad_tot = horas_seguridad_lv + horas_seguridad_sd

/****************************************************************************
  Actividad 2.H: TDNR - GESTIÓN Y ADMINISTRACIÓN
  6. Esperar Servicios Públicos (p6_10a_6_1 a p6_10a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_6_1 p6_10a_6_2 p6_10a_6_3 p6_10a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_espera_servicios_lv = 0
gen horas_espera_servicios_sd = 0

capture confirm variable p6_10a_6_1 p6_10a_6_2 p6_10a_6_3 p6_10a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_espera_servicios_lv = p6_10a_6_1 + (p6_10a_6_2 / 60) if !missing(p6_10a_6_1, p6_10a_6_2)
    // Sábado y Domingo
    replace horas_espera_servicios_sd = p6_10a_6_3 + (p6_10a_6_4 / 60) if !missing(p6_10a_6_3, p6_10a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_espera_servicios_tot = horas_espera_servicios_lv + horas_espera_servicios_sd

/****************************************************************************
   GESTIÓN Y ADMINISTRACIÓN
  7. Organizar o Repartir Quehaceres del Hogar (p6_10a_7_1 a p6_10a_7_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_10a_7_1 p6_10a_7_2 p6_10a_7_3 p6_10a_7_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_organizacion_lv = 0
gen horas_organizacion_sd = 0

capture confirm variable p6_10a_7_1 p6_10a_7_2 p6_10a_7_3 p6_10a_7_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_organizacion_lv = p6_10a_7_1 + (p6_10a_7_2 / 60) if !missing(p6_10a_7_1, p6_10a_7_2)
    // Sábado y Domingo
    replace horas_organizacion_sd = p6_10a_7_3 + (p6_10a_7_4 / 60) if !missing(p6_10a_7_3, p6_10a_7_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_organizacion_tot = horas_organizacion_lv + horas_organizacion_sd

/*****************************************************************
COMPONENTE FINAL: GESTIÓN Y ADMINISTRACIÓN
*****************************************************************/

gen horas_tot_gest_adm = horas_ropa_ext_tot + horas_superv_const_tot + horas_superv_rep_muebles_tot + horas_gest_transporte_tot + horas_seguridad_tot + horas_espera_servicios_tot + horas_organizacion_tot
svy:mean horas_tot_gest_adm if p6_10_1 == 1 | p6_10_2 == 1 | p6_10_3 == 1 | p6_10_4 == 1 | p6_10_5 == 1| p6_10_6 == 1 | p6_10_7 == 1

/* Nos da el mismor resultado que INEGI */

/*****************************************************************************************
COMPONENTE : TRABAJO DOMÉSTICO NO REMUNERADO PARA EL PROPIO HOGAR
******************************************************************************************/

gen horas_tot_tdnr_prop_hog = horas_tot_gest_adm + horas_tot_pagos_tram + horas_tot_compras + horas_tot_mant_inst_rep +  horas_tot_lim_ropcal + horas_tot_lim_viv + horas_totales_prep_ali
svy:mean horas_tot_tdnr_prop_hog if p6_4_1 == 1 | p6_4_2 == 1 | p6_4_3 == 1 | p6_4_4 == 1 | p6_4_5 == 1 | p6_5_1 == 1 | p6_5_2 == 1 | p6_5_3 == 1 | p6_5_4 == 1 | p6_5_5 == 1 | ///
															p6_6_1 == 1 | p6_6_2 == 1 | p6_6_3 == 1 | p6_6_4 == 1 | p6_6_5 == 1 | p6_7_1 == 1 | p6_7_2 == 1 | p6_7_3 == 1 | p6_7_4 == 1 | ///
															p6_8_1 == 1 | p6_8_2 == 1 | p6_8_3 == 1 | p6_9_1 == 1 | p6_9_2 == 1 | p6_9_3 == 1 |  p6_10_1 == 1 | p6_10_2 == 1 | p6_10_3 == 1 | p6_10_4 == 1 | p6_10_5 == 1| p6_10_6 == 1 | p6_10_7 == 1

/* Nos da el mismo resultado que INEGI */

/***************************************************************************************************************
BLOQUE DE TRABAJO NO REMUNERADO DE CUIDADOS A INTEGRANTES DEL HOGAR
***************************************************************************************************************/

/****************************************************************************
   CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  1. Dar de comer o ayudar a hacerlo (p6_11a_01_1 a p6_11a_01_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_01_1 p6_11a_01_2 p6_11a_01_3 p6_11a_01_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_ayudar_comer_lv = 0
gen horas_ayudar_comer_sd = 0

capture confirm variable p6_11a_01_1 p6_11a_01_2 p6_11a_01_3 p6_11a_01_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_ayudar_comer_lv = p6_11a_01_1 + (p6_11a_01_2 / 60) if !missing(p6_11a_01_1, p6_11a_01_2)
    // Sábado y Domingo
    replace horas_ayudar_comer_sd = p6_11a_01_3 + (p6_11a_01_4 / 60) if !missing(p6_11a_01_3, p6_11a_01_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen ayudar_comer_tot = horas_ayudar_comer_lv + horas_ayudar_comer_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  2. Bañar, asear, vestir, arreglar o ayudar (p6_11a_02_1 a p6_11a_02_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_02_1 p6_11a_02_2 p6_11a_02_3 p6_11a_02_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_aseo_lv = 0
gen horas_aseo_sd = 0

capture confirm variable p6_11a_02_1 p6_11a_02_2 p6_11a_02_3 p6_11a_02_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_aseo_lv = p6_11a_02_1 + (p6_11a_02_2 / 60) if !missing(p6_11a_02_1, p6_11a_02_2)
    // Sábado y Domingo
    replace horas_aseo_sd = p6_11a_02_3 + (p6_11a_02_4 / 60) if !missing(p6_11a_02_3, p6_11a_02_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen aseo_tot = horas_aseo_lv + horas_aseo_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  3. Cargar, acostar o ayudarlo a hacer (p6_11a_03_1 a p6_11a_03_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_03_1 p6_11a_03_2 p6_11a_03_3 p6_11a_03_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cargar_lv = 0
gen horas_cargar_sd = 0

capture confirm variable p6_11a_03_1 p6_11a_03_2 p6_11a_03_3 p6_11a_03_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cargar_lv = p6_11a_03_1 + (p6_11a_03_2 / 60) if !missing(p6_11a_03_1, p6_11a_03_2)
    // Sábado y Domingo
    replace horas_cargar_sd = p6_11a_03_3 + (p6_11a_03_4 / 60) if !missing(p6_11a_03_3, p6_11a_03_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen cargar_tot = horas_cargar_lv + horas_cargar_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  4. Preparar remedios caseros o algún alimento especial (p6_11a_04_1 a p6_11a_04_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_04_1 p6_11a_04_2 p6_11a_04_3 p6_11a_04_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_remedios_lv = 0
gen horas_remedios_sd = 0

capture confirm variable p6_11a_04_1 p6_11a_04_2 p6_11a_04_3 p6_11a_04_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_remedios_lv = p6_11a_04_1 + (p6_11a_04_2 / 60) if !missing(p6_11a_04_1, p6_11a_04_2)
    // Sábado y Domingo
    replace horas_remedios_sd = p6_11a_04_3 + (p6_11a_04_4 / 60) if !missing(p6_11a_04_3, p6_11a_04_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen remedios_tot = horas_remedios_lv + horas_remedios_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  5. Dar medicamentos o checar síntomas (p6_11a_05_1 a p6_11a_05_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_05_1 p6_11a_05_2 p6_11a_05_3 p6_11a_05_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_medicamentos_lv = 0
gen horas_medicamentos_sd = 0

capture confirm variable p6_11a_05_1 p6_11a_05_2 p6_11a_05_3 p6_11a_05_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_medicamentos_lv = p6_11a_05_1 + (p6_11a_05_2 / 60) if !missing(p6_11a_05_1, p6_11a_05_2)
    // Sábado y Domingo
    replace horas_medicamentos_sd = p6_11a_05_3 + (p6_11a_05_4 / 60) if !missing(p6_11a_05_3, p6_11a_05_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen medicamentos_tot = horas_medicamentos_lv + horas_medicamentos_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  6. Acompañar a recibir atención de salud (p6_11a_06_1 a p6_11a_06_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_06_1 p6_11a_06_2 p6_11a_06_3 p6_11a_06_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_salud_lv = 0
gen horas_transporte_salud_sd = 0

capture confirm variable p6_11a_06_1 p6_11a_06_2 p6_11a_06_3 p6_11a_06_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_salud_lv = p6_11a_06_1 + (p6_11a_06_2 / 60) if !missing(p6_11a_06_1, p6_11a_06_2)
    // Sábado y Domingo
    replace horas_transporte_salud_sd = p6_11a_06_3 + (p6_11a_06_4 / 60) if !missing(p6_11a_06_3, p6_11a_06_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_salud_tot = horas_transporte_salud_lv + horas_transporte_salud_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  7. Llevar o recoger para atención de salud o terapias (p6_11a_07_1 a p6_11a_07_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_07_1 p6_11a_07_2 p6_11a_07_3 p6_11a_07_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_terapia_lv = 0
gen horas_terapia_sd = 0

capture confirm variable p6_11a_07_1 p6_11a_07_2 p6_11a_07_3 p6_11a_07_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_terapia_lv = p6_11a_07_1 + (p6_11a_07_2 / 60) if !missing(p6_11a_07_1, p6_11a_07_2)
    // Sábado y Domingo
    replace horas_terapia_sd = p6_11a_07_3 + (p6_11a_07_4 / 60) if !missing(p6_11a_07_3, p6_11a_07_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen terapia_tot = horas_terapia_lv + horas_terapia_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  8. Dar terapia o ayudar a realizar ejercicios terapéuticos (p6_11a_08_1 a p6_11a_08_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_08_1 p6_11a_08_2 p6_11a_08_3 p6_11a_08_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_ejercicios_lv = 0
gen horas_ejercicios_sd = 0

capture confirm variable p6_11a_08_1 p6_11a_08_2 p6_11a_08_3 p6_11a_08_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_ejercicios_lv = p6_11a_08_1 + (p6_11a_08_2 / 60) if !missing(p6_11a_08_1, p6_11a_08_2)
    // Sábado y Domingo
    replace horas_ejercicios_sd = p6_11a_08_3 + (p6_11a_08_4 / 60) if !missing(p6_11a_08_3, p6_11a_08_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen ejercicios_tot = horas_ejercicios_lv + horas_ejercicios_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  9. Esperar al enfermo de clases, trabajo u otro lugar (p6_11a_09_1 a p6_11a_09_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_09_1 p6_11a_09_2 p6_11a_09_3 p6_11a_09_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_espera_enfermo_lv = 0
gen horas_espera_enfermo_sd = 0

capture confirm variable p6_11a_09_1 p6_11a_09_2 p6_11a_09_3 p6_11a_09_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_espera_enfermo_lv = p6_11a_09_1 + (p6_11a_09_2 / 60) if !missing(p6_11a_09_1, p6_11a_09_2)
    // Sábado y Domingo
    replace horas_espera_enfermo_sd = p6_11a_09_3 + (p6_11a_09_4 / 60) if !missing(p6_11a_09_3, p6_11a_09_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen espera_enfermo_tot = horas_espera_enfermo_lv + horas_espera_enfermo_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  10. Llevar o recoger de clases o trabajo al enfermo (p6_11a_10_1 a p6_11a_10_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_10_1 p6_11a_10_2 p6_11a_10_3 p6_11a_10_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_enfermo_lv = 0
gen horas_transporte_enfermo_sd = 0

capture confirm variable p6_11a_10_1 p6_11a_10_2 p6_11a_10_3 p6_11a_10_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_enfermo_lv = p6_11a_10_1 + (p6_11a_10_2 / 60) if !missing(p6_11a_10_1, p6_11a_10_2)
    // Sábado y Domingo
    replace horas_transporte_enfermo_sd = p6_11a_10_3 + (p6_11a_10_4 / 60) if !missing(p6_11a_10_3, p6_11a_10_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_enfermo_tot = horas_transporte_enfermo_lv + horas_transporte_enfermo_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  11. Ayudar o apoyar en tareas de la escuela o trabajo al enfermo (p6_11a_11_1 a p6_11a_11_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_11_1 p6_11a_11_2 p6_11a_11_3 p6_11a_11_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_apoyo_enfermo_lv = 0
gen horas_apoyo_enfermo_sd = 0

capture confirm variable p6_11a_11_1 p6_11a_11_2 p6_11a_11_3 p6_11a_11_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_apoyo_enfermo_lv = p6_11a_11_1 + (p6_11a_11_2 / 60) if !missing(p6_11a_11_1, p6_11a_11_2)
    // Sábado y Domingo
    replace horas_apoyo_enfermo_sd = p6_11a_11_3 + (p6_11a_11_4 / 60) if !missing(p6_11a_11_3, p6_11a_11_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen apoyo_enfermo_tot = horas_apoyo_enfermo_lv + horas_apoyo_enfermo_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  12. Asistir a Juntas, Festivales o Apoyo Escolar (p6_11a_12_1 a p6_11a_12_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_12_1 p6_11a_12_2 p6_11a_12_3 p6_11a_12_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_apoyo_esc_lv = 0
gen horas_apoyo_esc_sd = 0

capture confirm variable p6_11a_12_1 p6_11a_12_2 p6_11a_12_3 p6_11a_12_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_apoyo_esc_lv = p6_11a_12_1 + (p6_11a_12_2 / 60) if !missing(p6_11a_12_1, p6_11a_12_2)
    // Sábado y Domingo
    replace horas_apoyo_esc_sd = p6_11a_12_3 + (p6_11a_12_4 / 60) if !missing(p6_11a_12_3, p6_11a_12_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen apoyo_esc_tot = horas_apoyo_esc_lv + horas_apoyo_esc_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  13. Jugar, leerle o escucharle al enfermo (p6_11a_13_1 a p6_11a_13_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_13_1 p6_11a_13_2 p6_11a_13_3 p6_11a_13_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_jugar_enfermo_lv = 0
gen horas_jugar_enfermo_sd = 0

capture confirm variable p6_11a_13_1 p6_11a_13_2 p6_11a_13_3 p6_11a_13_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_jugar_enfermo_lv = p6_11a_13_1 + (p6_11a_13_2 / 60) if !missing(p6_11a_13_1, p6_11a_13_2)
    // Sábado y Domingo
    replace horas_jugar_enfermo_sd = p6_11a_13_3 + (p6_11a_13_4 / 60) if !missing(p6_11a_13_3, p6_11a_13_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen jugar_enfermo_tot = horas_jugar_enfermo_lv + horas_jugar_enfermo_sd

/****************************************************************************
  Actividad 2.I: TDNR - CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
  14. Vigilar o estar al pendiente del enfermo (p6_11a_14_1 a p6_11a_14_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_11a_14_1 p6_11a_14_2 p6_11a_14_3 p6_11a_14_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_vigilancia_enfermo_lv = 0
gen horas_vigilancia_enfermo_sd = 0

capture confirm variable p6_11a_14_1 p6_11a_14_2 p6_11a_14_3 p6_11a_14_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_vigilancia_enfermo_lv = p6_11a_14_1 + (p6_11a_14_2 / 60) if !missing(p6_11a_14_1, p6_11a_14_2)
    // Sábado y Domingo
    replace horas_vigilancia_enfermo_sd = p6_11a_14_3 + (p6_11a_14_4 / 60) if !missing(p6_11a_14_3, p6_11a_14_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen vigilancia_enfermo_tot = horas_vigilancia_enfermo_lv + horas_vigilancia_enfermo_sd

/*****************************************************************
COMPONENTE FINAL: CUIDADOS ESPECIALES A INTEGRANTES DEL HOGAR
CON ENFERMEDAD CRÓNICA, TEMPORAL O DISCAPACIDAD
*****************************************************************/

gen horas_cuidados_esp_tot = ayudar_comer_tot + aseo_tot + cargar_tot + remedios_tot + medicamentos_tot + transporte_salud_tot + terapia_tot + ejercicios_tot + ///
												espera_enfermo_tot + transporte_enfermo_tot + apoyo_enfermo_tot + apoyo_esc_tot + jugar_enfermo_tot + vigilancia_enfermo_tot
												
svy:mean horas_cuidados_esp_tot if  p6_11_01 == 1 | p6_11_02 == 1 | p6_11_03 == 1 | p6_11_04 == 1 | p6_11_05 == 1 | p6_11_06 == 1 | p6_11_07 == 1 | p6_11_08 == 1 | ///
															p6_11_09 == 1 | p6_11_10 == 1 | p6_11_11 == 1 | p6_11_12 == 1 | p6_11_13 == 1 | p6_11_14 == 1
															
/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  1. Dar de comer o beber a infantes (p6_12a_01_1 a p6_12a_01_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_01_1 p6_12a_01_2 p6_12a_01_3 p6_12a_01_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_dar_comer_inf_lv = 0
gen horas_dar_comer_inf_sd = 0

capture confirm variable p6_12a_01_1 p6_12a_01_2 p6_12a_01_3 p6_12a_01_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_dar_comer_inf_lv = p6_12a_01_1 + (p6_12a_01_2 / 60) if !missing(p6_12a_01_1, p6_12a_01_2)
    // Sábado y Domingo
    replace horas_dar_comer_inf_sd = p6_12a_01_3 + (p6_12a_01_4 / 60) if !missing(p6_12a_01_3, p6_12a_01_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen dar_comer_inf_tot = horas_dar_comer_inf_lv + horas_dar_comer_inf_sd

/****************************************************************************
  CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  2. Bañar, asear, cambiar pañales, vestir o arreglar a infantes (p6_12a_02_1 a p6_12a_02_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_02_1 p6_12a_02_2 p6_12a_02_3 p6_12a_02_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_aseo_inf_lv = 0
gen horas_aseo_inf_sd = 0

capture confirm variable p6_12a_02_1 p6_12a_02_2 p6_12a_02_3 p6_12a_02_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_aseo_inf_lv = p6_12a_02_1 + (p6_12a_02_2 / 60) if !missing(p6_12a_02_1, p6_12a_02_2)
    // Sábado y Domingo
    replace horas_aseo_inf_sd = p6_12a_02_3 + (p6_12a_02_4 / 60) if !missing(p6_12a_02_3, p6_12a_02_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen aseo_inf_tot = horas_aseo_inf_lv + horas_aseo_inf_sd

/****************************************************************************
   CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  3. Cargar o acostar a infantes (p6_12a_03_1 a p6_12a_03_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_03_1 p6_12a_03_2 p6_12a_03_3 p6_12a_03_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cargar_inf_lv = 0
gen horas_cargar_inf_sd = 0

capture confirm variable p6_12a_03_1 p6_12a_03_2 p6_12a_03_3 p6_12a_03_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cargar_inf_lv = p6_12a_03_1 + (p6_12a_03_2 / 60) if !missing(p6_12a_03_1, p6_12a_03_2)
    // Sábado y Domingo
    replace horas_cargar_inf_sd = p6_12a_03_3 + (p6_12a_03_4 / 60) if !missing(p6_12a_03_3, p6_12a_03_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen cargar_inf_tot = horas_cargar_inf_lv + horas_cargar_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  4. Esperar de clase, actividad o taller a un infante (p6_12a_04_1 a p6_12a_04_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_04_1 p6_12a_04_2 p6_12a_04_3 p6_12a_04_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_esperar_inf_lv = 0
gen horas_esperar_inf_sd = 0

capture confirm variable p6_12a_04_1 p6_12a_04_2 p6_12a_04_3 p6_12a_04_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_esperar_inf_lv = p6_12a_04_1 + (p6_12a_04_2 / 60) if !missing(p6_12a_04_1, p6_12a_04_2)
    // Sábado y Domingo
    replace horas_esperar_inf_sd = p6_12a_04_3 + (p6_12a_04_4 / 60) if !missing(p6_12a_04_3, p6_12a_04_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen esperar_inf_tot = horas_esperar_inf_lv + horas_esperar_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  5. Llevar o recoger de guardería, preescolar o casa de familiares (p6_12a_05_1 a p6_12a_05_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_05_1 p6_12a_05_2 p6_12a_05_3 p6_12a_05_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_guard_lv = 0
gen horas_transporte_guard_sd = 0

capture confirm variable p6_12a_05_1 p6_12a_05_2 p6_12a_05_3 p6_12a_05_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_guard_lv = p6_12a_05_1 + (p6_12a_05_2 / 60) if !missing(p6_12a_05_1, p6_12a_05_2)
    // Sábado y Domingo
    replace horas_transporte_guard_sd = p6_12a_05_3 + (p6_12a_05_4 / 60) if !missing(p6_12a_05_3, p6_12a_05_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_guard_tot = horas_transporte_guard_lv + horas_transporte_guard_sd


/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  6. Ayudar en actividades de educación inicial (p6_12a_06_1 a p6_12a_06_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_06_1 p6_12a_06_2 p6_12a_06_3 p6_12a_06_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_educ_inicial_lv = 0
gen horas_educ_inicial_sd = 0

capture confirm variable p6_12a_06_1 p6_12a_06_2 p6_12a_06_3 p6_12a_06_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_educ_inicial_lv = p6_12a_06_1 + (p6_12a_06_2 / 60) if !missing(p6_12a_06_1, p6_12a_06_2)
    // Sábado y Domingo
    replace horas_educ_inicial_sd = p6_12a_06_3 + (p6_12a_06_4 / 60) if !missing(p6_12a_06_3, p6_12a_06_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen educ_inicial_tot = horas_educ_inicial_lv + horas_educ_inicial_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  7. Asistir a juntas o festivales de infantes (p6_12a_07_1 a p6_12a_07_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_07_1 p6_12a_07_2 p6_12a_07_3 p6_12a_07_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_juntas_inf_lv = 0
gen horas_juntas_inf_sd = 0

capture confirm variable p6_12a_07_1 p6_12a_07_2 p6_12a_07_3 p6_12a_07_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_juntas_inf_lv = p6_12a_07_1 + (p6_12a_07_2 / 60) if !missing(p6_12a_07_1, p6_12a_07_2)
    // Sábado y Domingo
    replace horas_juntas_inf_sd = p6_12a_07_3 + (p6_12a_07_4 / 60) if !missing(p6_12a_07_3, p6_12a_07_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen juntas_inf_tot = horas_juntas_inf_lv + horas_juntas_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  8. Acompañar a Infantes a Recibir Atención de Salud (p6_12a_08_1 a p6_12a_08_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_08_1 p6_12a_08_2 p6_12a_08_3 p6_12a_08_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_salud_inf_lv = 0
gen horas_salud_inf_sd = 0

capture confirm variable p6_12a_08_1 p6_12a_08_2 p6_12a_08_3 p6_12a_08_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_salud_inf_lv = p6_12a_08_1 + (p6_12a_08_2 / 60) if !missing(p6_12a_08_1, p6_12a_08_2)
    // Sábado y Domingo
    replace horas_salud_inf_sd = p6_12a_08_3 + (p6_12a_08_4 / 60) if !missing(p6_12a_08_3, p6_12a_08_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen salud_inf_tot = horas_salud_inf_lv + horas_salud_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  9. Llevar o recoger para que los infantes reciban atención de salud (p6_12a_09_1 a p6_12a_09_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_09_1 p6_12a_09_2 p6_12a_09_3 p6_12a_09_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_salud_inf_lv = 0
gen horas_transporte_salud_inf_sd = 0

capture confirm variable p6_12a_09_1 p6_12a_09_2 p6_12a_09_3 p6_12a_09_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_salud_inf_lv = p6_12a_09_1 + (p6_12a_09_2 / 60) if !missing(p6_12a_09_1, p6_12a_09_2)
    // Sábado y Domingo
    replace horas_transporte_salud_inf_sd = p6_12a_09_3 + (p6_12a_09_4 / 60) if !missing(p6_12a_09_3, p6_12a_09_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_salud_inf_tot = horas_transporte_salud_inf_lv + horas_transporte_salud_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  10. Revisar o dar atención a la salud del infante (p6_12a_10_1 a p6_12a_10_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_10_1 p6_12a_10_2 p6_12a_10_3 p6_12a_10_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_salud_atenc_inf_lv = 0
gen horas_salud_atenc_inf_sd = 0

capture confirm variable p6_12a_10_1 p6_12a_10_2 p6_12a_10_3 p6_12a_10_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_salud_atenc_inf_lv = p6_12a_10_1 + (p6_12a_10_2 / 60) if !missing(p6_12a_10_1, p6_12a_10_2)
    // Sábado y Domingo
    replace horas_salud_atenc_inf_sd = p6_12a_10_3 + (p6_12a_10_4 / 60) if !missing(p6_12a_10_3, p6_12a_10_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen salud_atenc_inf_tot = horas_salud_atenc_inf_lv + horas_salud_atenc_inf_sd

/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  11. Jugar, leer, escuchar, orientar o consolar (p6_12a_11_1 a p6_12a_11_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_11_1 p6_12a_11_2 p6_12a_11_3 p6_12a_11_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_jugar_inf_lv = 0
gen horas_jugar_inf_sd = 0

capture confirm variable p6_12a_11_1 p6_12a_11_2 p6_12a_11_3 p6_12a_11_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_jugar_inf_lv = p6_12a_11_1 + (p6_12a_11_2 / 60) if !missing(p6_12a_11_1, p6_12a_11_2)
    // Sábado y Domingo
    replace horas_jugar_inf_sd = p6_12a_11_3 + (p6_12a_11_4 / 60) if !missing(p6_12a_11_3, p6_12a_11_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen jugar_inf_tot = horas_jugar_inf_lv + horas_jugar_inf_sd


/****************************************************************************
  Actividad 2.J: TDNR - CUIDADO A INTEGRANTES DE 0 A 5 AÑOS
  12. Vigilar o estar pendiente de forma presente del infante (p6_12a_12_1 a p6_12a_12_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_12a_12_1 p6_12a_12_2 p6_12a_12_3 p6_12a_12_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_vigilancia_inf_lv = 0
gen horas_vigilancia_inf_sd = 0

capture confirm variable p6_12a_12_1 p6_12a_12_2 p6_12a_12_3 p6_12a_12_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_vigilancia_inf_lv = p6_12a_12_1 + (p6_12a_12_2 / 60) if !missing(p6_12a_12_1, p6_12a_12_2)
    // Sábado y Domingo
    replace horas_vigilancia_inf_sd = p6_12a_12_3 + (p6_12a_12_4 / 60) if !missing(p6_12a_12_3, p6_12a_12_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen vigilancia_inf_tot = horas_vigilancia_inf_lv + horas_vigilancia_inf_sd


/*****************************************************************
COMPONENTE FINAL: CUIDADOS A INTEGRANTES DE 
0 A 5 AÑOS DE EDAD
*****************************************************************/

gen horas_cuidados_inf_tot = dar_comer_inf_tot + aseo_inf_tot + cargar_inf_tot + esperar_inf_tot + transporte_guard_tot + educ_inicial_tot +  juntas_inf_tot + ///
												salud_inf_tot +  transporte_salud_inf_tot + salud_atenc_inf_tot + jugar_inf_tot +  vigilancia_inf_tot

svy:mean horas_cuidados_inf_tot if p6_12_01 == 1 | p6_12_02 == 1 | p6_12_03 == 1 | p6_12_04 == 1 | p6_12_05 == 1| p6_12_06 == 1 | p6_12_07 == 1 | ///
														 p6_12_08 == 1 | p6_12_09 == 1 | p6_12_10 == 1 | p6_12_11 == 1 | p6_12_12 == 1
														 
/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  1. Esperar de Clase, Actividad o Taller (p6_13a_1_1 a p6_13a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_1_1 p6_13a_1_2 p6_13a_1_3 p6_13a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_esperar_adol_lv = 0
gen horas_esperar_adol_sd = 0

capture confirm variable p6_13a_1_1 p6_13a_1_2 p6_13a_1_3 p6_13a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_esperar_adol_lv = p6_13a_1_1 + (p6_13a_1_2 / 60) if !missing(p6_13a_1_1, p6_13a_1_2)
    // Sábado y Domingo
    replace horas_esperar_adol_sd = p6_13a_1_3 + (p6_13a_1_4 / 60) if !missing(p6_13a_1_3, p6_13a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen esperar_adol_tot = horas_esperar_adol_lv + horas_esperar_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  2. Llevar o Recoger de la Escuela, Clase o Casa de Familiares (p6_13a_2_1 a p6_13a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_2_1 p6_13a_2_2 p6_13a_2_3 p6_13a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_adol_lv = 0
gen horas_transporte_adol_sd = 0

capture confirm variable p6_13a_2_1 p6_13a_2_2 p6_13a_2_3 p6_13a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_adol_lv = p6_13a_2_1 + (p6_13a_2_2 / 60) if !missing(p6_13a_2_1, p6_13a_2_2)
    // Sábado y Domingo
    replace horas_transporte_adol_sd = p6_13a_2_3 + (p6_13a_2_4 / 60) if !missing(p6_13a_2_3, p6_13a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_adol_tot = horas_transporte_adol_lv + horas_transporte_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  3. Ayudar en las tareas de la escuela (p6_13a_3_1 a p6_13a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_3_1 p6_13a_3_2 p6_13a_3_3 p6_13a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_tareas_esc_lv = 0
gen horas_tareas_esc_sd = 0

capture confirm variable p6_13a_3_1 p6_13a_3_2 p6_13a_3_3 p6_13a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_tareas_esc_lv = p6_13a_3_1 + (p6_13a_3_2 / 60) if !missing(p6_13a_3_1, p6_13a_3_2)
    // Sábado y Domingo
    replace horas_tareas_esc_sd = p6_13a_3_3 + (p6_13a_3_4 / 60) if !missing(p6_13a_3_3, p6_13a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen tareas_esc_tot = horas_tareas_esc_lv + horas_tareas_esc_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  4. Asistir a juntas, festivales o actividades de apoyo (p6_13a_4_1 a p6_13a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_4_1 p6_13a_4_2 p6_13a_4_3 p6_13a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_juntas_adol_lv = 0
gen horas_juntas_adol_sd = 0

capture confirm variable p6_13a_4_1 p6_13a_4_2 p6_13a_4_3 p6_13a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_juntas_adol_lv = p6_13a_4_1 + (p6_13a_4_2 / 60) if !missing(p6_13a_4_1, p6_13a_4_2)
    // Sábado y Domingo
    replace horas_juntas_adol_sd = p6_13a_4_3 + (p6_13a_4_4 / 60) if !missing(p6_13a_4_3, p6_13a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen juntas_adol_tot = horas_juntas_adol_lv + horas_juntas_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  5. Acompañar mientras recibían atención de salud (p6_13a_5_1 a p6_13a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_5_1 p6_13a_5_2 p6_13a_5_3 p6_13a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_acomp_salud_adol_lv = 0
gen horas_acomp_salud_adol_sd = 0

capture confirm variable p6_13a_5_1 p6_13a_5_2 p6_13a_5_3 p6_13a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_acomp_salud_adol_lv = p6_13a_5_1 + (p6_13a_5_2 / 60) if !missing(p6_13a_5_1, p6_13a_5_2)
    // Sábado y Domingo
    replace horas_acomp_salud_adol_sd = p6_13a_5_3 + (p6_13a_5_4 / 60) if !missing(p6_13a_5_3, p6_13a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen acomp_salud_adol_tot = horas_acomp_salud_adol_lv + horas_acomp_salud_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  6. Llevar o recoger para atención de salud (p6_13a_6_1 a p6_13a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_6_1 p6_13a_6_2 p6_13a_6_3 p6_13a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_salud_adol_lv = 0
gen horas_transporte_salud_adol_sd = 0

capture confirm variable p6_13a_6_1 p6_13a_6_2 p6_13a_6_3 p6_13a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_salud_adol_lv = p6_13a_6_1 + (p6_13a_6_2 / 60) if !missing(p6_13a_6_1, p6_13a_6_2)
    // Sábado y Domingo
    replace horas_transporte_salud_adol_sd = p6_13a_6_3 + (p6_13a_6_4 / 60) if !missing(p6_13a_6_3, p6_13a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_salud_adol_tot = horas_transporte_salud_adol_lv + horas_transporte_salud_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  7. Revisar o dar atención de salud (p6_13a_7_1 a p6_13a_7_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_7_1 p6_13a_7_2 p6_13a_7_3 p6_13a_7_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_atenc_salud_adol_lv = 0
gen horas_atenc_salud_adol_sd = 0

capture confirm variable p6_13a_7_1 p6_13a_7_2 p6_13a_7_3 p6_13a_7_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_atenc_salud_adol_lv = p6_13a_7_1 + (p6_13a_7_2 / 60) if !missing(p6_13a_7_1, p6_13a_7_2)
    // Sábado y Domingo
    replace horas_atenc_salud_adol_sd = p6_13a_7_3 + (p6_13a_7_4 / 60) if !missing(p6_13a_7_3, p6_13a_7_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen atenc_salud_adol_tot = horas_atenc_salud_adol_lv + horas_atenc_salud_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  8. Jugar, leerle, escucharle, orientarle o consolarle (p6_13a_8_1 a p6_13a_8_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_8_1 p6_13a_8_2 p6_13a_8_3 p6_13a_8_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_jugar_adol_lv = 0
gen horas_jugar_adol_sd = 0

capture confirm variable p6_13a_8_1 p6_13a_8_2 p6_13a_8_3 p6_13a_8_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_jugar_adol_lv = p6_13a_8_1 + (p6_13a_8_2 / 60) if !missing(p6_13a_8_1, p6_13a_8_2)
    // Sábado y Domingo
    replace horas_jugar_adol_sd = p6_13a_8_3 + (p6_13a_8_4 / 60) if !missing(p6_13a_8_3, p6_13a_8_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen jugar_adol_tot = horas_jugar_adol_lv + horas_jugar_adol_sd

/****************************************************************************
  Actividad 2.K: TDNR - CUIDADO A INTEGRANTES DE 6 A 14 AÑOS
  9. Vigilar o estar al pendiente de forma presente (p6_13a_9_1 a p6_13a_9_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_13a_9_1 p6_13a_9_2 p6_13a_9_3 p6_13a_9_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_vigilancia_adol_lv = 0
gen horas_vigilancia_adol_sd = 0

capture confirm variable p6_13a_9_1 p6_13a_9_2 p6_13a_9_3 p6_13a_9_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_vigilancia_adol_lv = p6_13a_9_1 + (p6_13a_9_2 / 60) if !missing(p6_13a_9_1, p6_13a_9_2)
    // Sábado y Domingo
    replace horas_vigilancia_adol_sd = p6_13a_9_3 + (p6_13a_9_4 / 60) if !missing(p6_13a_9_3, p6_13a_9_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen vigilancia_adol_tot = horas_vigilancia_adol_lv + horas_vigilancia_adol_sd

/*****************************************************************
COMPONENTE FINAL: CUIDADOS A INTEGRANTES DE 
6 A 14 AÑOS DE EDAD 
*****************************************************************/

gen horas_cuidados_adol_tot = esperar_adol_tot + transporte_adol_tot + tareas_esc_tot + juntas_adol_tot + acomp_salud_adol_tot +  transporte_salud_adol_tot + ///
													atenc_salud_adol_tot + jugar_adol_tot + vigilancia_adol_tot

svy:mean horas_cuidados_adol_tot if p6_13_1 == 1 | p6_13_2 == 1 | p6_13_3 == 1 | p6_13_4 == 1 | p6_13_5 == 1| p6_13_6 == 1 | p6_13_7 == 1 | ///
														 p6_13_8 == 1 | p6_13_9 == 1 
														 
/* Nos da el mismo resultado que INEG */

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  1. Apoyar o asesorar en el uso de tecnología (p6_14a_1_1 a p6_14a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_1_1 p6_14a_1_2 p6_14a_1_3 p6_14a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_asesoria_tec_lv = 0
gen horas_asesoria_tec_sd = 0

capture confirm variable p6_14a_1_1 p6_14a_1_2 p6_14a_1_3 p6_14a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_asesoria_tec_lv = p6_14a_1_1 + (p6_14a_1_2 / 60) if !missing(p6_14a_1_1, p6_14a_1_2)
    // Sábado y Domingo
    replace horas_asesoria_tec_sd = p6_14a_1_3 + (p6_14a_1_4 / 60) if !missing(p6_14a_1_3, p6_14a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen asesoria_tec_tot = horas_asesoria_tec_lv + horas_asesoria_tec_sd

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  2. Acompañar a que reciban atención de salud (p6_14a_2_1 a p6_14a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_2_1 p6_14a_2_2 p6_14a_2_3 p6_14a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_acomp_salud_adulto_lv = 0
gen horas_acomp_salud_adulto_sd = 0

capture confirm variable p6_14a_2_1 p6_14a_2_2 p6_14a_2_3 p6_14a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_acomp_salud_adulto_lv = p6_14a_2_1 + (p6_14a_2_2 / 60) if !missing(p6_14a_2_1, p6_14a_2_2)
    // Sábado y Domingo
    replace horas_acomp_salud_adulto_sd = p6_14a_2_3 + (p6_14a_2_4 / 60) if !missing(p6_14a_2_3, p6_14a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen acomp_salud_adulto_tot = horas_acomp_salud_adulto_lv + horas_acomp_salud_adulto_sd

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  3. Llevar o Recoger de Atención de Salud (p6_14a_3_1 a p6_14a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_3_1 p6_14a_3_2 p6_14a_3_3 p6_14a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_recoger_salud_adulto_lv = 0
gen horas_recoger_salud_adulto_sd = 0

capture confirm variable p6_14a_3_1 p6_14a_3_2 p6_14a_3_3 p6_14a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_recoger_salud_adulto_lv = p6_14a_3_1 + (p6_14a_3_2 / 60) if !missing(p6_14a_3_1, p6_14a_3_2)
    // Sábado y Domingo
    replace horas_recoger_salud_adulto_sd = p6_14a_3_3 + (p6_14a_3_4 / 60) if !missing(p6_14a_3_3, p6_14a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen recoger_salud_adulto_tot = horas_recoger_salud_adulto_lv + horas_recoger_salud_adulto_sd

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  4. Esperar de Clases, Trabajo o Trámite (p6_14a_4_1 a p6_14a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_4_1 p6_14a_4_2 p6_14a_4_3 p6_14a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_esperar_adulto_lv = 0
gen horas_esperar_adulto_sd = 0

capture confirm variable p6_14a_4_1 p6_14a_4_2 p6_14a_4_3 p6_14a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_esperar_adulto_lv = p6_14a_4_1 + (p6_14a_4_2 / 60) if !missing(p6_14a_4_1, p6_14a_4_2)
    // Sábado y Domingo
    replace horas_esperar_adulto_sd = p6_14a_4_3 + (p6_14a_4_4 / 60) if !missing(p6_14a_4_3, p6_14a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen esperar_adulto_tot = horas_esperar_adulto_lv + horas_esperar_adulto_sd

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  5. Llevar o Recoger de Clases, Trabajo o Trámite (p6_14a_5_1 a p6_14a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_5_1 p6_14a_5_2 p6_14a_5_3 p6_14a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_adulto_lv = 0
gen horas_transporte_adulto_sd = 0

capture confirm variable p6_14a_5_1 p6_14a_5_2 p6_14a_5_3 p6_14a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_adulto_lv = p6_14a_5_1 + (p6_14a_5_2 / 60) if !missing(p6_14a_5_1, p6_14a_5_2)
    // Sábado y Domingo
    replace horas_transporte_adulto_sd = p6_14a_5_3 + (p6_14a_5_4 / 60) if !missing(p6_14a_5_3, p6_14a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_adulto_tot = horas_transporte_adulto_lv + horas_transporte_adulto_sd

/****************************************************************************
  Actividad 2.L: TDNR - CUIDADOS A ADULTOS (15-59 AÑOS)
  6. Escuchar, Orientar o Consolar (p6_14a_6_1 a p6_14a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_14a_6_1 p6_14a_6_2 p6_14a_6_3 p6_14a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_consuelo_adulto_lv = 0
gen horas_consuelo_adulto_sd = 0

capture confirm variable p6_14a_6_1 p6_14a_6_2 p6_14a_6_3 p6_14a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_consuelo_adulto_lv = p6_14a_6_1 + (p6_14a_6_2 / 60) if !missing(p6_14a_6_1, p6_14a_6_2)
    // Sábado y Domingo
    replace horas_consuelo_adulto_sd = p6_14a_6_3 + (p6_14a_6_4 / 60) if !missing(p6_14a_6_3, p6_14a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen consuelo_adulto_tot = horas_consuelo_adulto_lv + horas_consuelo_adulto_sd

/*****************************************************************
COMPONENTE FINAL: CUIDADOS A INTEGRANTES DE 
15 A 59 AÑOS DE EDAD 
*****************************************************************/

gen horas_cuidados_adult_tot = asesoria_tec_tot + acomp_salud_adulto_tot + recoger_salud_adulto_tot + esperar_adulto_tot + transporte_adulto_tot +  consuelo_adulto_tot

svy:mean horas_cuidados_adult_tot if p6_14_1 == 1 | p6_14_2 == 1 | p6_14_3 == 1 | p6_14_4 == 1 | p6_14_5 == 1 | p6_14_6 == 1

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  1. Apoyar o Asesorar en el Uso de Tecnología (p6_15a_1_1 a p6_15a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_1_1 p6_15a_1_2 p6_15a_1_3 p6_15a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_asesoria_tec_mayor_lv = 0
gen horas_asesoria_tec_mayor_sd = 0

capture confirm variable p6_15a_1_1 p6_15a_1_2 p6_15a_1_3 p6_15a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_asesoria_tec_mayor_lv = p6_15a_1_1 + (p6_15a_1_2 / 60) if !missing(p6_15a_1_1, p6_15a_1_2)
    // Sábado y Domingo
    replace horas_asesoria_tec_mayor_sd = p6_15a_1_3 + (p6_15a_1_4 / 60) if !missing(p6_15a_1_3, p6_15a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen asesoria_tec_mayor_tot = horas_asesoria_tec_mayor_lv + horas_asesoria_tec_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  2. Acompañar a que reciban atención de salud (p6_15a_2_1 a p6_15a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_2_1 p6_15a_2_2 p6_15a_2_3 p6_15a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_acomp_salud_mayor_lv = 0
gen horas_acomp_salud_mayor_sd = 0

capture confirm variable p6_15a_2_1 p6_15a_2_2 p6_15a_2_3 p6_15a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_acomp_salud_mayor_lv = p6_15a_2_1 + (p6_15a_2_2 / 60) if !missing(p6_15a_2_1, p6_15a_2_2)
    // Sábado y Domingo
    replace horas_acomp_salud_mayor_sd = p6_15a_2_3 + (p6_15a_2_4 / 60) if !missing(p6_15a_2_3, p6_15a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen acomp_salud_mayor_tot = horas_acomp_salud_mayor_lv + horas_acomp_salud_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  3. Llevar o Recoger para Atención de Salud (p6_15a_3_1 a p6_15a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_3_1 p6_15a_3_2 p6_15a_3_3 p6_15a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_salud_mayor_lv = 0
gen horas_transporte_salud_mayor_sd = 0

capture confirm variable p6_15a_3_1 p6_15a_3_2 p6_15a_3_3 p6_15a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_salud_mayor_lv = p6_15a_3_1 + (p6_15a_3_2 / 60) if !missing(p6_15a_3_1, p6_15a_3_2)
    // Sábado y Domingo
    replace horas_transporte_salud_mayor_sd = p6_15a_3_3 + (p6_15a_3_4 / 60) if !missing(p6_15a_3_3, p6_15a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_salud_mayor_tot = horas_transporte_salud_mayor_lv + horas_transporte_salud_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  4. Esperar del Trabajo, Trámite u Otro Lugar (p6_15a_4_1 a p6_15a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_4_1 p6_15a_4_2 p6_15a_4_3 p6_15a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_esperar_mayor_lv = 0
gen horas_esperar_mayor_sd = 0

capture confirm variable p6_15a_4_1 p6_15a_4_2 p6_15a_4_3 p6_15a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_esperar_mayor_lv = p6_15a_4_1 + (p6_15a_4_2 / 60) if !missing(p6_15a_4_1, p6_15a_4_2)
    // Sábado y Domingo
    replace horas_esperar_mayor_sd = p6_15a_4_3 + (p6_15a_4_4 / 60) if !missing(p6_15a_4_3, p6_15a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen esperar_mayor_tot = horas_esperar_mayor_lv + horas_esperar_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  5. Llevar o Recoger del Trabajo o Trámite (p6_15a_5_1 a p6_15a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_5_1 p6_15a_5_2 p6_15a_5_3 p6_15a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_transporte_mayor_lv = 0
gen horas_transporte_mayor_sd = 0

capture confirm variable p6_15a_5_1 p6_15a_5_2 p6_15a_5_3 p6_15a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_transporte_mayor_lv = p6_15a_5_1 + (p6_15a_5_2 / 60) if !missing(p6_15a_5_1, p6_15a_5_2)
    // Sábado y Domingo
    replace horas_transporte_mayor_sd = p6_15a_5_3 + (p6_15a_5_4 / 60) if !missing(p6_15a_5_3, p6_15a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen transporte_mayor_tot = horas_transporte_mayor_lv + horas_transporte_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  6. Leerle un libro, escuchar, orientar o consolar (p6_15a_6_1 a p6_15a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_6_1 p6_15a_6_2 p6_15a_6_3 p6_15a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_consuelo_mayor_lv = 0
gen horas_consuelo_mayor_sd = 0

capture confirm variable p6_15a_6_1 p6_15a_6_2 p6_15a_6_3 p6_15a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_consuelo_mayor_lv = p6_15a_6_1 + (p6_15a_6_2 / 60) if !missing(p6_15a_6_1, p6_15a_6_2)
    // Sábado y Domingo
    replace horas_consuelo_mayor_sd = p6_15a_6_3 + (p6_15a_6_4 / 60) if !missing(p6_15a_6_3, p6_15a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen consuelo_mayor_tot = horas_consuelo_mayor_lv + horas_consuelo_mayor_sd

/****************************************************************************
  Actividad 2.M: TDNR - CUIDADOS A ADULTOS MAYORES (60 AÑOS Y MÁS)
  7. Vigilar o estar al pendiente de forma presente (p6_15a_7_1 a p6_15a_7_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_15a_7_1 p6_15a_7_2 p6_15a_7_3 p6_15a_7_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_vigilancia_mayor_lv = 0
gen horas_vigilancia_mayor_sd = 0

capture confirm variable p6_15a_7_1 p6_15a_7_2 p6_15a_7_3 p6_15a_7_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_vigilancia_mayor_lv = p6_15a_7_1 + (p6_15a_7_2 / 60) if !missing(p6_15a_7_1, p6_15a_7_2)
    // Sábado y Domingo
    replace horas_vigilancia_mayor_sd = p6_15a_7_3 + (p6_15a_7_4 / 60) if !missing(p6_15a_7_3, p6_15a_7_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen vigilancia_mayor_tot = horas_vigilancia_mayor_lv + horas_vigilancia_mayor_sd

/*****************************************************************
COMPONENTE FINAL: CUIDADOS A INTEGRANTES DE 
60 Y MÁS AÑOS DE EDAD 
*****************************************************************/

gen horas_cuidados_adultmay_tot = asesoria_tec_mayor_tot + acomp_salud_mayor_tot + transporte_salud_mayor_tot + esperar_mayor_tot + transporte_mayor_tot + ///
														consuelo_mayor_tot + vigilancia_mayor_tot 

svy:mean horas_cuidados_adultmay_tot if p6_15_1 == 1 | p6_15_2 == 1 | p6_15_3 == 1 | p6_15_4 == 1 | p6_15_5 == 1 | p6_15_6 == 1 | p6_15_7 == 1
/* Nos da el mismo resultado que INEGI */

/***************************************************************************************************************
COMPONENTE FINAL DEL BLOQUE DE TRABAJO NO REMUNERADO DE CUIDADOS A INTEGRANTES DEL HOGAR
***************************************************************************************************************/

gen horas_totales_cuidados = horas_cuidados_esp_tot + horas_cuidados_inf_tot + horas_cuidados_adol_tot + horas_cuidados_adult_tot + horas_cuidados_adultmay_tot
svy:mean horas_totales_cuidados if p6_11_01 == 1 | p6_11_02 == 1 | p6_11_03 == 1 | p6_11_04 == 1 | p6_11_05 == 1 | p6_11_06 == 1 | p6_11_07 == 1 | p6_11_08 == 1 | ///
															p6_11_09 == 1 | p6_11_10 == 1 | p6_11_11 == 1 | p6_11_12 == 1 | p6_11_13 == 1 | p6_11_14 == 1 | p6_12_01 == 1 | p6_12_02 == 1 | ///
															p6_12_03 == 1 | p6_12_04 == 1 | p6_12_05 == 1| p6_12_06 == 1 | p6_12_07 == 1 | p6_12_08 == 1 | p6_12_09 == 1 | p6_12_10 == 1 | ///
															p6_12_11 == 1 | p6_12_12 == 1 | p6_13_1 == 1 | p6_13_2 == 1 | p6_13_3 == 1 | p6_13_4 == 1 | p6_13_5 == 1| p6_13_6 == 1 | p6_13_7 == 1 | ///
														    p6_13_8 == 1 | p6_13_9 == 1 | p6_14_1 == 1 | p6_14_2 == 1 | p6_14_3 == 1 | p6_14_4 == 1 | p6_14_5 == 1 | p6_14_6 == 1 | ///
															p6_15_1 == 1 | p6_15_2 == 1 | p6_15_3 == 1 | p6_15_4 == 1 | p6_15_5 == 1 | p6_15_6 == 1 | p6_15_7 == 1
															
															
/* Nos da el mismo resultado que INEGI */

/***************************************************************************************************************
 BLOQUE DE TRABAJO NO REMUNERADO COMO APOYO A OTROS HOGARES Y TRABAJO VOLUNTARIO
***************************************************************************************************************/

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES
  1. Ayuda gratuita en quehaceres domésticos a otro hogar (p6_16a_1_1 a p6_16a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_1_1 p6_16a_1_2 p6_16a_1_3 p6_16a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_quehacer_ajenos_lv = 0
gen horas_quehacer_ajenos_sd = 0

capture confirm variable p6_16a_1_1 p6_16a_1_2 p6_16a_1_3 p6_16a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_quehacer_ajenos_lv = p6_16a_1_1 + (p6_16a_1_2 / 60) if !missing(p6_16a_1_1, p6_16a_1_2)
    // Sábado y Domingo
    replace horas_quehacer_ajenos_sd = p6_16a_1_3 + (p6_16a_1_4 / 60) if !missing(p6_16a_1_3, p6_16a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_quehacer_ajenos_tot = horas_quehacer_ajenos_lv + horas_quehacer_ajenos_sd

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES
  2. Ayuda gratuita a otro hogar en compras/pagos/trámites/reparaciones (p6_16a_2_1 a p6_16a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_2_1 p6_16a_2_2 p6_16a_2_3 p6_16a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_tramites_ajenos_lv = 0
gen horas_tramites_ajenos_sd = 0

capture confirm variable p6_16a_2_1 p6_16a_2_2 p6_16a_2_3 p6_16a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_tramites_ajenos_lv = p6_16a_2_1 + (p6_16a_2_2 / 60) if !missing(p6_16a_2_1, p6_16a_2_2)
    // Sábado y Domingo
    replace horas_tramites_ajenos_sd = p6_16a_2_3 + (p6_16a_2_4 / 60) if !missing(p6_16a_2_3, p6_16a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_tramites_ajenos_tot = horas_tramites_ajenos_lv + horas_tramites_ajenos_sd


/****************************************************************************
 COMPONENTE FINAL: TRABAJO DOMÉSTICO PARA OTRO HOGAR (P6.16A COMPONENTE 1 Y 2)
****************************************************************************/

gen trabajo_domestico_otro_hogar = horas_quehacer_ajenos_tot + horas_tramites_ajenos_tot
svy:mean trabajo_domestico_otro_hogar if p6_16_1 == 1 | p6_16_2 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES
  3. Ayuda gratuita en atención de cuidados especiales (p6_16a_3_1 a p6_16a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_3_1 p6_16a_3_2 p6_16a_3_3 p6_16a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_aten_cui_disca_lv = 0
gen horas_aten_cui_disca_sd = 0

capture confirm variable p6_16a_3_1 p6_16a_3_2 p6_16a_3_3 p6_16a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_aten_cui_disca_lv = p6_16a_3_1 + (p6_16a_3_2 / 60) if !missing(p6_16a_3_1, p6_16a_3_2)
    // Sábado y Domingo
    replace horas_aten_cui_disca_sd = p6_16a_3_3 + (p6_16a_3_4 / 60) if !missing(p6_16a_3_3, p6_16a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_aten_cui_disca = horas_aten_cui_disca_lv + horas_aten_cui_disca_sd
svy:mean horas_aten_cui_disca if p6_16_3 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES (CUIDADOS POR EDAD)
  4. Ayuda gratuita en cuidado de infantes 0-5 años (p6_16a_4_1 a p6_16a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_4_1 p6_16a_4_2 p6_16a_4_3 p6_16a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cui_inf_ajenos_lv = 0
gen horas_cui_inf_ajenos_sd = 0

capture confirm variable p6_16a_4_1 p6_16a_4_2 p6_16a_4_3 p6_16a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cui_inf_ajenos_lv = p6_16a_4_1 + (p6_16a_4_2 / 60) if !missing(p6_16a_4_1, p6_16a_4_2)
    // Sábado y Domingo
    replace horas_cui_inf_ajenos_sd = p6_16a_4_3 + (p6_16a_4_4 / 60) if !missing(p6_16a_4_3, p6_16a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_cui_menores = horas_cui_inf_ajenos_lv + horas_cui_inf_ajenos_sd

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES (CUIDADOS POR EDAD)
  5. Ayuda gratuita en cuidado de personas de 6 a 59 años (p6_16a_5_1 a p6_16a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_5_1 p6_16a_5_2 p6_16a_5_3 p6_16a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cui_adultos_ajenos_lv = 0
gen horas_cui_adultos_ajenos_sd = 0

capture confirm variable p6_16a_5_1 p6_16a_5_2 p6_16a_5_3 p6_16a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cui_adultos_ajenos_lv = p6_16a_5_1 + (p6_16a_5_2 / 60) if !missing(p6_16a_5_1, p6_16a_5_2)
    // Sábado y Domingo
    replace horas_cui_adultos_ajenos_sd = p6_16a_5_3 + (p6_16a_5_4 / 60) if !missing(p6_16a_5_3, p6_16a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_cui_adultos = horas_cui_adultos_ajenos_lv + horas_cui_adultos_ajenos_sd

/****************************************************************************
  Actividad 2.N: TDNR - APOYO A OTROS HOGARES (CUIDADOS POR EDAD)
  6. Ayuda gratuita en cuidado de personas de 60 años y más (p6_16a_6_1 a p6_16a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_16a_6_1 p6_16a_6_2 p6_16a_6_3 p6_16a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cui_mayor_ajenos_lv = 0
gen horas_cui_mayor_ajenos_sd = 0

capture confirm variable p6_16a_6_1 p6_16a_6_2 p6_16a_6_3 p6_16a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cui_mayor_ajenos_lv = p6_16a_6_1 + (p6_16a_6_2 / 60) if !missing(p6_16a_6_1, p6_16a_6_2)
    // Sábado y Domingo
    replace horas_cui_mayor_ajenos_sd = p6_16a_6_3 + (p6_16a_6_4 / 60) if !missing(p6_16a_6_3, p6_16a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_adultos_mayores = horas_cui_mayor_ajenos_lv + horas_cui_mayor_ajenos_sd


/****************************************************************************
COMPONENTE CUIDADOS PROPIOS DE LA EDAD A PERSONAS DE OTRO HOGAR FAMILIAR
****************************************************************************/

gen cuidados_otro_hogar = horas_cui_menores + horas_cui_adultos + horas_adultos_mayores
svy:mean cuidados_otro_hogar if p6_16_4 == 1 | p6_16_5 == 1 | p6_16_6 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 2.O: TDNR - APOYO A HOGARES NO FAMILIARES
  1. Actividades o servicios gratuitos para hogares de amistades/otros (p6_17a_1_1 a p6_17a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_17a_1_1 p6_17a_1_2 p6_17a_1_3 p6_17a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_apoyo_no_fam_lv = 0
gen horas_apoyo_no_fam_sd = 0

capture confirm variable p6_17a_1_1 p6_17a_1_2 p6_17a_1_3 p6_17a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_apoyo_no_fam_lv = p6_17a_1_1 + (p6_17a_1_2 / 60) if !missing(p6_17a_1_1, p6_17a_1_2)
    // Sábado y Domingo
    replace horas_apoyo_no_fam_sd = p6_17a_1_3 + (p6_17a_1_4 / 60) if !missing(p6_17a_1_3, p6_17a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_apoyo_no_fam_tot = horas_apoyo_no_fam_lv + horas_apoyo_no_fam_sd

/****************************************************************************
  Actividad 2.O: TDNR - TRABAJO VOLUNTARIO INSTITUCIONAL
  2. Actividades o servicios gratuitos como voluntariado (p6_17a_2_1 a p6_17a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_17a_2_1 p6_17a_2_2 p6_17a_2_3 p6_17a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_voluntariado_inst_lv = 0
gen horas_voluntariado_inst_sd = 0

capture confirm variable p6_17a_2_1 p6_17a_2_2 p6_17a_2_3 p6_17a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_voluntariado_inst_lv = p6_17a_2_1 + (p6_17a_2_2 / 60) if !missing(p6_17a_2_1, p6_17a_2_2)
    // Sábado y Domingo
    replace horas_voluntariado_inst_sd = p6_17a_2_3 + (p6_17a_2_4 / 60) if !missing(p6_17a_2_3, p6_17a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_voluntariado_inst_tot = horas_voluntariado_inst_lv + horas_voluntariado_inst_sd

/****************************************************************************
  Actividad 2.O: TDNR - TRABAJO COMUNITARIO Y VOLUNTARIO
  3. Actividades o servicios gratuitos para la comunidad (p6_17a_3_1 a p6_17a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_17a_3_1 p6_17a_3_2 p6_17a_3_3 p6_17a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_comunitario_lv = 0
gen horas_comunitario_sd = 0

capture confirm variable p6_17a_3_1 p6_17a_3_2 p6_17a_3_3 p6_17a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_comunitario_lv = p6_17a_3_1 + (p6_17a_3_2 / 60) if !missing(p6_17a_3_1, p6_17a_3_2)
    // Sábado y Domingo
    replace horas_comunitario_sd = p6_17a_3_3 + (p6_17a_3_4 / 60) if !missing(p6_17a_3_3, p6_17a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_comunitario_tot = horas_comunitario_lv + horas_comunitario_sd

/****************************************************************************
COMPONENTE TRABAJO NO REMUNERADO COMO APOYO A HOGARES NO 
FAMILIARES, VOLUNTARIADO Y TRABAJO COMUNITARIO
****************************************************************************/

gen trabajo_otroh_comunvolun = horas_apoyo_no_fam_tot + horas_voluntariado_inst_tot + horas_comunitario_tot
svy:mean trabajo_otroh_comunvolun if p6_17_1 == 1 | p6_17_2 == 1 | p6_17_3 == 1

/* Nos da el mismo resultado que INEGI */


/****************************************************************************
BLOQUE DE ACTIVIDADES DE CONVIVENCIA Y ENTRETENIMIENTO:
****************************************************************************/

/****************************************************************************
  Actividad 3.A: CONVIVENCIA Y ENTRETENIMIENTO
  1. Hacer deporte o ejercicio físico (p6_18a_1 a p6_18a_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_18a_1 p6_18a_2 p6_18a_3 p6_18a_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
// Nota: P6.18A consolida Horas LV/SD y Minutos LV/SD en 4 variables
// p6_18a_1: Horas L-V; p6_18a_2: Minutos L-V
// p6_18a_3: Horas S-D; p6_18a_4: Minutos S-D
gen horas_deporte_lv = 0
gen horas_deporte_sd = 0

capture confirm variable p6_18a_1 p6_18a_2 p6_18a_3 p6_18a_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_deporte_lv = p6_18a_1 + (p6_18a_2 / 60) if !missing(p6_18a_1, p6_18a_2)
    // Sábado y Domingo
    replace horas_deporte_sd = p6_18a_3 + (p6_18a_4 / 60) if !missing(p6_18a_3, p6_18a_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_deporte_totales = horas_deporte_lv + horas_deporte_sd

svy:mean horas_deporte_totales if p6_18 == 1
/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 3.B: CONVIVENCIA Y ENTRETENIMIENTO
  1. Realizar actividades artísticas o culturales (p6_19a_1_1 a p6_19a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_19a_1_1 p6_19a_1_2 p6_19a_1_3 p6_19a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
// p6_19a_1_1: Horas L-V; p6_19a_1_2: Minutos L-V
// p6_19a_1_3: Horas S-D; p6_19a_1_4: Minutos S-D
gen horas_artisticas_lv = 0
gen horas_artisticas_sd = 0

capture confirm variable p6_19a_1_1 p6_19a_1_2 p6_19a_1_3 p6_19a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_artisticas_lv = p6_19a_1_1 + (p6_19a_1_2 / 60) if !missing(p6_19a_1_1, p6_19a_1_2)
    // Sábado y Domingo
    replace horas_artisticas_sd = p6_19a_1_3 + (p6_19a_1_4 / 60) if !missing(p6_19a_1_3, p6_19a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_artisticas_totales = horas_artisticas_lv + horas_artisticas_sd

/****************************************************************************
  Actividad 3.B: CONVIVENCIA Y ENTRETENIMIENTO
  2. Participar en juegos de mesa o azar (p6_19a_2_1 a p6_19a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_19a_2_1 p6_19a_2_2 p6_19a_2_3 p6_19a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
// p6_19a_2_1: Horas L-V; p6_19a_2_2: Minutos L-V
// p6_19a_2_3: Horas S-D; p6_19a_2_4: Minutos S-D
gen horas_juegos_mesa_lv = 0
gen horas_juegos_mesa_sd = 0

capture confirm variable p6_19a_2_1 p6_19a_2_2 p6_19a_2_3 p6_19a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_juegos_mesa_lv = p6_19a_2_1 + (p6_19a_2_2 / 60) if !missing(p6_19a_2_1, p6_19a_2_2)
    // Sábado y Domingo
    replace horas_juegos_mesa_sd = p6_19a_2_3 + (p6_19a_2_4 / 60) if !missing(p6_19a_2_3, p6_19a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_juegos_mesa_totales = horas_juegos_mesa_lv + horas_juegos_mesa_sd

/****************************************************************************
COMPONENTE:  PARTICIPACION EN JUEGOS 
Y AFICIONES
****************************************************************************/

gen horas_juegos_aficiones = horas_artisticas_totales + horas_juegos_mesa_totales
svy:mean horas_juegos_aficiones if p6_19_1 == 1 | p6_19_2 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 3.C: CONVIVENCIA Y ENTRETENIMIENTO
  1. Asistir a Estadios, Parques, Ferias u Otros (p6_20a_1_1 a p6_20a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_20a_1_1 p6_20a_1_2 p6_20a_1_3 p6_20a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_entretenimiento_lv = 0
gen horas_entretenimiento_sd = 0

capture confirm variable p6_20a_1_1 p6_20a_1_2 p6_20a_1_3 p6_20a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_entretenimiento_lv = p6_20a_1_1 + (p6_20a_1_2 / 60) if !missing(p6_20a_1_1, p6_20a_1_2)
    // Sábado y Domingo
    replace horas_entretenimiento_sd = p6_20a_1_3 + (p6_20a_1_4 / 60) if !missing(p6_20a_1_3, p6_20a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_entretenimiento_tot = horas_entretenimiento_lv + horas_entretenimiento_sd

svy:mean horas_entretenimiento_tot if p6_20_1 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 3.C: CONVIVENCIA Y ENTRETENIMIENTO
  2. Asistir al cine, museo, teatro y otros sitios culturales (p6_20a_2_1 a p6_20a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_20a_2_1 p6_20a_2_2 p6_20a_2_3 p6_20a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_cultura_lv = 0
gen horas_cultura_sd = 0

capture confirm variable p6_20a_2_1 p6_20a_2_2 p6_20a_2_3 p6_20a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_cultura_lv = p6_20a_2_1 + (p6_20a_2_2 / 60) if !missing(p6_20a_2_1, p6_20a_2_2)
    // Sábado y Domingo
    replace horas_cultura_sd = p6_20a_2_3 + (p6_20a_2_4 / 60) if !missing(p6_20a_2_3, p6_20a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_cultura_tot = horas_cultura_lv + horas_cultura_sd

svy:mean horas_cultura_tot if p6_20_2 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 3.D: CONVIVENCIA SOCIAL, PRÁCTICAS SOCIALES Y RELIGIOSAS
  1. Dedicar tiempo especial a integrantes del hogar para platicar (p6_21a_1_1 a p6_21a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_21a_1_1 p6_21a_1_2 p6_21a_1_3 p6_21a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_platicar_hogar_lv = 0
gen horas_platicar_hogar_sd = 0

capture confirm variable p6_21a_1_1 p6_21a_1_2 p6_21a_1_3 p6_21a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_platicar_hogar_lv = p6_21a_1_1 + (p6_21a_1_2 / 60) if !missing(p6_21a_1_1, p6_21a_1_2)
    // Sábado y Domingo
    replace horas_platicar_hogar_sd = p6_21a_1_3 + (p6_21a_1_4 / 60) if !missing(p6_21a_1_3, p6_21a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_platicar_hogar_tot = horas_platicar_hogar_lv + horas_platicar_hogar_sd

/****************************************************************************
  Actividad 3.D: CONVIVENCIA SOCIAL, PRÁCTICAS SOCIALES Y RELIGIOSAS
  2. Asistir o participar en actividades o celebraciones religiosas (p6_21a_2_1 a p6_21a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_21a_2_1 p6_21a_2_2 p6_21a_2_3 p6_21a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_religiosas_lv = 0
gen horas_religiosas_sd = 0

capture confirm variable p6_21a_2_1 p6_21a_2_2 p6_21a_2_3 p6_21a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_religiosas_lv = p6_21a_2_1 + (p6_21a_2_2 / 60) if !missing(p6_21a_2_1, p6_21a_2_2)
    // Sábado y Domingo
    replace horas_religiosas_sd = p6_21a_2_3 + (p6_21a_2_4 / 60) if !missing(p6_21a_2_3, p6_21a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_religiosas_tot = horas_religiosas_lv + horas_religiosas_sd

/****************************************************************************
  Actividad 3.D: CONVIVENCIA SOCIAL, PRÁCTICAS SOCIALES Y RELIGIOSAS
  3. Asistir o participar en celebraciones cívicas o políticas (p6_21a_3_1 a p6_21a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_21a_3_1 p6_21a_3_2 p6_21a_3_3 p6_21a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_civicas_lv = 0
gen horas_civicas_sd = 0

capture confirm variable p6_21a_3_1 p6_21a_3_2 p6_21a_3_3 p6_21a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_civicas_lv = p6_21a_3_1 + (p6_21a_3_2 / 60) if !missing(p6_21a_3_1, p6_21a_3_2)
    // Sábado y Domingo
    replace horas_civicas_sd = p6_21a_3_3 + (p6_21a_3_4 / 60) if !missing(p6_21a_3_3, p6_21a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_civicas_tot = horas_civicas_lv + horas_civicas_sd

/****************************************************************************
  Actividad 3.D: CONVIVENCIA SOCIAL, PRÁCTICAS SOCIALES Y RELIGIOSAS
  4. Conversar, Reunirse con Amigos/Familiares, o Asistir a Fiestas (p6_21a_4_1 a p6_21a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_21a_4_1 p6_21a_4_2 p6_21a_4_3 p6_21a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_reuniones_lv = 0
gen horas_reuniones_sd = 0

capture confirm variable p6_21a_4_1 p6_21a_4_2 p6_21a_4_3 p6_21a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_reuniones_lv = p6_21a_4_1 + (p6_21a_4_2 / 60) if !missing(p6_21a_4_1, p6_21a_4_2)
    // Sábado y Domingo
    replace horas_reuniones_sd = p6_21a_4_3 + (p6_21a_4_4 / 60) if !missing(p6_21a_4_3, p6_21a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_reuniones_tot = horas_reuniones_lv + horas_reuniones_sd

/****************************************************************************
  COMPONENTE: CONVIVENCIA FAMILIAR Y SOCIAL
****************************************************************************/

gen horas_covivencia_famsoc = horas_platicar_hogar_tot + horas_religiosas_tot + horas_civicas_tot + horas_reuniones_tot
svy:mean horas_covivencia_famsoc if p6_21_1 == 1 | p6_21_2 == 1 | p6_21_3 == 1 | p6_21_4 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  1. Ver Películas, Novelas, Series o Programas (p6_22a_1_1 a p6_22a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_1_1 p6_22a_1_2 p6_22a_1_3 p6_22a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_pelis_series_lv = 0
gen horas_pelis_series_sd = 0

capture confirm variable p6_22a_1_1 p6_22a_1_2 p6_22a_1_3 p6_22a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_pelis_series_lv = p6_22a_1_1 + (p6_22a_1_2 / 60) if !missing(p6_22a_1_1, p6_22a_1_2)
    // Sábado y Domingo
    replace horas_pelis_series_sd = p6_22a_1_3 + (p6_22a_1_4 / 60) if !missing(p6_22a_1_3, p6_22a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_pelis_ser_tot = horas_pelis_series_lv + horas_pelis_series_sd

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  2. Escuchar Música, Noticias, Programas de Radio (p6_22a_2_1 a p6_22a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_2_1 p6_22a_2_2 p6_22a_2_3 p6_22a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_musica_noticias_lv = 0
gen horas_musica_noticias_sd = 0

capture confirm variable p6_22a_2_1 p6_22a_2_2 p6_22a_2_3 p6_22a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_musica_noticias_lv = p6_22a_2_1 + (p6_22a_2_2 / 60) if !missing(p6_22a_2_1, p6_22a_2_2)
    // Sábado y Domingo
    replace horas_musica_noticias_sd = p6_22a_2_3 + (p6_22a_2_4 / 60) if !missing(p6_22a_2_3, p6_22a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_musica_noticias_totales = horas_musica_noticias_lv + horas_musica_noticias_sd

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  3. Leer Revista, Libro, Periódico o Artículo Digital (p6_22a_3_1 a p6_22a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_3_1 p6_22a_3_2 p6_22a_3_3 p6_22a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_lectura_digital_lv = 0
gen horas_lectura_digital_sd = 0

capture confirm variable p6_22a_3_1 p6_22a_3_2 p6_22a_3_3 p6_22a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_lectura_digital_lv = p6_22a_3_1 + (p6_22a_3_2 / 60) if !missing(p6_22a_3_1, p6_22a_3_2)
    // Sábado y Domingo
    replace horas_lectura_digital_sd = p6_22a_3_3 + (p6_22a_3_4 / 60) if !missing(p6_22a_3_3, p6_22a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_lectura_digital_tot = horas_lectura_digital_lv + horas_lectura_digital_sd

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  4. Entretenerse a Través de Redes Sociales SIN PAGO DE POR MEDIO (p6_22a_4_1 a p6_22a_4_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_4_1 p6_22a_4_2 p6_22a_4_3 p6_22a_4_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_redes_sociales_lv = 0
gen horas_redes_sociales_sd = 0

capture confirm variable p6_22a_4_1 p6_22a_4_2 p6_22a_4_3 p6_22a_4_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_redes_sociales_lv = p6_22a_4_1 + (p6_22a_4_2 / 60) if !missing(p6_22a_4_1, p6_22a_4_2)
    // Sábado y Domingo
    replace horas_redes_sociales_sd = p6_22a_4_3 + (p6_22a_4_4 / 60) if !missing(p6_22a_4_3, p6_22a_4_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_redes_sociales_totales = horas_redes_sociales_lv + horas_redes_sociales_sd

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  5. Consultar Correo Electrónico o Redes Sociales (p6_22a_5_1 a p6_22a_5_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_5_1 p6_22a_5_2 p6_22a_5_3 p6_22a_5_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_correo_redes_lv = 0
gen horas_correo_redes_sd = 0

capture confirm variable p6_22a_5_1 p6_22a_5_2 p6_22a_5_3 p6_22a_5_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_correo_redes_lv = p6_22a_5_1 + (p6_22a_5_2 / 60) if !missing(p6_22a_5_1, p6_22a_5_2)
    // Sábado y Domingo
    replace horas_correo_redes_sd = p6_22a_5_3 + (p6_22a_5_4 / 60) if !missing(p6_22a_5_3, p6_22a_5_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_correo_redes_tot = horas_correo_redes_lv + horas_correo_redes_sd

/****************************************************************************
  Actividad 3.E: CONVIVENCIA Y ENTRETENIMIENTO - USO DE MEDIOS
  6. Usar Internet para Descargar/Consultar (Fines Recreativos) (p6_22a_6_1 a p6_22a_6_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_22a_6_1 p6_22a_6_2 p6_22a_6_3 p6_22a_6_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_internet_recreativo_lv = 0
gen horas_internet_recreativo_sd = 0

capture confirm variable p6_22a_6_1 p6_22a_6_2 p6_22a_6_3 p6_22a_6_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_internet_recreativo_lv = p6_22a_6_1 + (p6_22a_6_2 / 60) if !missing(p6_22a_6_1, p6_22a_6_2)
    // Sábado y Domingo
    replace horas_internet_recreativo_sd = p6_22a_6_3 + (p6_22a_6_4 / 60) if !missing(p6_22a_6_3, p6_22a_6_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_internet_recrea_tot = horas_internet_recreativo_lv + horas_internet_recreativo_sd

/****************************************************************************
COMPONENTE: UTILIZACIÓN DE MEDIOS MASIVOS DE COMUNICACIÓN
****************************************************************************/
 gen horas_medios_tot = horas_pelis_ser_tot + horas_musica_noticias_totales + horas_lectura_digital_tot + horas_redes_sociales_totales + ///
horas_correo_redes_tot + horas_internet_recrea_tot
 svy:mean horas_medios_tot if p6_22_1 == 1 | p6_22_2 == 1 | p6_22_3 == 1 | p6_22_4 == 1 | p6_22_5 == 1 | p6_22_6 == 1
 
 /* Nos da el mismo rsultado que INEGI */
 
 /****************************************************************************
  Actividad 4.A: AUTOCUIDADO Y TIEMPO PERSONAL
  1. Rezar, Meditar o Descansar (p6_23a_1_1 a p6_23a_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_23a_1_1 p6_23a_1_2 p6_23a_1_3 p6_23a_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_rezar_meditar_descansar_lv = 0
gen horas_rezar_meditar_descansar_sd = 0

capture confirm variable p6_23a_1_1 p6_23a_1_2 p6_23a_1_3 p6_23a_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_rezar_meditar_descansar_lv = p6_23a_1_1 + (p6_23a_1_2 / 60) if !missing(p6_23a_1_1, p6_23a_1_2)
    // Sábado y Domingo
    replace horas_rezar_meditar_descansar_sd = p6_23a_1_3 + (p6_23a_1_4 / 60) if !missing(p6_23a_1_3, p6_23a_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_rezar_meditar_desc_tot = horas_rezar_meditar_descansar_lv + horas_rezar_meditar_descansar_sd
svy:mean horas_rezar_meditar_desc_tot if p6_23_1 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 4.A: AUTOCUIDADO Y TIEMPO PERSONAL
  2. Recibir Atención de Salud, Terapia o Recuperación (p6_23a_2_1 a p6_23a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_23a_2_1 p6_23a_2_2 p6_23a_2_3 p6_23a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_atencion_salud_lv = 0
gen horas_atencion_salud_sd = 0

capture confirm variable p6_23a_2_1 p6_23a_2_2 p6_23a_2_3 p6_23a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_atencion_salud_lv = p6_23a_2_1 + (p6_23a_2_2 / 60) if !missing(p6_23a_2_1, p6_23a_2_2)
    // Sábado y Domingo
    replace horas_atencion_salud_sd = p6_23a_2_3 + (p6_23a_2_4 / 60) if !missing(p6_23a_2_3, p6_23a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_atencion_salud_totales = horas_atencion_salud_lv + horas_atencion_salud_sd
svy:mean horas_atencion_salud_totales if p6_23_2 == 1

/* Nos da el mismo resultado que INEGI */

/****************************************************************************
  Actividad 4.A: AUTOCUIDADO Y TIEMPO PERSONAL
  3. Dormir (p6_1_1_1 a p6_1_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_1_1_1 p6_1_1_2 p6_1_1_3 p6_1_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_dormir_lv = 0
gen horas_dormir_sd = 0

capture confirm variable p6_1_1_1 p6_1_1_2 p6_1_1_3 p6_1_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_dormir_lv = p6_1_1_1 + (p6_1_1_2 / 60) if !missing(p6_1_1_1, p6_1_1_2)
    // Sábado y Domingo
    replace horas_dormir_sd = p6_1_1_3 + (p6_1_1_4 / 60) if !missing(p6_1_1_3, p6_1_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_dormir_totales = horas_dormir_lv + horas_dormir_sd
svy:mean horas_dormir_totales

/****************************************************************************
  Actividad 4.A: AUTOCUIDADO Y TIEMPO PERSONAL
  4. Comer (p6_1_2_1 a p6_1_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_1_2_1 p6_1_2_2 p6_1_2_3 p6_1_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_comer_lv = 0
gen horas_comer_sd = 0

capture confirm variable p6_1_2_1 p6_1_2_2 p6_1_2_3 p6_1_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_comer_lv = p6_1_2_1 + (p6_1_2_2 / 60) if !missing(p6_1_2_1, p6_1_2_2)
    // Sábado y Domingo
    replace horas_comer_sd = p6_1_2_3 + (p6_1_2_4 / 60) if !missing(p6_1_2_3, p6_1_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_comer_totales = horas_comer_lv + horas_comer_sd
svy:mean horas_comer_totales

/****************************************************************************
  Actividad 4.A: AUTOCUIDADO Y TIEMPO PERSONAL
  5. Aseo Personal (p6_1_3_1 a p6_1_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_1_3_1 p6_1_3_2 p6_1_3_3 p6_1_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_aseo_propio_lv = 0
gen horas_aseo_propio_sd = 0

capture confirm variable p6_1_3_1 p6_1_3_2 p6_1_3_3 p6_1_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_aseo_propio_lv = p6_1_3_1 + (p6_1_3_2 / 60) if !missing(p6_1_3_1, p6_1_3_2)
    // Sábado y Domingo
    replace horas_aseo_propio_sd = p6_1_3_3 + (p6_1_3_4 / 60) if !missing(p6_1_3_3, p6_1_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_aseo_totales = horas_aseo_propio_lv + horas_aseo_propio_sd
svy:mean horas_aseo_totales

/****************************************************************************
  Actividad 4.B: ESTUDIO
  1. Clases Presenciales (p6_2a_1_1_1 a p6_2a_1_1_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_2a_1_1_1 p6_2a_1_1_2 p6_2a_1_1_3 p6_2a_1_1_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_clases_pres_lv = 0
gen horas_clases_pres_sd = 0

capture confirm variable p6_2a_1_1_1 p6_2a_1_1_2 p6_2a_1_1_3 p6_2a_1_1_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_clases_pres_lv = p6_2a_1_1_1 + (p6_2a_1_1_2 / 60) if !missing(p6_2a_1_1_1, p6_2a_1_1_2)
    // Sábado y Domingo
    replace horas_clases_pres_sd = p6_2a_1_1_3 + (p6_2a_1_1_4 / 60) if !missing(p6_2a_1_1_3, p6_2a_1_1_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_clases_pres_totales = horas_clases_pres_lv + horas_clases_pres_sd

/****************************************************************************
  Actividad 4.B: ESTUDIO
  2. Clases en Línea (p6_2a_1_2_1 a p6_2a_1_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_2a_1_2_1 p6_2a_1_2_2 p6_2a_1_2_3 p6_2a_1_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_clases_online_lv = 0
gen horas_clases_online_sd = 0

capture confirm variable p6_2a_1_2_1 p6_2a_1_2_2 p6_2a_1_2_3 p6_2a_1_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_clases_online_lv = p6_2a_1_2_1 + (p6_2a_1_2_2 / 60) if !missing(p6_2a_1_2_1, p6_2a_1_2_2)
    // Sábado y Domingo
    replace horas_clases_online_sd = p6_2a_1_2_3 + (p6_2a_1_2_4 / 60) if !missing(p6_2a_1_2_3, p6_2a_1_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_clases_online_totales = horas_clases_online_lv + horas_clases_online_sd

/****************************************************************************
 COMPONENTE CLASES
****************************************************************************/

gen horas_clases_totales = horas_clases_pres_totales + horas_clases_online_totales 
svy:mean horas_clases_totales if p6_2_1 == 1 | p6_2_1a == 1 | p6_2_1a == 2 | p6_2_1a == 3

/* Nos da ligeramente por debajo de lo reportado por INEGI */

/****************************************************************************
  Actividad 4.B: ESTUDIO
  3. Hacer Tareas, Prácticas o Alguna Actividad de Estudio (p6_2a_2_1 a p6_2a_2_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_2a_2_1 p6_2a_2_2 p6_2a_2_3 p6_2a_2_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_tareas_lv = 0
gen horas_tareas_sd = 0

capture confirm variable p6_2a_2_1 p6_2a_2_2 p6_2a_2_3 p6_2a_2_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_tareas_lv = p6_2a_2_1 + (p6_2a_2_2 / 60) if !missing(p6_2a_2_1, p6_2a_2_2)
    // Sábado y Domingo
    replace horas_tareas_sd = p6_2a_2_3 + (p6_2a_2_4 / 60) if !missing(p6_2a_2_3, p6_2a_2_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_tareas_totales = horas_tareas_lv + horas_tareas_sd
svy:mean horas_tareas_totales if p6_2_2 == 1

/* Nos da ligeramente por debajo de lo reportado por INEGI */

/****************************************************************************
  Actividad 4.B: ESTUDIO
  4. Tiempo de Traslado a la Escuela (p6_2a_3_1 a p6_2a_3_4)
****************************************************************************/

// 1. Limpieza de variables específicas
foreach var in p6_2a_3_1 p6_2a_3_2 p6_2a_3_3 p6_2a_3_4 {
    capture confirm string variable `var'
    if _rc == 0 {
        // Limpieza y conversión a "0" si es string no numérico
        replace `var' = "0" if `var' == "b" | `var' == "" | `var' == "."
        capture destring `var', replace
    }
    // Asegura que missing sea 0
    replace `var' = 0 if missing(`var')
}


// 2. CÁLCULO DE HORAS POR DÍA DE LA SEMANA
gen horas_traslado_escuela_lv = 0
gen horas_traslado_escuela_sd = 0

capture confirm variable p6_2a_3_1 p6_2a_3_2 p6_2a_3_3 p6_2a_3_4
if _rc == 0 {
    // Lunes a Viernes
    replace horas_traslado_escuela_lv = p6_2a_3_1 + (p6_2a_3_2 / 60) if !missing(p6_2a_3_1, p6_2a_3_2)
    // Sábado y Domingo
    replace horas_traslado_escuela_sd = p6_2a_3_3 + (p6_2a_3_4 / 60) if !missing(p6_2a_3_3, p6_2a_3_4)
}

// 3. VARIABLE FINAL DEL COMPONENTE
gen horas_traslado_escuela_totales = horas_traslado_escuela_lv + horas_traslado_escuela_sd
svy:mean horas_traslado_escuela_totales if p6_2_3 == 1

/* Nos da ligeramente por debajo */


/****************************************************************************************************************
CONSTRUCCIÓN DE LAS VARIABLES PARA EL MODELO 
****************************************************************************************************************/

*--------------------------------------------------------------------*
* Cálculo de carga total de trabajo
*--------------------------------------------------------------------*

gen horas_trabajo_total = actividades_mercado + horas_tot_tdnr_prop_hog + horas_totales_cuidados + trabajo_otroh_comunvolun

*--------------------------------------------------------------------*
* 1) Medidas relativas (Covarrubias 2019, p.8)
*--------------------------------------------------------------------*
sum horas_trabajo_total, detail
local mediana = r(p50)

* Pobreza R: 1.5 × mediana
local umbral_R = `mediana' * 1.5
gen pobreza_R = horas_trabajo_total > `umbral_R'

* Pobreza E: 2 × mediana
local umbral_E = `mediana' * 2
gen pobreza_E = horas_trabajo_total > `umbral_E'

*--------------------------------------------------------------------*
* 2) Medida absoluta (Pobreza V)
*--------------------------------------------------------------------*
* Tiempo disponible = 168 - carga total de trabajo
gen tiempo_disponible = 168 - horas_trabajo_total
gen pobreza_V = tiempo_disponible < 81

gen year = 1
label values year year_lbl
save "TMODULO_2024_pooled_temp.dta", replace
*--------------------------------------------------------------------*
* 3) Modelo LOGIT
*--------------------------------------------------------------------*
// 3.1) DISEÑO MUESTRAL
svyset upm [pweight=fac_per], strata(est_dis)

// 3.2) MODELOS LOGIT AJUSTADOS (svy)
svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_R

svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_V

svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estimates store M_E

// 3.3) EFECTOS MARGINALES / PROBABILIDADES (svy)
est restore M_E
margins sexo, predict(pr)
margins, dydx(sexo)
margins sexo#p4_4, predict(pr)
margins tloc, predict(pr)

// 3.4) INTERACCIONES (E como ejemplo)
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
estimates store M_E_cony
svy: logit pobreza_E i.sexo##i.tloc  i.edad_v i.niv i.p4_4 i.p4_5
estimates store M_E_loc

// 3.5) Ajuste por cada modelo derivado de que lroc es para stata 16.
*** Estimamos los modelos de manera individual con su estat gof:

svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 

svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 

svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
estat gof, group(10) 

/* Para el modelo de Pobreza_R se obtiene un  P-value de 0.8327 por lo que el modelo está bien específicado. */
/* Para el modelo de Pobreza_V se obtiene un P.Value de 0.4943 po lo que el modelo esta bien especificado */
/* Para el modelo de Pobreza_E se obtiene un P.Value de 0.9484 por lo que el modelo esta bien especificado */

/* Modelos alternativos */
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
estat gof, group(10) 
/* Se obtiene un  P-value de 0.9017 por lo que el modelo está bien específicado. */

svy: logit pobreza_E i.sexo##i.tloc  i.edad_v i.niv i.p4_4 i.p4_5
estat gof, group(10) 
/* Se obtiene un  P-value de 0.9426 por lo que el modelo está bien específicado. */

// (Opcional) si está instalado spost13, se puede usar:
// fitstat

// ----------------------------------------------------------
// Notas:
// - pobreza_R: 1.5× mediana semanal de horas trabajadas totales
// - pobreza_V: menos de 81 horas semanales de tiempo disponible
// - pobreza_E: 2× mediana semanal de horas trabajadas totales
// - Variables de control: sexo, edad (categorías), nivel educativo,
//   estado conyugal, hijos, tamaño de localidad.
// ----------------------------------------------------------

// ----------------------------------------------------------
// EXPORTACIÓN AUTOMÁTICA DE TABLAS Y GRÁFICAS
// Requisitos: outreg2 (SSC) o estout (esttab) y marginsplot
// Crea carpeta /output y guarda tablas (.doc/.csv) y gráficas (.png)
// ----------------------------------------------------------

capture noisily which outreg2
if _rc {
    di as text "Instalando outreg2 desde SSC..."
    ssc install outreg2, replace
}
capture noisily which esttab
if _rc {
    di as text "Instalando estout (esttab) desde SSC..."
    ssc install estout, replace
}
capture noisily which parmest
if _rc {
    di as text "Instalando parmest desde SSC..."
    ssc install parmest, replace
}
capture noisily which somersd
if _rc {
	di as text "Instalando somersd desde SSC..."
	ssc install somersd, replace
}
 capture noisily which lroc
if _rc {
	di as text "Instalando lroc desde SSC..."
	ssc install lroc, replace
}

// 1) Carpeta de salida
cap mkdir "output"

// 2) Reestimar y almacenar modelos (si no se han almacenado)
capture confirm estimate M_R
if _rc { 
    svy: logit pobreza_R i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_R 
}

capture confirm estimate M_V
if _rc { 
    svy: logit pobreza_V i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_V 
}

capture confirm estimate M_E
if _rc { 
    svy: logit pobreza_E i.sexo i.edad_v i.niv i.p4_4 i.p4_5 i.tloc
    estimates store M_E 
}
* Nuevos modelos con interacciones
capture confirm estimate M_E_cony
if _rc { 
    svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc
    estimates store M_E_cony 
}

capture confirm estimate M_E_loc
if _rc { 
    svy: logit pobreza_E i.sexo##i.tloc i.edad_v i.niv i.p4_4 i.p4_5
    estimates store M_E_loc 
}

// 3) Tablas con outreg2 (OR, IC95%, p-val)
outreg2 [M_R M_V M_E] using "output/resultados_logit.doc", ///
    replace ctitle("Modelo R" "Modelo V" "Modelo E") eform dec(2) ///
    alpha(0.1, 0.05, 0.01) addstat("Pseudo-R2", e(r2_p)) ///
    title("Resultados Logit (Odds Ratios)") label
	
outreg2 [M_R M_V M_E] using "output/resultados_logit.doc", ///
    replace ctitle("Modelo R" "Modelo V" "Modelo E") eform dec(2) ///
    alpha(0.1, 0.05, 0.01) title("Resultados Logit (Odds Ratios)") label


// 3b) Alternativa con esttab (si se prefiere .csv)
esttab M_R M_V M_E using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes // Sólo para Stata 16
	
esttab M_R M_V M_E using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes

esttab M_R M_V M_E using "output/resultados_logit_pvalues.csv", replace ///
    eform wide b(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, p-valores)") nonotes
/* Para resultados completos */
esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit.csv", replace ///
    eform wide b(2) ci(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes // Sólo para Stata 16
	
esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit_completos.csv", replace ///
    eform wide b(2) ci(2) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, IC95)") nonotes

esttab M_R M_V M_E M_E_cony M_E_loc using "output/resultados_logit_pvalues_completos.csv", replace ///
    eform wide b(2) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Resultados Logit (OR, p-valores)") nonotes
	
// 4) Indicadores de ajuste: AUC y matriz de clasificación por modelo
// Se exportan como PNG (gráficas) y TXT (resumen)
tempname fh
file open `fh' using "output/ajuste_resumen.txt", text write replace

// Modelo R
est restore M_R
lroc
graph export "output/roc_R.png", replace width(2000)
quietly estat classification
return list
file write `fh' "=== Modelo R ===" _n
file write `fh' "AUC (ver roc_R.png). Ver detalles en resultados de Stata." _n
// Modelo V
est restore M_V
lroc
graph export "output/roc_V.png", replace width(2000)
quietly estat classification
file write `fh' "=== Modelo V ===" _n
file write `fh' "AUC (ver roc_V.png). Ver detalles en resultados de Stata." _n
// Modelo E
est restore M_E
lroc
graph export "output/roc_E.png", replace width(2000)
quietly estat classification
file write `fh' "=== Modelo E ===" _n
file write `fh' "AUC (ver roc_E.png). Ver detalles en resultados de Stata." _n

file close `fh'

// 4.1) Otra alternativa si lo anterior no corre: 

// Modelo R
est restore M_R
predict p_R
roctab pobreza_R p_R [pweight=peso], graph
graph export "output/roc_R.png", replace width(2000)
local auc_R = r(area)
di "AUC Modelo R: `auc_R'"
drop p_R

// Modelo V  
est restore M_V
predict p_V
roctab pobreza_V p_V [pweight=peso], graph
graph export "output/roc_V.png", replace width(2000)
local auc_V = r(area)
di "AUC Modelo V: `auc_V'"
drop p_V

// Modelo E
est restore M_E
predict p_E
roctab pobreza_E p_E [pweight=peso], graph
graph export "output/roc_E.png", replace width(2000)
local auc_E = r(area)
di "AUC Modelo E: `auc_E'"
drop p_E

**** Sin pweights. Para Stata 15

// Modelo R
est restore M_R
predict phat_R if e(sample), pr
roctab pobreza_R phat_R, graph
graph export "output/roc_R.png", replace width(2000)

// Modelo V
est restore M_V
predict phat_V if e(sample), pr
roctab pobreza_V phat_V, graph
graph export "output/roc_V.png", replace width(2000)

// Modelo E
est restore M_E
predict phat_E if e(sample), pr
roctab pobreza_E phat_E, graph
graph export "output/roc_E.png", replace width(2000)

// 5) Probabilidades predichas y márgenes (sexo, conyugalidad, localidad)
est restore M_E
margins sexo, predict(pr)
marginsplot, recastci(rarea) title("Figura 1: Probabilidad predicha por sexo (E)") ///
    name(g_sexo_E, replace)
graph export "output/prob_sexo_E.png", replace width(2000)

margins sexo#p4_4, predict(pr)
marginsplot, recastci(rarea) title("Figura 2: Probabilidad por sexo x conyugalidad (E)") ///
    name(g_sexo_cony_E, replace)
graph export "output/prob_sexo_cony_E.png", replace width(2000)

margins tloc, predict(pr)
marginsplot, recastci(rarea) title("Figura 3: Probabilidad por tamaño de localidad (E)") ///
    name(g_loc_E, replace)
graph export "output/prob_localidad_E.png", replace width(2000)

// 6) Exportar márgenes a CSV para reproducibilidad
// Sexo
// Exportar márgenes a CSV (parmest)
margins, dydx(sexo) post
parmest, saving("output/margins_dydx_sexo_E.dta", replace)
preserve
use "output/margins_dydx_sexo_E.dta", clear
export delimited using "output/margins_dydx_sexo_E.csv", replace
restore

est restore M_E
margins sexo, post
parmest, saving("output/margins_sexo_levels_E.dta", replace)
preserve
use "output/margins_sexo_levels_E.dta", clear
export delimited using "output/margins_sexo_levels_E.csv", replace
restore

di as result "Exportación completa. Revise la carpeta /output."

// Otra alternativa por si no corre: Efectos marginales para sexo (dydx)
margins, dydx(sexo) post
parmest, saving("output/margins_dydx_sexo_E.dta", replace)
preserve
use "output/margins_dydx_sexo_E.dta", clear
export delimited using "output/margins_dydx_sexo_E.csv", replace
restore

// Margins por niveles de sexo
est restore M_E
margins sexo, post
parmest, saving("output/margins_sexo_levels_E.dta", replace)
preserve
use "output/margins_sexo_levels_E.dta", clear
export delimited using "output/margins_sexo_levels_E.csv", replace
restore

di as result "Exportación completa. Revise la carpeta /output."

* === 1. Re-estimar modelo ===
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc

* === 2. Márgenes sexo × estado civil ===
margins sexo#p4_4, predict(pr)
margins, post
export delimited using "output/margins_sexo_p4_4.csv", replace

* === 3. Re-estimar modelo otra vez ===
svy: logit pobreza_E i.sexo##i.p4_4 i.edad_v i.niv i.p4_5 i.tloc

* === 4. Contrastes de estado civil dentro de sexo ===
margins r.p4_4, over(sexo)
margins, post
export delimited using "output/contrastes_sexo_p4_4.csv", replace

************************************************************************
* === 1. Re-estimar modelo Pobreza_E, Sexo y Localidad controlados=== *
svy: logit pobreza_E i.sexo##i.p4_4 i.sexo##i.tloc i.edad_v i.niv i.p4_5
est store M_E2

* === 2. Probabilidades predichas: Sexo x estado conyugal. ===*
margins sexo#p4_4, predict(pr)
marginsplot, xdimension(p4_4) by(sexo) ///
    title("Probabilidad de pobreza de tiempo extrema por sexo y estado conyugal") ///
    ytitle("Pr(pobreza_E)") xtitle("Estado conyugal")
graph export "output/prob_sexo_p4_4.png", replace width(2000)

margins sexo#p4_4
marginsplot, by(sexo) ///
    title("Probabilidad de Pobreza por Estado Conyugal") ///
    xtitle("Estado Conyugal") ///
    ytitle("Probabilidad de Pobreza") ///
    xlabel(1 "Soltero" 2 "Unión libre" 3 "Casado" 4 "Separado" 5 "Viudo" 6 "Divorciado", angle(45)) ///
    graphregion(color(white))


* === 3. Probabilidades predichas para sexo x tamaño localidad ===*
margins sexo#tloc, predict(pr)
marginsplot, xdimension(tloc) by(sexo) ///
    title("Probabilidad de pobreza de tiempo extrema por sexo y tipo de localidad") ///
    ytitle("Pr(pobreza_E)") xtitle("Tipo de localidad")
graph export "output/prob_sexo_tloc.png", replace width(2000)


* === 4. Contrastes de diferencias ====*
margins r.p4_4, over(sexo)
margins r.tloc, over(sexo)

margins r.tloc, over(sexo) saving("output/margins_tloc_sexo.dta", replace)
use "output/margins_tloc_sexo.dta", clear
export delimited using "output/margins_tloc_sexo.csv", replace


* ===========================
* Diagnóstico rápido pobreza de tiempo (E)
* ===========================

* 1. Revisar categorías base (por default la más baja, pero lo mostramos)
tabulate sexo
tabulate p4_4
tabulate tloc

* Opcional: definir explícitamente bases de referencia
fvset base 1 sexo   // 1 = hombres
fvset base 1 p4_4   // 1 = soltero
fvset base 1 tloc   // 1 = localidad pequeña

* 2. Distribución pobreza extrema por variables clave
tabulate pobreza_E sexo, row col
tabulate pobreza_E p4_4, row col
tabulate pobreza_E tloc, row col

* 3. Revisar combinaciones sexo × conyugalidad
tabulate sexo p4_4 if e(sample), missing

* 4. Revisar combinaciones sexo × localidad
tabulate sexo tloc if e(sample), missing

* 5. Revisar combinaciones con el desenlace (pobreza extrema)
table sexo p4_4 pobreza_E
table sexo tloc pobreza_E

/* Podemos concuir que no hay perfect prediction, sin embargo, hay variables que muestran
cierto nivel de desbalance */

//----------------------------------------------------
// C. AGREGACIÓN (APPEND) Y CONFIGURACIÓN FINAL
// ----------------------------------------------------

// 1. Cargar la base de 2024 e incorporar la de 2019

use "TMODULO_2024_pooled_temp.dta", clear
append using "TMODULO_2019_pooled_temp.dta", force

// 3. Guardar el archivo final POOLED
save "TMODULO_POOLED_FINAL.dta", replace
export delimited using "TMODULO_POOLED_FINAL.csv", replace
// 4. Reestablecer el diseño muestral sobre la base combinada
// (Asegúrate de que 'upm' y 'fac_per' no tengan missing values después del append)
svyset upm [pweight=fac_per], strata(est_dis)

/****************************************************************************
  GENERACIÓN DE FIGURA (GRÁFICA DE BARRAS DE MEDIANA DE CTT)
****************************************************************************/

// 1. Guardar el estado actual (para no perder el diseño muestral)
preserve

// 2. Crear un nuevo dataset que contenga solo la mediana por subgrupo
// Nota: Usar mean o median (p50) directamente en el collapse
collapse (median) mediana_CTT=horas_trabajo_total [pweight=fac_per], by(year sexo tloc)

// 3. Crear el gráfico de barras comparando 2019 y 2024
graph bar mediana_CTT, over(tloc) by(year) stack ///
    title("Apéndice: Mediana de CTT por Sexo y Localidad (2019 vs 2024)") ///
    legend(label(1 "Hombre") label(2 "Mujer"))
    
// Exportar la figura
graph export "output/Apéndice_Figura_Mediana_CTT.png", replace width(2000)

/****************************************************************************
: MEDIANA CTT PONDERADA POR SUBGRUPO
****************************************************************************/

// 1. Crear una variable que combine los tres factores (Año x Sexo x tloc)
// Esto permite usar tabstat by() de manera compatible.
egen group_factor = group(year sexo tloc)

// 2. Ejecutar TABSTAT en la variable combinada
// Usamos el peso de analítico [aweight=fac_per] para calcular la mediana ponderada (p50)
tabstat horas_trabajo_total [aweight=fac_per], stats(median) by(group_factor)

ssc install tabout, replace

// 2. Ejecutar y Exportar la tabla de Medianas Ponderadas
// El comando tabout es más compatible que tabstat para la exportación de medianas por múltiples grupos.
tabout year sexo tloc using "output/Apéndice_Mediana_CTT_Final.csv", ///
    c(median horas_trabajo_total) sum replace ///
    f(1) clab("Mediana CTT (Horas Semanales)") ///
    bt
	
// 4. Regresar al dataset original
restore

/****************************************************************************
  EJECUCIÓN DEL MODELO LOGIT POOLED (M_POOL)
  Referencia: Año=2019 (0), Hombre (1), tloc=1, p4_4=1
****************************************************************************/

// 1. Definir la variable de conyugalidad para que tenga un factor base simple (p4_4=1 es soltero/sin pareja)
fvset base 1 p4_4

// 2. Ejecutar el modelo logit con las interacciones triples y cuádruples
// (Añadimos i.edad_v, i.niv, i.p4_5 como controles para mayor robustez, si están en la base)
svy: logit pobreza_R i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
estimates store M_R_POOL

svy: logit pobreza_V i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
estimates store M_V_POOL

svy: logit pobreza_E i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
estimates store M_POOL

// Cargamos de nuevo outreg2
ssc install outreg2, replace

// Ejecutar y exportar la Tabla 3 con Odds Ratios e Intervalos de Confianza
outreg2 [M_POOL] using "output/Tabla3_OR_IC95.doc", ///
    replace eform dec(3) ctitle("Pooled Logit Pobreza Extrema") ///
    alpha(0.10, 0.05, 0.01) symbol(†, *, **) label ///
    addstat("N (obs)", e(N)) title("Tabla 3. Modelo Combinado (Pooled) para Pobreza Extrema")
	
/****************************************************************************
TABLA 2.  (Ejemplo para POBREZA_E. Repetir para POBREZA_R y POBREZA_V)
****************************************************************************/

/****************************************************************************
CALCULAR PREVALENCIA (MARGENS) POR CELDA
****************************************************************************/
// POBREZA RELATIVA (R)
svy: logit pobreza_R i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
margins year#sexo#tloc, predict(pr) post
export delimited using "output/tabla2_prevalencia_R_data.csv", replace
contrast r.year@sexo@tloc
export delimited using "output/tabla2_deltapp_R_data.csv", replace

// POBREZA ABSOLUTA (V)
svy: logit pobreza_V i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
margins year#sexo#tloc, predict(pr) post
export delimited using "output/tabla2_prevalencia_V_data.csv", replace
contrast r.year@sexo@tloc
export delimited using "output/tabla2_deltapp_V_data.csv", replace


// POBREZA EXTREMA (E)
svy: logit pobreza_E i.year##i.sexo##i.tloc i.p4_4 i.edad_v i.niv i.p4_5
margins year#sexo#tloc, predict(pr) post
export delimited using "output/tabla2_prevalencia_E_data.csv", replace
contrast r.year@sexo@tloc
export delimited using "output/tabla2_deltapp_E_data.csv", replace
	
************************************************************
* FIGURA 1B – Sexo × Conyugalidad (2019 y 2024)
* Ruta: C:\Users\karla\OneDrive\Documentos\Modelo_Pobreza de tiempo
************************************************************
clear all
set more off
version 17

*==== 0) RUTA DE TRABAJO ====
cd "C:\Users\karla\OneDrive\Documentos\Modelo_Pobreza de tiempo"
capture mkdir "output"

*==== 1) CARGA/ARMA BASE POOLED ====
capture confirm file "TMODULO_POOLED_FINAL.dta"
if _rc {
    di as txt "No existe TMODULO_POOLED_FINAL.dta; se construye desde 2019 y 2024."

    * 2019
    use "TMODULO_2019_pooled_temp.dta", clear
    capture confirm variable year
    if _rc {
        local cand_year anio Año ANIO anio_encuesta
        local found ""
        foreach v of local cand_year {
            capture confirm variable `v'
            if !_rc local found `v'
        }
        if "`found'" != "" rename `found' year
        else gen year = 2019
    }
    replace year = 2019 if missing(year)
    tempfile base2019
    save `base2019'

    * 2024
    use "TMODULO_2024_pooled_temp.dta", clear
    capture confirm variable year
    if _rc {
        local cand_year anio Año ANIO anio_encuesta
        local found ""
        foreach v of local cand_year {
            capture confirm variable `v'
            if !_rc local found `v'
        }
        if "`found'" != "" rename `found' year
        else gen year = 2024
    }
    replace year = 2024 if missing(year)
    tempfile base2024
    save `base2024'

    * Append y guardar pooled
    use `base2019', clear
    append using `base2024'
    save "TMODULO_POOLED_FINAL.dta", replace
}
else {
    use "TMODULO_POOLED_FINAL.dta", clear
}

*==== 2) NORMALIZAR AÑO → year_num (2019/2024) ====
local cand_year year anio Año ANIO anio_encuesta
local yvar ""
foreach v of local cand_year {
    capture confirm variable `v'
    if !_rc local yvar `v'
}
if "`yvar'"=="" {
    di as error "Falta variable de año."; exit 111
}

capture drop year_num
capture confirm string variable `yvar'
if !_rc {
    destring `yvar', gen(year_num) force
}
else {
    gen year_num = `yvar'
    quietly count if inlist(year_num,2019,2024)
    if r(N)==0 {
        local vlab : value label `yvar'
        if "`vlab'"!="" {
            tempvar ytxt
            decode `yvar', gen(`ytxt')
            capture drop year_num
            destring `ytxt', gen(year_num) force
        }
        quietly levelsof year_num, local(ylv)
        if "`ylv'"=="1 2" {
            replace year_num = 2019 if year_num==1
            replace year_num = 2024 if year_num==2
        }
    }
}

tab year_num
keep if inlist(year_num,2019,2024)

*==== 3) VARIABLES CLAVE ====

* SEXO (1=Hombres, 2=Mujeres)
capture confirm variable sexo
if _rc di as error "Falta 'sexo'." 
if _rc exit 111
label define lbl_sexo 1 "Hombres" 2 "Mujeres", replace
label values sexo lbl_sexo
replace sexo = . if !inlist(sexo,1,2)

* CONYUGALIDAD por AÑO:
*   2019 -> p4_4 (1–6)
*   2024 -> p4_5 (1–6; 9 = NS/NR -> .)
capture drop cony
gen byte cony = .

capture confirm variable p4_4
if !_rc replace cony = p4_4 if year_num==2019 & inrange(p4_4,1,6)

capture confirm variable p4_5
if !_rc replace cony = p4_5 if year_num==2024 & inrange(p4_5,1,6)
if !_rc replace cony = .     if year_num==2024 & p4_5==9

* Seguridad adicional
replace cony = . if !inrange(cony,1,6)

* Etiquetas simples (ajusta si quieres textos completos)
capture label define lbl_cony 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6", replace
capture label values cony lbl_cony

* DEPENDIENTE (fijar explícitamente)
capture confirm variable pobreza_E
if _rc di as error "Falta la variable dependiente 'pobreza_E'." 
if _rc exit 111
local depvar pobreza_E

* Chequeo de observaciones
count if !missing(`depvar', sexo, cony, year_num)
if r(N)==0 di as error "Sin casos válidos (revise year_num/sexo/cony/pobreza_E)."
if r(N)==0 exit 2000

*==== 4) MODELO Y MÁRGENES (usar year_num) ====
capture noisily svy: logit `depvar' i.year_num##i.sexo##i.cony
if _rc {
    di as txt "Aviso: sin svyset; se estima logit simple."
    quietly logit `depvar' i.year_num##i.sexo##i.cony
}

margins i.year_num#i.sexo, over(cony) post

* Etiquetas limpias para los paneles
label define yearlbl 2019 "2019" 2024 "2024", replace
label values year_num yearlbl
label var year_num ""   // oculta el nombre de la variable en el encabezado

*==== GRÁFICO: 1 línea por sexo + barras de error, sin título ====
marginsplot,                                       ///
    xdimension(cony)                                ///
    plotdimension(sexo)                             ///
    bydimension(year_num)                           ///
    byopts(compact)                                 ///
    recast(scatter)                                 ///
    plot1opts(msymbol(Oh) connect(l) lwidth(medthick))  ///
    plot2opts(msymbol(Th) connect(l) lwidth(medthick))  ///
    ciopts(recast(rcap) lwidth(thin))               ///
    title("")                                       ///
    ytitle("Probabilidad (Pobreza E)", size(medlarge) margin(medium)) ///
    ylabel(0(.05).30, angle(0) format(%3.2f))       ///
    xtitle("Conyugalidad (1–6)", size(medlarge))    ///
    legend(order(1 "Hombres" 2 "Mujeres") col(1))   ///
    name(fig1B_sexoXcony, replace)

graph export "output/fig1B_sexoXcony_2019_2024.png", width(3000) replace





*================ FIGURA 1A – Sexo × TLOC (igual diseño que 1B) ================

* 0) Fijar TLOC
local tlocvar tloc   // ya confirmaste que es 'tloc' y es numérica 1–4

* (Opcional) Si quieres poner textos en el eje X, descomenta y edita:
* label define tloc_lbl 1 "1" 2 "2" 3 "3" 4 "4", replace
* label values `tlocvar' tloc_lbl

* 1) Modelo (svy si lo tienes; si no, logit simple)
capture noisily svy: logit pobreza_E i.year_num##i.sexo##i.`tlocvar'
if _rc {
    di as txt "Aviso: sin svyset; se estima logit simple."
    quietly logit pobreza_E i.year_num##i.sexo##i.`tlocvar'
}

* 2) Márgenes
margins i.year_num#i.sexo, over(`tlocvar') post

* 3) * Encabezados de panel limpios
label define yearlbl 2019 "2019" 2024 "2024", replace
label values year_num yearlbl
label var year_num ""   // oculta 'year_num=' en el encabezado

* Gráfico: 1 línea por sexo + barras de error, sin título
marginsplot, ///
    xdimension(tloc) ///
    plotdimension(sexo) ///
    bydimension(year_num) ///
    byopts(compact) ///
    recast(scatter) ///
    plot1opts(msymbol(Oh) connect(l) lwidth(medthick)) ///
    plot2opts(msymbol(Th) connect(l) lwidth(medthick)) ///
    ciopts(recast(rcap) lwidth(thin)) ///
    title("") ///
    ytitle("Probabilidad (Pobreza E)", size(medlarge) margin(medium)) ///
    ylabel(0(.05).30, angle(0) format(%3.2f)) ///
    xtitle("Tloc", size(medlarge)) ///
    legend(order(1 "Hombres" 2 "Mujeres") col(1)) ///
    name(fig1A_sexoXTLOC, replace)

graph export "output/fig1A_sexoXTLOC_2019_2024.png", width(3000) replace





*******************************************************
* TABLA 3. MODELO POOLED ENUT 2019–2024 (POBREZA EXTREMA E)
* Interacciones year×sexo y year×tloc, incluye conyugalidad
*******************************************************

clear all
set more off
capture mkdir "output"

*------------------------------------------------------
* 1. Cargar base POOLED FINAL
*------------------------------------------------------
use "TMODULO_POOLED_FINAL.dta", clear

*------------------------------------------------------
* 2. Crear variable de conyugalidad armonizada
*    Sin depender de cómo esté codificado 'year'
*    - p4_4 llena para un año
*    - p4_5 llena para el otro
*------------------------------------------------------
capture drop conyugalidad
gen byte conyugalidad = .

* Primero tomamos p4_4 donde exista
replace conyugalidad = p4_4 if !missing(p4_4)

* Luego, donde haya p4_5, la usamos (sobrescribe si aplica)
replace conyugalidad = p4_5 if !missing(p4_5)

label var conyugalidad "Condición conyugal armonizada 2019–2024"

* (Opcional) Ajusta estas etiquetas a tus códigos reales
* label define cony_lbl 1 "Unida/o" 2 "Soltera/o" 3 "Separada/o" 4 "Viuda/o"
* label values conyugalidad cony_lbl


*------------------------------------------------------
* 3. Chequeo rápido de que haya datos completos
*------------------------------------------------------
* Esto es solo para ver que sí queden observaciones válidas
count if !missing(pobreza_E, year, sexo, tloc, conyugalidad)
list pobreza_E year sexo tloc conyugalidad in 1/10

*------------------------------------------------------
* 4. Definir diseño muestral (si hace falta)
*    Usa las mismas variables que en tu do-file original.
*    Si el diseño ya viene guardado en el .dta, puedes dejar
*    esto comentado.
*------------------------------------------------------
* svyset upm [pweight = fac], strata(estrato)


*------------------------------------------------------
* 5. Modelo logístico pooled (pobreza extrema E)
*    - Dependiente: pobreza_E (E extrema)
*    - Interacciones: year×sexo y year×tloc
*    - Incluye conyugalidad en el modelo
*------------------------------------------------------
svy: logit pobreza_E ///
    i.year##i.sexo##i.tloc ///
    i.conyugalidad, or

* Esta salida (OR, IC95% y p-valores) es la base de la Tabla 3:
* "Modelo combinado (pooled) para E (extrema) con interacciones
*  year×sexo y year×tloc (e incluye conyugalidad)."


*******************************************************
* 6. PRUEBAS FORMALES (CAMBIO 2019–2024 Y GRADIENTE TERRITORIAL)
*******************************************************

* Guardar el modelo logístico estimado
estimates store mE

*------------------------------------------------------
* 6A. Cambio 2019–2024 por sexo (brecha de género)
*------------------------------------------------------
estimates restore mE
margins year#sexo, post
contrast r.year@sexo

* Nota importante:
* Si en los resultados ves muchos "." (not estimable),
* significa que en algunas combinaciones year×sexo no hay
* casos de pobreza extrema (todo 0), y por eso Stata no
* puede estimar la probabilidad ni el cambio 2019–2024.

*------------------------------------------------------
* 6B. Cambio 2019–2024 por tipo de localidad
*    (gradiente territorial en el tiempo)
*------------------------------------------------------
estimates restore mE
margins year#tloc, post
contrast r.year@tloc

*------------------------------------------------------
* 6C. Gradiente territorial por año
*    (diferencias entre tipos de localidad dentro de cada año)
*------------------------------------------------------
estimates restore mE
margins year#tloc, post
contrast r.tloc@year

* (Opcional: si quieres hacer algo más fino por sexo y año)
* estimates restore mE
* margins year#sexo#tloc, post
* contrast r.tloc@year#sexo
*******************************************************
* FIN BLOQUE TABLA 3
*******************************************************






*******************************************************
* DESEMPEÑO DEL MODELO POOLED (VERSIÓN NO-SVY)
* Pobreza extrema (pobreza_E)
*******************************************************

clear all
set more off

* 1. Cargar la base pooled final
use "TMODULO_POOLED_FINAL.dta", clear

* 2. Construir conyugalidad armonizada (igual que en el modelo svy)
capture drop conyugalidad
gen byte conyugalidad = .
replace conyugalidad = p4_4 if !missing(p4_4)
replace conyugalidad = p4_5 if !missing(p4_5)
label var conyugalidad "Condición conyugal armonizada 2019–2024"

* 3. Mantener sólo casos completos para este modelo
keep if !missing(pobreza_E, year, sexo, tloc, conyugalidad)

* (Opcional) Chequeo rápido
* tab pobreza_E
* tab year sexo
* tab tloc
* tab conyugalidad

*******************************************************
* 4. Modelo logístico SIN svy (misma especificación de Tabla 4)
*******************************************************
* Nota: SIN 'svy:' al inicio
logit pobreza_E ///
    i.year##i.sexo##i.tloc ///
    i.conyugalidad, or

* Aquí, en la salida:
* - Stata reporta el pseudo-R² (McFadden) al final
* - Los OR/IC95% deben ser muy similares a los de tu Tabla 4
*   (puede cambiar un poco por el diseño muestral vs no-svy)

*******************************************************
* 5. Pseudo-R², porcentaje de clasificación y AUC-ROC
*******************************************************

* 5.1. Pseudo-R² (McFadden) – lo tomas del modelo ya estimado
display "Pseudo-R2 (McFadden), no-svy = " %6.3f e(r2_p)

* 5.2. Porcentaje de clasificación (con punto de corte por defecto 0.5)
estat classification

* En 'estat classification' fíjate en:
* - 'Percent correctly classified' → % de clasificación total
* - También puedes mencionar sensitivity/specificity si quieres.

* 5.3. Curva ROC y AUC (área bajo la curva)
lroc, nograph
display "Área bajo la curva ROC (AUC), no-svy = " %6.3f e(roc_area)

* Si quieres guardar el modelo por si luego quieres más cosas:
estimates store mE_nosvy

*******************************************************
* FIN BLOQUE DESEMPEÑO NO-SVY
*******************************************************


