-- =============================================================
-- Archivo     : div_frec.vhd
-- Descripcion : Divisor de frecuencia de 50 MHz a 1 Hz
--               Utilizado para generar el reloj de 1 segundo
--               a partir del reloj de la FPGA DE0 (50 MHz).
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY divisor_frecuencia IS
    PORT (
        reloj_50mhz : IN  std_logic;   -- Reloj de entrada 50 MHz
        reset       : IN  std_logic;   -- Reset asincrono activo alto
        habilitar   : IN  std_logic;   -- '1' = temporizador corriendo
        reloj_1hz   : OUT std_logic    -- Reloj de salida 1 Hz
    );
END divisor_frecuencia;

ARCHITECTURE comportamiento OF divisor_frecuencia IS

    -- Constante: numero de ciclos para medio periodo a 50 MHz
    -- 50,000,000 / 2 = 25,000,000 ciclos por semiciclo
    SIGNAL contador_ciclos : UNSIGNED(25 DOWNTO 0) := (others => '0');
    SIGNAL reloj_1hz_reg   : std_logic := '1';

BEGIN

    -- Proceso secuencial: contador y generacion de reloj_1hz
    proceso_divisor : PROCESS (reloj_50mhz, reset) IS
    BEGIN
        IF reset = '1' THEN
            -- Reset asincrono: limpiar contador y salida
            contador_ciclos <= (others => '0');
            reloj_1hz_reg   <= '1';   -- 1 -> 0 a los 0.5 s, 0 -> 1 al 1 s
        ELSIF reloj_50mhz'event AND reloj_50mhz = '1' THEN
            IF habilitar = '1' THEN
                -- En cada flanco de subida del reloj de 50 MHz
                IF contador_ciclos = 24999999 THEN
                    -- Al llegar a 25,000,000 ciclos: invertir salida
                    -- y reiniciar contador
                    reloj_1hz_reg   <= NOT reloj_1hz_reg;
                    contador_ciclos <= (others => '0');
                ELSE
                    -- Incrementar contador
                    contador_ciclos <= contador_ciclos + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Asignacion de la salida
    reloj_1hz <= reloj_1hz_reg;

END comportamiento;
