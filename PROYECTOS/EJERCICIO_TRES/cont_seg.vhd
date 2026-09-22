-- =============================================================
-- Archivo     : cont_seg.vhd
-- Descripcion : Contador de segundos de 0 a 59 (modulo 60).
--               Las salidas se entregan separadas en decenas
--               y unidades para facilitar la decodificacion
--               en los displays de 7 segmentos.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_segundos IS
    PORT (
        reloj_1hz         : IN  std_logic;
        reset             : IN  std_logic;
        habilitar         : IN  std_logic;
        segundos_unidades : OUT std_logic_vector(3 DOWNTO 0);
        segundos_decenas  : OUT std_logic_vector(3 DOWNTO 0);
        acarreo           : OUT std_logic
    );
END contador_segundos;

ARCHITECTURE comportamiento OF contador_segundos IS

    SIGNAL contador_unidades : UNSIGNED(3 DOWNTO 0) := (others => '0');
    SIGNAL contador_decenas  : UNSIGNED(3 DOWNTO 0) := (others => '0');

BEGIN

    proceso_contador_segundos : PROCESS (reloj_1hz, reset) IS
    BEGIN
        IF reset = '1' THEN
            contador_unidades <= (others => '0');
            contador_decenas  <= (others => '0');
            

        ELSIF reloj_1hz'event AND reloj_1hz = '1' THEN

           

            IF habilitar = '1' THEN


                -- CASO 1: llegamos a 59 -> resetear 
                IF contador_decenas = 5 AND contador_unidades = 9 THEN
                    contador_unidades <= (others => '0');
                    contador_decenas  <= (others => '0');
                    

                -- CASO 2: unidades llegaron a 9 -> subir decenas
                ELSIF contador_unidades = 9 THEN
                    contador_unidades <= (others => '0');
                    contador_decenas  <= contador_decenas + 1;

                -- CASO 3: incremento normal
                ELSE
                    contador_unidades <= contador_unidades + 1;

                END IF;

            END IF;

        END IF;
    END PROCESS;

    segundos_unidades <= std_logic_vector(contador_unidades);
    segundos_decenas  <= std_logic_vector(contador_decenas);
	 acarreo <= '1' WHEN (habilitar = '1' AND contador_decenas = 5 AND contador_unidades = 9) ELSE '0';
   

END comportamiento;
