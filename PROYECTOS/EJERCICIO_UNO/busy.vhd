-- =============================================================
-- Archivo  : busy.vhd
-- Entidad  : detector_ocupacion
-- Descripcion: Detector de ocupacion del espacio.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY detector_ocupacion IS
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
END detector_ocupacion;

ARCHITECTURE comportamiento OF detector_ocupacion IS

    SIGNAL estado_ocupado      : STD_LOGIC := '0';
    SIGNAL estado_felicitacion : STD_LOGIC := '0';

    -- Sincronizadores de 2 flip-flops para los botones
    -- (los botones son asincronos respecto a CLOCK_50)
    SIGNAL entrada_sinc1, entrada_sinc2 : STD_LOGIC := '0';
    SIGNAL salida_sinc1,  salida_sinc2  : STD_LOGIC := '0';

    -- Deteccion de flanco de subida de los botones
    SIGNAL entrada_anterior : STD_LOGIC := '0';
    SIGNAL salida_anterior  : STD_LOGIC := '0';

    -- Contador de 3 segundos para apagar felicitacion
    SIGNAL contador_felicitacion : UNSIGNED(27 DOWNTO 0) := (others => '0');

    -- Indica si el contador de felicitacion esta corriendo
    SIGNAL contando_felicitacion : STD_LOGIC := '0';

    -- Constante: 3 segundos en ciclos de 50 MHz
    CONSTANT TRES_SEGUNDOS : UNSIGNED(27 DOWNTO 0) := to_unsigned(150000000, 28);

BEGIN

    proceso_control : PROCESS (reloj_sistema, reset)
    BEGIN
        IF (reset = '1') THEN
            estado_ocupado        <= '0';
            estado_felicitacion   <= '0';
            entrada_sinc1         <= '0';
            entrada_sinc2         <= '0';
            salida_sinc1          <= '0';
            salida_sinc2          <= '0';
            entrada_anterior      <= '0';
            salida_anterior       <= '0';
            reinicio_contadores   <= '0';
            contador_felicitacion <= (others => '0');
            contando_felicitacion <= '0';

        ELSIF (reloj_sistema'EVENT AND reloj_sistema = '1') THEN

            -- Sincronizacion de botones
            entrada_sinc1 <= entrada;
            entrada_sinc2 <= entrada_sinc1;
            salida_sinc1  <= salida;
            salida_sinc2  <= salida_sinc1;

            -- Por defecto el pulso de reset dura solo un ciclo
            reinicio_contadores <= '0';

            -- -----------------------------------------------
            -- CONTADOR DE 3 SEGUNDOS PARA FELICITACION
            -- Corre mientras contando_felicitacion='1'.
            -- Al llegar a TRES_SEGUNDOS apaga el LED.
            -- -----------------------------------------------
            IF (contando_felicitacion = '1') THEN
                IF (contador_felicitacion >= TRES_SEGUNDOS) THEN
                    estado_felicitacion   <= '0';
                    contando_felicitacion <= '0';
                    contador_felicitacion <= (others => '0');
                ELSE
                    contador_felicitacion <= contador_felicitacion + 1;
                END IF;
            END IF;

            -- -----------------------------------------------
            -- SUBIDA DE ENTRADA
            -- -----------------------------------------------
            IF (entrada_sinc2 = '1' AND entrada_anterior = '0') THEN
                estado_ocupado <= '1';
                -- Si aun estaba el LED de felicitacion, apagarlo
                estado_felicitacion   <= '0';
                contando_felicitacion <= '0';
                contador_felicitacion <= (others => '0');
            END IF;

            -- -----------------------------------------------
            -- SUBIDA DE SALIDA
            -- -----------------------------------------------
            IF (salida_sinc2 = '1' AND salida_anterior = '0' AND estado_ocupado = '1') THEN
                estado_ocupado      <= '0';
                reinicio_contadores <= '1';   -- reiniciar contadores display

                IF (tiempo_ok = '0') THEN
                    -- Salio antes de 35s: encender felicitacion
                    -- y arrancar contador de 3 segundos
                    estado_felicitacion   <= '1';
                    contando_felicitacion <= '1';
                    contador_felicitacion <= (others => '0');
                ELSE
                    estado_felicitacion <= '0';
                END IF;
            END IF;

            -- Guardar estado anterior de botones
            entrada_anterior <= entrada_sinc2;
            salida_anterior  <= salida_sinc2;

        END IF;
    END PROCESS;

    ocupado      <= estado_ocupado;
    felicitacion <= estado_felicitacion;

END comportamiento;
