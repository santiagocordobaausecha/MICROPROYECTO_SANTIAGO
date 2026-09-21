-- =============================================================
-- Archivo    : contador_seg_u.vhd
-- Descripcion: Contador de unidades de segundo (0 a 9).
--              Cuenta de 0 a 9 y genera un pulso de acarreo
--              (acarreo='1') cuando llega a 9, para indicar
--              al siguiente digito que debe incrementarse.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_unidades_segundo IS
    PORT (
        reloj     : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset     : IN  std_logic;                       -- Reset asincrono
        habilitar : IN  std_logic;                       -- Habilitacion del contador
        valor     : OUT std_logic_vector(3 DOWNTO 0);   -- Valor actual (0-9)
        acarreo   : OUT std_logic                        -- Pulso cuando llega a 9
    );
END contador_unidades_segundo;

ARCHITECTURE comportamiento OF contador_unidades_segundo IS

    -- Senal interna de conteo (tipo UNSIGNED para aritmetica)
    SIGNAL contador : UNSIGNED(3 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y habilitar
    proceso_contador : PROCESS (reloj, reset) IS
    BEGIN

        -- Reset asincrono: contador a cero
        IF reset = '0' THEN
            contador <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF reloj'event AND reloj = '1' THEN

            -- Solo contar si el timer esta habilitado (habilitar='1')
            IF habilitar = '1' THEN

                -- Cuando llega a 9, volver a 0 (modulo-10)
                IF contador = 9 THEN
                    contador <= (others => '0');

                -- De lo contrario, incrementar
                ELSE
                    contador <= contador + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador en std_logic_vector
    valor <= std_logic_vector(contador);

    -- acarreo es '1' solo cuando el contador esta en 9 y habilitado
    -- Esto indica al siguiente digito que debe incrementar
    acarreo <= '1' WHEN (contador = 9 AND habilitar = '1') ELSE '0';

END comportamiento;
