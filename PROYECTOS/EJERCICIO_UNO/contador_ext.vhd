-- =============================================================
-- Archivo  : contador_ext.vhd
-- Entidad  : contador_tiempo_extra
-- Desc     : Contador de tiempo extra de 00 a 99 segundos.
--            Se activa cuando habilitar = ocupado AND fin_conteo_35.
--            alarma = habilitar (encendida mientras hay tiempo extra).
--            Se congela exactamente en 99 con NULL.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY contador_tiempo_extra IS
    PORT (
        reloj_1hz : IN  STD_LOGIC;
        reset     : IN  STD_LOGIC;
        habilitar : IN  STD_LOGIC;
        unidades  : OUT INTEGER RANGE 0 TO 9;
        decenas   : OUT INTEGER RANGE 0 TO 9;
        alarma    : OUT STD_LOGIC
    );
END contador_tiempo_extra;

ARCHITECTURE comportamiento OF contador_tiempo_extra IS
    SIGNAL contador_unidades : INTEGER RANGE 0 TO 9;
    SIGNAL contador_decenas  : INTEGER RANGE 0 TO 9;
BEGIN

    proceso_contador_extra : PROCESS (reloj_1hz, reset)
    BEGIN
        IF (reset = '1') THEN
            contador_unidades <= 0;
            contador_decenas  <= 0;

        ELSIF (reloj_1hz'EVENT AND reloj_1hz = '1') THEN

            IF (habilitar = '1') THEN

                -- CASO 1: tope en 99, congelar
                IF (contador_decenas = 9 AND contador_unidades = 9) THEN
                    NULL;

                -- CASO 2: unidades llegan a 9 -> subir decenas
                ELSIF (contador_unidades = 9) THEN
                    contador_unidades <= 0;
                    contador_decenas  <= contador_decenas + 1;

                -- CASO 3: incremento normal
                ELSE
                    contador_unidades <= contador_unidades + 1;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    unidades <= contador_unidades;
    decenas  <= contador_decenas;

    -- alarma: activa mientras hay tiempo extra corriendo
    alarma <= habilitar;

END comportamiento;
