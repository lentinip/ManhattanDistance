----------------------------------------------------------------------------------
--ANNO ACCADEMICO 2018/2019
--(PROVA FINALE) PROGETTO DI RETI LOGICHE
--Docente: Salice Fabio

--Studente: Lentini Pietro
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.all;

entity project_reti_logiche is 
    port (
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector(7 downto 0)
        );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is
    type state_type is (S0, S1, S2, S3, S4, S5, S6, S7);
    signal CURRENT_STATE : state_type;
begin

process(i_clk, i_rst)

    --Costanti
    constant pointsToConsiderAddress: std_logic_vector(15 downto 0) := "0000000000000000"; --Indirizzo maschera con i centroidi da considerare (Indirizzo 0)
    constant numberOfPoints : integer := 8; --Numero di centroidi in memoria
    constant xPointAddress : std_logic_vector(15 downto 0) := "0000000000010001"; --Indirizzo coordinata X del punto da valutare(Indirizzo 17)
    constant yPointAddress : std_logic_vector(15 downto 0) := "0000000000010010"; --Indirizzo coordinata Y del punto da valutare(Indirizzo 18)
    constant startingPoint : std_logic_vector(15 downto 0) := "0000000000000000"; --Primo indirizzo della lista di indirizzi di coordinate: Indirizzo 0 (NOTA: DEVE ESSERE DI 1 MINORE RISPETTO ALL'INDIRIZZO REALE)
    constant whereToWrite : std_logic_vector(15 downto 0) := "0000000000010011"; --Indirizzo del risultato (Indirizzo 19)
    
    --Variabili
    variable pointsToConsider : std_logic_vector(7 downto 0); --Variabile che contiene la maschera con i centroidi da considerare (da leggere dalla memoria)
    variable isFirstRound : std_logic; --Variabile che permette di far utilizzare l'indirizzo 0000000000000000 come pointsToConsiderAddress
    variable currentPoint : integer; --Intero con il numero del centroide analizzato
    variable minDistance : integer range 0 to 510 := 0; --Variabile che contiene la distanza minima trovata
    variable currentDistance : integer range -1 to 510:= 0; --Variabile che contiene la distanza dal punto dal centroide analizzato
    variable currentAddress : std_logic_vector(15 downto 0); --Variabile che contiene l'indirizzo di memoria da utilizzare/appena utilizzato
    variable xPoint : integer range -1 to 255; --Variabile che contiene la coordinata X del punto da valutare (da leggere dalla memoria)
    variable yPoint : integer range -1 to 255; --Variabile che contiene la coordinata Y del punto da valutare (da leggere dalla memoria)
    variable currentXPoint : integer range -1 to 255; --Variabile che contiene la coordinata X del centroide analizzato (da leggere dalla memoria)
    variable currentYPoint : integer range -1 to 255; --Variabile che contiene la coordinata Y del centroide analizzato (da leggere dalla memoria)
    variable result : std_logic_vector(7 downto 0);    

    begin
    if i_rst = '1' then
        CURRENT_STATE <= S0;
    end if;
    if (rising_edge(i_clk) and i_rst = '0') then
        case CURRENT_STATE is 
        
        when S0 => --Stato d'inizio
            if i_start = '1' then
            --Inizializzazione
            minDistance := 510;
            currentDistance := -1;
            pointsToConsider := "00000000";
            isFirstRound := '1';
            currentPoint := 0;
            currentAddress := pointsToConsiderAddress;
            xPoint := -1;
            yPoint := -1;
            currentXPoint := -1;
            currentYPoint := -1;
            result := "00000000";
            o_en <= '0';
            o_we <= '0';
            o_address <= currentAddress;
            o_done <= '0';
            o_data <= "00000000";
            CURRENT_STATE <= S1;
            end if;
            
        when S1 => --Stato che gestisce l'ordine degli indirizzi da leggere in memoria ed invia i segnali per la lettura alla memoria
        
            --Gestione indirizzo della maschera dei centroidi da considerare
            if currentAddress = pointsToConsiderAddress then
                --If necessario se pointsToConsiderAddress è l'indirizzo 0
                if isFirstRound = '0' then
                    currentAddress := xPointAddress;
                end if;
                
                o_address <= currentAddress;
                o_en <= '1';
                o_we <= '0';
                CURRENT_STATE <= S2;
            
            --Dopo aver impostato la variabile xPoint viene preparata la lettura di yPoint    
            elsif ( currentAddress = xPointAddress and yPoint = -1) then
                currentAddress := yPointAddress;
                
                o_address <= currentAddress;
                o_en <= '1';
                o_we <= '0';
                CURRENT_STATE <= S2;
            
            --Dopo aver letto la maschera dei centroidi da considerare e le coordinate del punto da valutare, lo stato far‡ scorrere gli indirizzi delle coordinate dei centroidi
            else
                --Gestione degli indirizzi dei centroidi da analizzare
                if currentAddress = yPointAddress then
                    currentAddress := startingPoint;
                    end if;
                
                --Se ci sono ancora centroidi da analizzare
                if currentPoint < numberOfPoints then
                    
                    --Se il centroide è da considerare (è ad 1 nella maschera) lo analizza
                    if pointsToConsider(currentPoint) = '1' then
                        currentAddress := currentAddress + "0000000000000001";
                        o_address <= currentAddress;
                        o_en <= '1';
                        o_we <= '0';
                        CURRENT_STATE <= S2;
                    
                    --Altrimenti vi è un autoanello ed analizza il centroide successivo
                    else
                        currentAddress := currentAddress + "0000000000000010";
                        currentPoint := currentPoint + 1;
                        CURRENT_STATE <= S1;
                    end if;
                 --Se non ci sono più centroidi da verificare
                 else
                    CURRENT_STATE <= S5;   
                end if;
            end if;
            
        when S2 => --Stato di attesa per la lettura della memoria
            CURRENT_STATE <= S3;
        
        when S3 => --Stato per la lettura della memoria e scrittura variabili principali
            o_en <= '0';
            o_we <= '0';
            
            if currentAddress = pointsToConsiderAddress then
                pointsToConsider := i_data;
                isFirstRound := '0';
                CURRENT_STATE <= S1;
                
            elsif currentAddress = xPointAddress then
                xPoint := to_integer(unsigned(i_data));
                CURRENT_STATE <= S1;
                
            elsif currentAddress = yPointAddress then
                yPoint := to_integer(unsigned(i_data));
                CURRENT_STATE <= S1;
                
            elsif currentXPoint = -1 then
                currentXPoint := to_integer(unsigned(i_data));
                --Deve essere letta anche la coordinata Y del centroide corrente
                CURRENT_STATE <= S1;
                
            else
                currentYPoint := to_integer(unsigned(i_data));
                --Si passa al confronto
                CURRENT_STATE <= S4;
            end if;
        
        when S4 => --Stato che gestisce il confronto
        
            --Calcola la distanza con il centroide corrente
            if xPoint > currentXPoint then
                currentDistance := xPoint - currentXPoint;
            else
                currentDistance := currentXPoint - xPoint;
            end if;
            
            if yPoint > currentYPoint then
                currentDistance := currentDistance + (yPoint - currentYPoint);
            else
                currentDistance := currentDistance + (currentYPoint - yPoint);
            end if;
            
            --Confronta la distanza calcolata con la distanza precedente

            if currentDistance = minDistance then
                result(currentPoint) := '1';
            end if;
            if currentDistance < minDistance then
                result := "00000000";
                minDistance := currentDistance;
                result(currentPoint) := '1';
            end if;
            
            --Continua l'analisi degli altri centroidi
            currentXPoint := -1;
            currentYPoint := -1;
            currentPoint := currentPoint + 1;
            CURRENT_STATE <= S1;
            
        when S5 => --Imposta i segnali per la scrittura in memoria
            o_en <= '1';
            o_we <= '1';
            o_address <= whereToWrite; 
            o_data <= result;
            CURRENT_STATE <= S6;
            
        when S6 => --Porta il segnale o_done ad 1
            o_en <= '0';
            o_we <= '0';
            o_done <= '1';
            CURRENT_STATE <= S7;
        
        when S7 => --Porta il segnale o_done a 0 quando il segnale i_start è a 0
            if i_start = '0' then 
                o_done <= '0';
                CURRENT_STATE <= S0;
            end if;
          
        end case;
    end if;
end process;
end behavioral;
