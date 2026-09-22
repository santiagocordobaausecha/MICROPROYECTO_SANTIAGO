-- =============================================================
-- Archivo    : timer_control.vhd
-- Descripcion: Modulo de control del timer.
--              Usa reloj_50mhz (50 MHz) para detectar pulsaciones
--              de botones con precision. El estado 'corriendo'
--              controla si los contadores de 1Hz cuentan o no.
--
-- RAZON DEL CAMBIO:
--              Con reloj_1hz (1 Hz) solo hay 1 muestreo por segundo.
--              Una pulsacion humana dura ~100-200ms y puede perderse
--              facilmente. Con reloj_50mhz (50 MHz) hay 50 millones de
--              muestreos por segundo: ninguna pulsacion se pierde.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY control_temporizador IS
    PORT (
        reloj_50mhz   : IN  std_logic;   -- Reloj 50 MHz para botones
        reset         : IN  std_logic;   -- BUTTON[0] activo en bajo
        inicio        : IN  std_logic;   -- BUTTON[1] activo en bajo
        parar         : IN  std_logic;   -- BUTTON[2] activo en bajo
        tiempo_maximo : IN  std_logic;   -- Timer llego a 9:59
        corriendo     : OUT std_logic    -- 1=corriendo, 0=detenido
    );
END control_temporizador;

ARCHITECTURE comportamiento OF control_temporizador IS

    SIGNAL estado          : std_logic;
    SIGNAL inicio_anterior : std_logic;
    SIGNAL parar_anterior  : std_logic;

BEGIN

    proceso_control : PROCESS (reloj_50mhz, reset) IS
    BEGIN

        -- Reset asincrono activo en bajo
        IF reset = '0' THEN
            estado          <= '0';
            inicio_anterior <= '1';
            parar_anterior  <= '1';

        -- Muestreo a 50 MHz: detecta flancos de botones
        ELSIF reloj_50mhz'event AND reloj_50mhz = '1' THEN

            inicio_anterior <= inicio;
            parar_anterior  <= parar;

            -- Flanco descendente de inicio (1->0 = boton presionado)
            IF inicio = '0' AND inicio_anterior = '1' AND tiempo_maximo = '0' THEN
                estado <= '1';

            -- Flanco descendente de parar (1->0 = boton presionado)
            ELSIF parar = '0' AND parar_anterior = '1' THEN
                estado <= '0';

            -- Detenerse automaticamente al llegar a 9:59
            ELSIF tiempo_maximo = '1' THEN
                estado <= '0';

            END IF;

        END IF;

    END PROCESS;

    corriendo <= estado;

END comportamiento;
