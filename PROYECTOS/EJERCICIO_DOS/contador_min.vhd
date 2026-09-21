-- =============================================================
-- Archivo    : contador_min.vhd
-- Descripcion: Contador de minutos (0 a 9).
--              Cuenta de 0 a 9. Se detiene en 9 y no vuelve a 0.
--              La condicion de maximo (9:59) la gestiona el
--              modulo principal usando la senal tiempo_maximo.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_minutos IS
    PORT (
        reloj     : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset     : IN  std_logic;                       -- Reset asincrono
        habilitar : IN  std_logic;                       -- Viene del acarreo de decenas
        valor     : OUT std_logic_vector(3 DOWNTO 0)    -- Valor actual (0-9)
    );
END contador_minutos;

ARCHITECTURE comportamiento OF contador_minutos IS

    -- Senal interna de conteo (4 bits para 0-9)
    SIGNAL contador : UNSIGNED(3 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y habilitar
    proceso_contador : PROCESS (reloj, reset) IS
    BEGIN

        -- Reset asincrono: contador de minutos a cero
        IF reset = '0' THEN
            contador <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF reloj'event AND reloj = '1' THEN

            -- Solo contar si habilitar es activo
            -- (habilitar viene del acarreo de decenas de segundo)
            IF habilitar = '1' THEN

                -- Limite en 9: no incrementar mas alla de 9
                -- La condicion 9:59 detiene el timer antes de
                -- que los minutos intenten pasar de 9
                IF contador < 9 THEN
                    contador <= contador + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador
    valor <= std_logic_vector(contador);

END comportamiento;
