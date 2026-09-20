-- =============================================================
-- Archivo  : contador_seg35.vhd
-- Entidad  : contador_35_segundos
-- Desc     : Contador unificado de 00 a 35 segundos.
--            Unidades y decenas en un solo proceso, igual que
--            cont_seg del proyecto anterior. Elimina todos los
--            problemas de sincronizacion de carry entre modulos.
--
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY contador_35_segundos IS
    PORT (
        reloj_1hz   : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        habilitar   : IN  STD_LOGIC;
        unidades    : OUT INTEGER RANGE 0 TO 9;
        decenas     : OUT INTEGER RANGE 0 TO 3;
        fin_conteo  : OUT STD_LOGIC;
        acarreo     : OUT STD_LOGIC
    );
END contador_35_segundos;

ARCHITECTURE comportamiento OF contador_35_segundos IS
    SIGNAL contador_unidades : INTEGER RANGE 0 TO 9;
    SIGNAL contador_decenas  : INTEGER RANGE 0 TO 3;
    SIGNAL acarreo_reg       : STD_LOGIC;
    SIGNAL fin_conteo_reg    : STD_LOGIC;
BEGIN

    proceso_contador_35 : PROCESS (reloj_1hz, reset)
BEGIN
    IF (reset = '1') THEN
        contador_unidades <= 0;
        contador_decenas  <= 0;
        acarreo_reg       <= '0';
        fin_conteo_reg    <= '0';

    ELSIF (reloj_1hz'EVENT AND reloj_1hz = '1') THEN
        acarreo_reg <= '0';

        IF (habilitar = '1') THEN

            -- ya estamos en 35: quedarse quieto
            IF (contador_decenas = 3 AND contador_unidades = 5) THEN
                NULL;

            -- unidades llegan a 9
            ELSIF (contador_unidades = 9) THEN
                contador_unidades <= 0;
                contador_decenas  <= contador_decenas + 1;
                acarreo_reg       <= '1';

            -- incremento normal
            ELSE
                contador_unidades <= contador_unidades + 1;
                IF (contador_decenas = 3 AND contador_unidades = 4) THEN
                    fin_conteo_reg <= '1';
                END IF;
            END IF;

        END IF;
    END IF;
END PROCESS;

    unidades   <= contador_unidades;
    decenas    <= contador_decenas;
    fin_conteo <= fin_conteo_reg;
    acarreo    <= acarreo_reg;

END comportamiento;
