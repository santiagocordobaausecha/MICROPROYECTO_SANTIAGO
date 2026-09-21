-- =============================================================
-- Archivo    : contador_seg_d.vhd
-- Descripcion: Contador de decenas de segundo (0 a 5).
--              Cuenta de 0 a 5 y genera acarreo cuando llega
--              a 5, para indicar al contador de minutos que
--              ha pasado un minuto completo.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_decenas_segundo IS
    PORT (
        reloj     : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset     : IN  std_logic;                       -- Reset asincrono
        habilitar : IN  std_logic;                       -- Viene del acarreo de unidades
        valor     : OUT std_logic_vector(2 DOWNTO 0);   -- Valor actual (0-5)
        acarreo   : OUT std_logic                        -- Pulso cuando llega a 5
    );
END contador_decenas_segundo;

ARCHITECTURE comportamiento OF contador_decenas_segundo IS

    -- Senal interna de conteo
    -- Rango 0-5 cabe en 3 bits
    SIGNAL contador : UNSIGNED(2 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y habilitar
    proceso_contador : PROCESS (reloj, reset) IS
    BEGIN

        -- Reset asincrono: contador a cero
        IF reset = '0' THEN
            contador <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF reloj'event AND reloj = '1' THEN

            -- Solo contar si el habilitar es activo
            -- (habilitar viene del acarreo de unidades de segundo)
            IF habilitar = '1' THEN

                -- Cuando llega a 5, volver a 0 (modulo-6)
                IF contador = 5 THEN
                    contador <= (others => '0');

                -- De lo contrario, incrementar
                ELSE
                    contador <= contador + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador
    valor <= std_logic_vector(contador);

    -- acarreo es '1' cuando esta en 5 y habilitado
    -- Esto indica que ha completado un minuto
    acarreo <= '1' WHEN (contador = 5 AND habilitar = '1') ELSE '0';
	

END comportamiento;
