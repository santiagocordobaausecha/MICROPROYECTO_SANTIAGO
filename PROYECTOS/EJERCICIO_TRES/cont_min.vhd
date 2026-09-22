-- =============================================================
-- Archivo     : cont_min.vhd
-- Descripcion : Contador de minutos de 0 a 9 (modulo 10).
--               Incrementa cuando recibe el pulso acarreo
--               proveniente del contador de segundos.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_minutos IS
    PORT (
        reloj_1hz        : IN  std_logic;                     -- Reloj 1 Hz
        reset            : IN  std_logic;                     -- Reset activo alto
        habilitar        : IN  std_logic;                     -- Habilitacion
        acarreo          : IN  std_logic;                     -- Pulso de contador_segundos
        minutos_unidades : OUT std_logic_vector(3 DOWNTO 0);  -- Valor de minutos
        fin_minuto       : OUT std_logic                      -- Indicador (ver nota)
    );
END contador_minutos;

ARCHITECTURE comportamiento OF contador_minutos IS
    SIGNAL contador : UNSIGNED(3 DOWNTO 0) := (others => '0');
BEGIN

    proceso_contador_minutos : PROCESS (reloj_1hz, reset) IS
    BEGIN
        IF reset = '1' THEN
            contador <= (others => '0');

        ELSIF reloj_1hz'event AND reloj_1hz = '1' THEN
            -- Incrementar minuto cuando hay acarreo Y el sistema corre
            -- Y aun no se llego al maximo de 9 minutos
            IF habilitar = '1' AND acarreo = '1' AND contador < 9 THEN
                contador <= contador + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Salidas combinacionales
    minutos_unidades <= std_logic_vector(contador);

    -- NOTA: esta senal queda disponible en el puerto pero
    -- NO debe conectarse al habilitar_temporizador del top-level.
    -- El fin real (9:59) se determina en temporizador.vhd
    -- con fin_verdadero usando minutos_unidades, segundos_decenas y segundos_unidades.
    fin_minuto <= '1' WHEN contador = 9 ELSE '0';

END comportamiento;
