----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/20/2017 01:46:27 PM
-- Design Name: 
-- Module Name: DD2_FP_Multiplier - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
     
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all; 
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DD2_FP_Multiplier is
    port ( 
        A           : in std_logic_vector(31 downto 0);
        B           : in std_logic_vector(31 downto 0);
        result      : out std_logic_vector(31 downto 0);
        clk         : in std_logic;
        reset       : in std_logic;
        start       : in std_logic;
        done        : out std_logic;
        overflow    : out std_logic    
    );
end DD2_FP_Multiplier;

architecture Behavioral of DD2_FP_Multiplier is

    signal done_i : std_logic := '1';
    signal start_del_i : std_logic := '0';

begin

    done <= done_i;
    
    DONE_PROC : process(clk, reset)
    begin
        if reset = '1' then
            done_i <= '0';
        elsif rising_edge(clk) then
            start_del_i <= start;
            
            if start = '1' then
                done_i <= '0';
            elsif start_del_i = '1' then
                done_i <= '1';
            end if;
        end if;
    end process DONE_PROC;
    
    

    P1:process(clk,reset)
	    variable A_mantisse : STD_LOGIC_VECTOR (22 downto 0);
		variable A_exponent : STD_LOGIC_VECTOR (7 downto 0);
		variable A_sign : STD_LOGIC;
		variable B_mantisse : STD_LOGIC_VECTOR (22 downto 0);
		variable B_exponent : STD_LOGIC_VECTOR (7 downto 0);
		variable B_sign : STD_LOGIC;
		variable result_mantisse : STD_LOGIC_VECTOR (22 downto 0);
		variable result_exponent : STD_LOGIC_VECTOR (7 downto 0);
		variable result_sign : STD_LOGIC;
		variable aux : STD_LOGIC;
		variable aux2 : STD_LOGIC_VECTOR (47 downto 0);
		variable exponent_sum : STD_LOGIC_VECTOR (8 downto 0);

   begin
   if reset = '1' then
       -- reset alles
       overflow <=  '0' ;     
       result(31 downto 0)  <=  (others => '0')  ;        
   elsif rising_edge(clk) then
      if start='1' then
		A_mantisse := A(22 downto 0);
		A_exponent := A(30 downto 23);
		A_sign := A(31);
		B_mantisse := B(22 downto 0);
		B_exponent := B(30 downto 23);
		B_sign := B(31);
		-- Check op vermenigvuldigen met 0 of inf
		if (A_exponent=255 or B_exponent=255) then 
		 -- vermenigvuldigen met inf
			result_exponent := "11111111";
			result_mantisse := (others => '0');
			result_sign := A_sign xor B_sign;
		elsif (A_exponent=0 or B_exponent=0) then 
		 -- vermenigvuldigen met 0
			result_exponent := (others => '0');
			result_mantisse := (others => '0');
			result_sign := '0';
		else
			aux2 := ('1' & A_mantisse) * ('1' & B_mantisse); --aux2 is 48 bits groot want vermeningvuldiging van 2 24 bit getallen is max 48 bits groot
			-- args in Q23 result in Q46
			if (aux2(47)='1') then 
				-- >=2, shift left and add one to exponent
				result_mantisse := aux2(46 downto 24) ;--+ aux2(23); -- with rounding (optioneel?)
				aux := '1';
			else
				result_mantisse := aux2(45 downto 23) ;--+ aux2(22); -- with rounding
				aux := '0';
			end if;
			
			-- calculate exponent
			exponent_sum := ('0' & A_exponent) + ('0' & B_exponent) + aux - 127;
			
			if (exponent_sum(8)='1') then 
				if (exponent_sum(7)='0') then -- overflow
					result_exponent := "11111111";
					result_mantisse := (others => '0');
					result_sign := A_sign xor B_sign;
				else 									-- underflow
					result_exponent := (others => '0');
					result_mantisse := (others => '0');
					result_sign := '0';
				end if;
			else								  		 -- Ok
				result_exponent := exponent_sum(7 downto 0);
				result_sign := A_sign xor B_sign;
			end if;
			
		end if;
		
		result(22 downto 0) <= result_mantisse;
		result(30 downto 23) <= result_exponent;
    	result(31) <= result_sign;
      end if;
    end if;
    
    end process P1;
    
    
end Behavioral;
