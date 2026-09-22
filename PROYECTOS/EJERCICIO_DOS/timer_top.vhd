-- =============================================================
-- Archivo    : timer_top.vhd
-- Descripcion: Modulo principal TOP-LEVEL del timer 0:00 - 9:59
--
--   clk_50 -> divisor_frecuencia -> reloj_1hz -> contadores
--   clk_50 -> control_temporizador (deteccion de botones a 50 MHz)
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY timer_top IS
    PORT (
        clk_50    : IN  std_logic;
        reset     : IN  std_logic;
        start     : IN  std_logic;
        stop      : IN  std_logic;
        ssd_min   : OUT std_logic_vector(6 DOWNTO 0);
        ssd_min_dp: OUT std_logic;
        ssd_seg_d : OUT std_logic_vector(6 DOWNTO 0);
        ssd_seg_u : OUT std_logic_vector(6 DOWNTO 0)
    );
END timer_top;

ARCHITECTURE estructura OF timer_top IS

    -- ==========================================================
    -- DECLARACION DE COMPONENTES
    -- ==========================================================

    COMPONENT divisor_frecuencia IS
        PORT (
            reloj_50mhz : IN  std_logic;
            reset       : IN  std_logic;
            habilitar   : IN  std_logic;
            reloj_1hz   : OUT std_logic
        );
    END COMPONENT;

    -- CAMBIO: control_temporizador ahora recibe reloj_50mhz
    COMPONENT control_temporizador IS
        PORT (
            reloj_50mhz   : IN  std_logic;
            reset         : IN  std_logic;
            inicio        : IN  std_logic;
            parar         : IN  std_logic;
            tiempo_maximo : IN  std_logic;
            corriendo     : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_unidades_segundo IS
        PORT (
            reloj     : IN  std_logic;
            reset     : IN  std_logic;
            habilitar : IN  std_logic;
            valor     : OUT std_logic_vector(3 DOWNTO 0);
            acarreo   : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_decenas_segundo IS
        PORT (
            reloj     : IN  std_logic;
            reset     : IN  std_logic;
            habilitar : IN  std_logic;
            valor     : OUT std_logic_vector(2 DOWNTO 0);
            acarreo   : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_minutos IS
        PORT (
            reloj     : IN  std_logic;
            reset     : IN  std_logic;
            habilitar : IN  std_logic;
            valor     : OUT std_logic_vector(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT decodificador_7segmentos IS
        PORT (
            digito_bcd : IN  std_logic_vector(3 DOWNTO 0);
            segmentos  : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

    -- ==========================================================
    -- SENALES INTERNAS
    -- ==========================================================

    SIGNAL reloj_1hz             : std_logic;
    SIGNAL corriendo             : std_logic;
    SIGNAL acarreo_unidades      : std_logic;
    SIGNAL acarreo_decenas       : std_logic;
    SIGNAL valor_unidades_segundo    : std_logic_vector(3 DOWNTO 0);
    SIGNAL valor_decenas_segundo_3b  : std_logic_vector(2 DOWNTO 0);
    SIGNAL valor_decenas_segundo     : std_logic_vector(3 DOWNTO 0);
    SIGNAL valor_minutos             : std_logic_vector(3 DOWNTO 0);
    SIGNAL tiempo_maximo         : std_logic;

BEGIN

    -- ==========================================================
    -- LOGICA COMBINACIONAL
    -- ==========================================================

    tiempo_maximo <= '1' WHEN (valor_minutos = "1001" AND
                                valor_decenas_segundo_3b = "101" AND
                                valor_unidades_segundo = "1001")
                  ELSE '0';

    valor_decenas_segundo <= '0' & valor_decenas_segundo_3b;

    -- Punto de HEX2 siempre encendido (activo en bajo)
    ssd_min_dp <= '0';

    -- ==========================================================
    -- INSTANCIACION DE COMPONENTES
    -- ==========================================================

    -- Divisor: 50 MHz -> 1 Hz para los contadores
    -- Solo corre con corriendo='1' para que el conteo arranque en 0:00
    -- y no se corte el segundo al hacer stop/start
    INST_DIVISOR : divisor_frecuencia
        PORT MAP (
            reloj_50mhz => clk_50,
            reset       => reset,
            habilitar   => corriendo,
            reloj_1hz   => reloj_1hz
        );

    -- Control: usa clk_50 para detectar botones rapidamente
    INST_CONTROL : control_temporizador
        PORT MAP (
            reloj_50mhz   => clk_50,
            reset         => reset,
            inicio        => start,
            parar         => stop,
            tiempo_maximo => tiempo_maximo,
            corriendo     => corriendo
        );

    -- Contadores: usan reloj_1hz para contar segundos reales
    INST_CONTADOR_UNIDADES : contador_unidades_segundo
        PORT MAP (
            reloj     => reloj_1hz,
            reset     => reset,
            habilitar => corriendo,
            valor     => valor_unidades_segundo,
            acarreo   => acarreo_unidades
        );

    INST_CONTADOR_DECENAS : contador_decenas_segundo
        PORT MAP (
            reloj     => reloj_1hz,
            reset     => reset,
            habilitar => acarreo_unidades,
            valor     => valor_decenas_segundo_3b,
            acarreo   => acarreo_decenas
        );

    INST_CONTADOR_MINUTOS : contador_minutos
        PORT MAP (
            reloj     => reloj_1hz,
            reset     => reset,
            habilitar => acarreo_decenas,
            valor     => valor_minutos
        );

    -- Decodificadores
    INST_DISPLAY_UNIDADES : decodificador_7segmentos
        PORT MAP (
            digito_bcd => valor_unidades_segundo,
            segmentos  => ssd_seg_u
        );

    INST_DISPLAY_DECENAS : decodificador_7segmentos
        PORT MAP (
            digito_bcd => valor_decenas_segundo,
            segmentos  => ssd_seg_d
        );

    INST_DISPLAY_MINUTOS : decodificador_7segmentos
        PORT MAP (
            digito_bcd => valor_minutos,
            segmentos  => ssd_min
        );

END estructura;
