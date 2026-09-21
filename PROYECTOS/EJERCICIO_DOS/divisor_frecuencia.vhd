-- =============================================================
-- Archivo    : divisor_frecuencia.vhd
-- Descripcion: Divisor de frecuencia de 50 MHz a 1 Hz.
--              La placa DE0 tiene un reloj de 50 MHz.
--              El timer necesita un pulso de 1 Hz (1 por segundo).
--              Este modulo genera ese pulso contando 50,000,000
--              ciclos del reloj de 50 MHz.
--              Solo cuenta mientras habilitar = '1' (timer corriendo):
--              al hacer stop se congela y al hacer start sigue
--              desde donde iba, sin cortar el segundo. Despues del
--              reset la salida arranca en '1', asi el primer flanco
--              de subida llega 1 s despues del start (no a los 0.5 s).
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY divisor_frecuencia IS
    PORT (
        reloj_50mhz : IN  std_logic;   -- Reloj 50 MHz de la DE0
        reset       : IN  std_logic;   -- Reset asincrono (activo en bajo)
        habilitar   : IN  std_logic;   -- '1' = timer corriendo
        reloj_1hz   : OUT std_logic    -- Pulso de 1 Hz para el timer
    );
END divisor_frecuencia;

ARCHITECTURE comportamiento OF divisor_frecuencia IS

    -- Contador interno: necesita contar hasta 49,999,999
    -- 50,000,000 ciclos de 50MHz = 1 segundo
    SIGNAL contador_ciclos : UNSIGNED(25 DOWNTO 0) := (others => '0');

    -- Senal interna de salida (para poder leerla y modificarla)
    SIGNAL reloj_1hz_reg : std_logic := '1';

BEGIN

    -- Proceso de conteo: cuenta de 0 a 49,999,999
    -- Cuando llega al limite, invierte la senal de salida
    -- Reset asincrono activo en bajo (boton DE0)
    proceso_divisor : PROCESS (reloj_50mhz, reset) IS
    BEGIN

        -- Reset asincrono activo en bajo
        IF reset = '0' THEN
            contador_ciclos <= (others => '0');
            reloj_1hz_reg   <= '1';   -- 1 -> 0 a los 0.5 s, 0 -> 1 al 1 s

        -- Flanco ascendente del reloj de 50 MHz
        ELSIF reloj_50mhz'event AND reloj_50mhz = '1' THEN

            -- Al llegar a 24,999,999 invierte la salida
            -- Esto genera una onda cuadrada de 1 Hz:
            -- 25,000,000 ciclos en alto + 25,000,000 en bajo = 1 segundo
            -- Solo cuenta mientras el timer esta corriendo
            IF habilitar = '1' THEN
                IF contador_ciclos = 24999999 THEN
                    contador_ciclos <= (others => '0');
                    reloj_1hz_reg   <= NOT reloj_1hz_reg;   -- Invertir senal
                ELSE
                    contador_ciclos <= contador_ciclos + 1;
                END IF;
            END IF;

        END IF;

    END PROCESS;

    -- Asignacion de salida
    reloj_1hz <= reloj_1hz_reg;

END comportamiento;
