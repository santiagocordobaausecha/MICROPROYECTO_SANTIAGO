-- Archivo: divisor_frecuencia.vhd
-- Descripcion: Divisor de frecuencia de 50 MHz a 1 Hz.
--              La placa DE0 tiene un reloj de 50 MHz.
--              El timer necesita un pulso de 1 Hz (1 por segundo).
--              Este modulo genera ese pulso contando 50,000,000
--              ciclos del reloj de 50 MHz.

-- CLAUDE SONETE 5.5: se uso parcialmente el codigo que nos mando con siertas modificaciones 

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY divisor_frecuencia IS
    PORT (
        reloj_50mhz : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        reloj_1hz   : OUT STD_LOGIC
    );
END divisor_frecuencia;

ARCHITECTURE comportamiento OF divisor_frecuencia IS
    -- 25,000,000 ciclos en alto + 25,000,000 en bajo = 1 segundo
    -- Necesita 26 bits (2^26 = 67,108,864 > 24,999,999)
    SIGNAL contador_ciclos : UNSIGNED(25 DOWNTO 0);
    SIGNAL reloj_1hz_reg   : STD_LOGIC;
BEGIN

    proceso_divisor : PROCESS (reloj_50mhz, reset)
    BEGIN
        -- Reset asincrono activo en alto
        IF (reset = '1') THEN
            contador_ciclos <= (OTHERS => '0');
            reloj_1hz_reg   <= '0';
        ELSIF (reloj_50mhz'EVENT AND reloj_50mhz = '1') THEN
            IF (contador_ciclos = 24999999) THEN
                contador_ciclos <= (OTHERS => '0');
                reloj_1hz_reg   <= NOT reloj_1hz_reg;
            ELSE
                contador_ciclos <= contador_ciclos + 1;
            END IF;
        END IF;
    END PROCESS;

    reloj_1hz <= reloj_1hz_reg;

END comportamiento;
