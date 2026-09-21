-- =============================================================
-- Archivo  : temporizador_espacio.vhd
-- Desc     : Top level. Cuenta 00-35 s mientras hay una persona
--            en el espacio (HEX1-HEX0); si se pasa de 35 s cuenta
--            el tiempo extra 00-99 (HEX3-HEX2) y enciende alarma.
--            Si sale antes de 35 s enciende felicitacion 3 s.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY temporizador_espacio IS
    PORT (
        CLOCK_50     : IN  STD_LOGIC;
        BUTTON       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        alarma       : OUT STD_LOGIC;
        felicitacion : OUT STD_LOGIC;
        HEX0_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END temporizador_espacio;

ARCHITECTURE estructura OF temporizador_espacio IS

    -- ----------------------------------------------------------
    -- Declaracion de componentes
    -- ----------------------------------------------------------

    COMPONENT divisor_frecuencia IS
        PORT (
            reloj_50mhz : IN  STD_LOGIC;
            reset       : IN  STD_LOGIC;
            reloj_1hz   : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT detector_ocupacion IS
        PORT (
            reloj_sistema       : IN  STD_LOGIC;
            reset               : IN  STD_LOGIC;
            entrada             : IN  STD_LOGIC;
            salida              : IN  STD_LOGIC;
            tiempo_ok           : IN  STD_LOGIC;
            ocupado             : OUT STD_LOGIC;
            felicitacion        : OUT STD_LOGIC;
            reinicio_contadores : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT contador_35_segundos IS
        PORT (
            reloj_1hz  : IN  STD_LOGIC;
            reset      : IN  STD_LOGIC;
            habilitar  : IN  STD_LOGIC;
            unidades   : OUT INTEGER RANGE 0 TO 9;
            decenas    : OUT INTEGER RANGE 0 TO 3;
            fin_conteo : OUT STD_LOGIC;
            acarreo    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT contador_tiempo_extra IS
        PORT (
            reloj_1hz : IN  STD_LOGIC;
            reset     : IN  STD_LOGIC;
            habilitar : IN  STD_LOGIC;
            unidades  : OUT INTEGER RANGE 0 TO 9;
            decenas   : OUT INTEGER RANGE 0 TO 9;
            alarma    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT decodificador_7segmentos IS
        PORT (
            digito_bcd : IN  INTEGER RANGE 0 TO 9;
            segmentos  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    -- ----------------------------------------------------------
    -- Senales internas
    -- ----------------------------------------------------------

    SIGNAL sig_reset   : STD_LOGIC;
    SIGNAL sig_entrada : STD_LOGIC;
    SIGNAL sig_salida  : STD_LOGIC;
    SIGNAL reloj_1seg  : STD_LOGIC;

    SIGNAL sig_ocupado    : STD_LOGIC;
    SIGNAL sig_fin_cuenta_35 : STD_LOGIC;

    -- Pulso de reset emitido por detector_ocupacion cuando la persona sale
    SIGNAL sig_reinicio_contadores : STD_LOGIC;

    -- Reset combinado: boton reset OR persona que sale
    -- Reinicia los contadores en ambos casos
    SIGNAL reset_combinado  : STD_LOGIC;

    -- Habilitar el contador de 35s
    SIGNAL sig_habilitar_35  : STD_LOGIC;

    -- Habilitar el tiempo extra
    SIGNAL sig_habilitar_extra : STD_LOGIC;

    -- Digitos para los displays
    SIGNAL sig_unidades_35   : INTEGER RANGE 0 TO 9;
    SIGNAL sig_decenas_35    : INTEGER RANGE 0 TO 3;
    SIGNAL sig_unidades_extra : INTEGER RANGE 0 TO 9;
    SIGNAL sig_decenas_extra  : INTEGER RANGE 0 TO 9;

    -- Adaptacion de rango para decodificador_7segmentos (0-3 -> 0-9)
    SIGNAL sig_decenas_35_ajustada : INTEGER RANGE 0 TO 9;


BEGIN

    -- Botones activos en bajo en DE0 -> invertir
    sig_reset   <= NOT BUTTON(0);
    sig_entrada <= NOT BUTTON(1);
    sig_salida  <= NOT BUTTON(2);

    -- Reset de contadores: boton reset manual O persona que sale
    reset_combinado <= sig_reset OR sig_reinicio_contadores;

    -- Habilitar del contador de 35s: corre si hay persona Y no termino
    sig_habilitar_35  <= sig_ocupado AND (NOT sig_fin_cuenta_35);

    -- Habilitar del tiempo extra: corre si hay persona Y ya paso 35s
    sig_habilitar_extra <= sig_ocupado AND sig_fin_cuenta_35;

    -- Adaptacion de rango
    sig_decenas_35_ajustada <= sig_decenas_35;

    -- ----------------------------------------------------------
    -- Instancia 1: Divisor de frecuencia 50 MHz -> 1 Hz
    -- ----------------------------------------------------------
    INST_DIVISOR : divisor_frecuencia
        PORT MAP (
            reloj_50mhz => CLOCK_50,
            reset       => sig_reset,
            reloj_1hz   => reloj_1seg
        );

    -- ----------------------------------------------------------
    -- Instancia 2: Detector de ocupacion
    -- Corre a 50 MHz para deteccion inmediata del boton
    -- ----------------------------------------------------------
    INST_DETECTOR_OCUPACION : detector_ocupacion
        PORT MAP (
            reloj_sistema       => CLOCK_50,      -- 50 MHz, no 1 Hz
            reset               => sig_reset,
            entrada             => sig_entrada,
            salida              => sig_salida,
            tiempo_ok           => sig_fin_cuenta_35,
            ocupado             => sig_ocupado,
            felicitacion        => felicitacion,
            reinicio_contadores => sig_reinicio_contadores   -- pulso al salir
        );

    -- ----------------------------------------------------------
    -- Instancia 3: Contador de 00 a 35 segundos
    -- Se resetea con reset_combinado (boton reset O persona que sale)
    -- ----------------------------------------------------------
    INST_CONTADOR_35 : contador_35_segundos
        PORT MAP (
            reloj_1hz  => reloj_1seg,
            reset      => reset_combinado,        -- reset combinado
            habilitar  => sig_habilitar_35,
            unidades   => sig_unidades_35,
            decenas    => sig_decenas_35,
            fin_conteo => sig_fin_cuenta_35,
            acarreo    => OPEN
        );

    -- ----------------------------------------------------------
    -- Instancia 4: Contador de tiempo extra 00 a 99 segundos
    -- Se resetea con reset_combinado (boton reset O persona que sale)
    -- ----------------------------------------------------------
    INST_CONTADOR_EXTRA : contador_tiempo_extra
        PORT MAP (
            reloj_1hz => reloj_1seg,
            reset     => reset_combinado,          -- reset combinado
            habilitar => sig_habilitar_extra,      -- CORREGIDO: antes sig_habilitar_35
            unidades  => sig_unidades_extra,
            decenas   => sig_decenas_extra,
            alarma    => alarma
        );

    -- ----------------------------------------------------------
    -- Instancias 5-8: Decodificadores 7 segmentos
    -- HEX0: unidades de 35s   HEX1: decenas de 35s
    -- HEX2: unidades extra    HEX3: decenas extra
    -- ----------------------------------------------------------
    INST_DISPLAY_HEX0 : decodificador_7segmentos PORT MAP (digito_bcd => sig_unidades_35,        segmentos => HEX0_D);
    INST_DISPLAY_HEX1 : decodificador_7segmentos PORT MAP (digito_bcd => sig_decenas_35_ajustada, segmentos => HEX1_D);
    INST_DISPLAY_HEX2 : decodificador_7segmentos PORT MAP (digito_bcd => sig_unidades_extra,      segmentos => HEX2_D);
    INST_DISPLAY_HEX3 : decodificador_7segmentos PORT MAP (digito_bcd => sig_decenas_extra,       segmentos => HEX3_D);

END estructura;
