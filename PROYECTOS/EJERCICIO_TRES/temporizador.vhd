-- =============================================================
-- Archivo     : temporizador.vhd
-- Descripcion : Archivo principal ESTRUCTURAL del temporizador.
--               Declara todos los componentes y los conecta
--               mediante PORT MAP, siguiendo el estilo del curso.
--
-- Componentes instanciados:
--   INST_DIVISOR        -> divisor_frecuencia      : Divisor 50 MHz -> 1 Hz
--   INST_CONTROL_BOTON  -> control_boton           : Control del boton unico (corre a 50 MHz)
--   INST_CONTADOR_SEG   -> contador_segundos       : Contador de segundos (0-59)
--   INST_CONTADOR_MIN   -> contador_minutos        : Contador de minutos  (0-9)
--   INST_DISPLAY_SEG_U  -> decodificador_7segmentos: Display segundos unidades (HEX0)
--   INST_DISPLAY_SEG_D  -> decodificador_7segmentos: Display segundos decenas  (HEX1)
--   INST_DISPLAY_MIN    -> decodificador_7segmentos: Display minutos           (HEX2)
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY temporizador IS
    PORT (
        clk_50 : IN  std_logic;                     -- Reloj fisico 50 MHz
        btn    : IN  std_logic;                     -- Boton fisico (activo bajo en DE0)
        HEX0   : OUT std_logic_vector(6 DOWNTO 0);  -- Seg. unidades seg.
        HEX1   : OUT std_logic_vector(6 DOWNTO 0);  -- Seg. decenas  seg.
        HEX2   : OUT std_logic_vector(7 DOWNTO 0)   -- Minutos + puntito
    );
END temporizador;

ARCHITECTURE estructura OF temporizador IS

    -- =========================================================
    -- DECLARACION DE COMPONENTES
    -- =========================================================

    -- Componente: Divisor de frecuencia 50 MHz -> 1 Hz
    COMPONENT divisor_frecuencia IS
        PORT (
            reloj_50mhz : IN  std_logic;
            reset       : IN  std_logic;
            habilitar   : IN  std_logic;
            reloj_1hz   : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Controlador del boton unico
    -- Corre con reloj_50mhz para respuesta inmediata al presionar
    COMPONENT control_boton IS
        PORT (
            reloj_50mhz           : IN  std_logic;
            boton                 : IN  std_logic;
            corriendo             : OUT std_logic;
            reinicio_temporizador : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Contador de segundos 0-59
    COMPONENT contador_segundos IS
        PORT (
            reloj_1hz         : IN  std_logic;
            reset             : IN  std_logic;
            habilitar         : IN  std_logic;
            segundos_unidades : OUT std_logic_vector(3 DOWNTO 0);
            segundos_decenas  : OUT std_logic_vector(3 DOWNTO 0);
            acarreo           : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Contador de minutos 0-9
    COMPONENT contador_minutos IS
        PORT (
            reloj_1hz        : IN  std_logic;
            reset            : IN  std_logic;
            habilitar        : IN  std_logic;
            acarreo          : IN  std_logic;
            minutos_unidades : OUT std_logic_vector(3 DOWNTO 0);
            fin_minuto       : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Decodificador BCD -> 7 segmentos
    -- Se declara UNA SOLA VEZ y se instancia 4 veces
    COMPONENT decodificador_7segmentos IS
        PORT (
            digito_bcd : IN  std_logic_vector(3 DOWNTO 0);
            segmentos  : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

    -- =========================================================
    -- DECLARACION DE SENALES INTERNAS DE INTERCONEXION
    -- =========================================================

    -- Reloj de 1 Hz generado por el divisor de frecuencia
    SIGNAL reloj_1hz  : std_logic;

    -- Boton interno: activo alto (invertido desde la placa)
    SIGNAL boton_interno : std_logic;

    -- Senal de habilitacion del temporizador
    SIGNAL corriendo  : std_logic;

    -- Senal de reset especifico del temporizador (pulsacion larga)
    SIGNAL reinicio_temporizador : std_logic;

    -- Habilitar final: corriendo AND NOT fin_verdadero
    SIGNAL habilitar_temporizador : std_logic;

    -- Acarreo entre contador de segundos y contador de minutos
    SIGNAL acarreo : std_logic;

    -- Valores BCD de cada digito (4 bits cada uno)
    SIGNAL segundos_unidades : std_logic_vector(3 DOWNTO 0);  -- Segundos unidades
    SIGNAL segundos_decenas  : std_logic_vector(3 DOWNTO 0);  -- Segundos decenas
    SIGNAL minutos_unidades  : std_logic_vector(3 DOWNTO 0);  -- Minutos unidades

    -- fin_minuto: salida de contador_minutos (minuto=9).
    -- Se recibe pero NO se usa para detener el sistema.
    -- El verdadero fin se calcula aqui con fin_verdadero.
    SIGNAL fin_minuto : std_logic;

    -- fin_verdadero: verdadero indicador de fin de conteo.
    -- Se activa SOLO cuando minutos=9, decenas_seg=5 y unidades_seg=9
    -- Es decir, exactamente cuando el display muestra 9:59.
    SIGNAL fin_verdadero : std_logic;

BEGIN

    -- =========================================================
    -- LOGICA COMBINACIONAL DE SENALES DE CONTROL
    -- =========================================================

    -- Invertir boton: en la DE0 el pulsador es activo en bajo
    -- presionado='0' -> boton_interno='1' (activo alto para control_boton)
    boton_interno <= NOT btn;

    -- Calculo del verdadero fin de conteo: 9:59
    -- Las tres condiciones deben cumplirse simultaneamente:
    --   minutos_unidades = "1001"  ->  minutos unidades = 9
    --   segundos_decenas = "0101"  ->  segundos decenas = 5
    --   segundos_unidades = "1001" ->  segundos unidades = 9
    fin_verdadero <= '1' WHEN (minutos_unidades = "1001" AND segundos_decenas = "0101" AND segundos_unidades = "1001") ELSE '0';

    -- Habilitar: el contador solo avanza si corriendo='1' y no llego a 9:59
    habilitar_temporizador <= corriendo AND (NOT fin_verdadero);

    -- =========================================================
    -- INSTANCIACION DE COMPONENTES CON PORT MAP
    -- =========================================================

    -- Divisor de frecuencia: 50 MHz -> 1 Hz
    -- CORREGIDO: antes reset='0' fijo y sin enable, por lo que
    -- corria desde el encendido de la placa sin importar corriendo.
    -- Ahora solo cuenta mientras corriendo='1' (arranca en 00 con
    -- 1 s completo) y se reinicia con reinicio_temporizador (pulsacion larga).
    INST_DIVISOR : divisor_frecuencia
        PORT MAP (
            reloj_50mhz => clk_50,
            reset       => reinicio_temporizador,
            habilitar   => corriendo,
            reloj_1hz   => reloj_1hz
        );

    -- Controlador del boton: corre a 50 MHz para respuesta inmediata
    -- reinicio_temporizador se pasa directamente a los contadores como reset
    INST_CONTROL_BOTON : control_boton
        PORT MAP (
            reloj_50mhz           => clk_50,
            boton                 => boton_interno,
            corriendo             => corriendo,
            reinicio_temporizador => reinicio_temporizador
        );

    -- Contador de segundos: corre a 1 Hz
    -- Se resetea con reinicio_temporizador (pulsacion larga del boton)
    INST_CONTADOR_SEG : contador_segundos
        PORT MAP (
            reloj_1hz         => reloj_1hz,
            reset             => reinicio_temporizador,
            habilitar         => habilitar_temporizador,
            segundos_unidades => segundos_unidades,
            segundos_decenas  => segundos_decenas,
            acarreo           => acarreo
        );

    -- Contador de minutos: corre a 1 Hz
    -- Se resetea con reinicio_temporizador (pulsacion larga del boton)
    -- fin_minuto se conecta a fin_minuto: solo indica que el minuto llego a 9,
    INST_CONTADOR_MIN : contador_minutos
        PORT MAP (
            reloj_1hz        => reloj_1hz,
            reset            => reinicio_temporizador,
            habilitar        => habilitar_temporizador,
            acarreo          => acarreo,
            minutos_unidades => minutos_unidades,
            fin_minuto       => fin_minuto
        );

    -- Decodificador segundos unidades -> HEX0
    INST_DISPLAY_SEG_U : decodificador_7segmentos
        PORT MAP (
            digito_bcd => segundos_unidades,
            segmentos  => HEX0
        );

    -- Decodificador segundos decenas -> HEX1
    INST_DISPLAY_SEG_D : decodificador_7segmentos
        PORT MAP (
            digito_bcd => segundos_decenas,
            segmentos  => HEX1
        );

    -- Decodificador minutos -> HEX2 (7 segmentos, bits 6 a 0)
    INST_DISPLAY_MIN : decodificador_7segmentos
        PORT MAP (
            digito_bcd => minutos_unidades,
            segmentos  => HEX2(6 DOWNTO 0)
        );

    -- Puntito de HEX2 siempre encendido (activo en bajo: '0' = encendido)
    HEX2(7) <= '0';

END estructura;
