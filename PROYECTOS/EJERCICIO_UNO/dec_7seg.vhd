-- ============================================================
-- Archivo     : dec_7seg.vhd
-- Descripción : Decodificador BCD a 7 segmentos.
--               Recibe un dígito INTEGER (0 a 9) y entrega
--               el patrón para display activo en bajo (DE0).
--               Segmentos: "gfedcba" (bit 6 = g, bit 0 = a)

-- ============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY decodificador_7segmentos IS
    PORT (
        digito_bcd : IN  INTEGER RANGE 0 TO 9;
        segmentos  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END decodificador_7segmentos;

ARCHITECTURE comportamiento OF decodificador_7segmentos IS
BEGIN

    proceso_decodificador : PROCESS (digito_bcd)
    BEGIN
        -- Patrones activo en bajo para displays DE0
        -- Orden de bits: segmentos = "gfedcba"
        CASE digito_bcd IS
            WHEN 0 => segmentos <= "1000000"; -- 0
            WHEN 1 => segmentos <= "1111001"; -- 1
            WHEN 2 => segmentos <= "0100100"; -- 2
            WHEN 3 => segmentos <= "0110000"; -- 3
            WHEN 4 => segmentos <= "0011001"; -- 4
            WHEN 5 => segmentos <= "0010010"; -- 5
            WHEN 6 => segmentos <= "0000010"; -- 6
            WHEN 7 => segmentos <= "1111000"; -- 7
            WHEN 8 => segmentos <= "0000000"; -- 8
            WHEN 9 => segmentos <= "0010000"; -- 9
            WHEN OTHERS => segmentos <= "1111111"; -- apagado
        END CASE;
    END PROCESS;

END comportamiento;
