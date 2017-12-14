----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2017 03:30:54 PM
-- Design Name: 
-- Module Name: DD2_FP_Biquad - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DD2_FP_Biquad is
port(
        
        
        sample_in  : in  std_logic_vector(31 downto 0);
        sample_out : out std_logic_vector(31 downto 0);
        b0         : in  std_logic_vector(31 downto 0);
        b1         : in  std_logic_vector(31 downto 0);
        b2         : in  std_logic_vector(31 downto 0);
        a1         : in  std_logic_vector(31 downto 0); -- Make sure to provide -a1
        a2         : in  std_logic_vector(31 downto 0); -- Make sure to provide -a2
        
        clk        : in  std_logic;
        
        reset      : in  std_logic;
        
        start      : out std_logic;
        
        done      : out std_logic
    );
end DD2_FP_Biquad;

architecture Behavioral of DD2_FP_Biquad is

-- history registers to save the previous inputs and outputs
signal in_Reg_T1    : std_logic_vector (31 downto 0) := (others => '0');
signal in_Reg_T2    : std_logic_vector (31 downto 0) := (others => '0');
signal out_Reg_T1   : std_logic_vector (31 downto 0) := (others => '0');
signal out_Reg_T2   : std_logic_vector (31 downto 0) := (others => '0');
signal uitgang      : std_logic_vector (31 downto 0) := (others => '0');
signal ingang       : std_logic_vector (31 downto 0) := (others => '0');

--control registers
signal done_sum     : std_logic := '0';
signal done_mul     : std_logic := '0';
signal sig_start    : std_logic := '0';
signal state        : std_logic_vector (2 downto 0) := (others => '0');
signal operation       : std_logic_vector (1 downto 0) := (others => '0');


--signals for the the adder to work
signal add_a        : std_logic_vector (31 downto 0) := (others => '0');
signal add_b        : std_logic_vector (31 downto 0) := (others => '0');
signal add_result   : std_logic_vector (31 downto 0) := (others => '0');
signal add_reset    : std_logic := '0';
signal add_done     : std_logic := '0';
signal add_start    : std_logic := '0';

--signals for the multiplier to work
signal mul_a            : std_logic_vector (31 downto 0) := (others => '0');
signal mul_b            : std_logic_vector (31 downto 0) := (others => '0');
signal mul_result   : std_logic_vector (31 downto 0) := (others => '0');
signal mul_reset    : std_logic := '0';
signal mul_done     : std_logic := '0';
signal mul_start    : std_logic := '0';

signal out_mul_result   : std_logic_vector (31 downto 0) := (others => '0');
signal in_mul_result    : std_logic_vector (31 downto 0) := (others => '0');
signal sum_result_1     : std_logic_vector (31 downto 0) := (others => '0'); 
signal temp_result      : std_logic_vector (31 downto 0) := (others => '0');     
signal sum_result_2     : std_logic_vector (31 downto 0) := (others => '0'); 



begin

adder: entity work.DD2_FP_Adder port map(
clk => clk,
a => add_a,
b => add_b,
result => add_result,
reset => add_reset,
done => add_done,
start => add_start
);

multiplier: entity work.DD2_FP_Multiplier port map(
clk => clk,
a => mul_a,
b => mul_b,
result => mul_result,
reset => mul_reset,
done => mul_done,
start => mul_start
);

biquad :process(reset,clk,sig_start,state)
variable var_in_Reg_T2 : std_logic_vector (31 downto 0) := (others => '0');
variable var_in_Reg_T1 : std_logic_vector (31 downto 0) := (others => '0');
variable var_out_Reg_T2 : std_logic_vector (31 downto 0) := (others => '0');
variable var_out_Reg_T1 : std_logic_vector (31 downto 0) := (others => '0');

begin 

if reset='1' then
   uitgang <= (others => '0');
   state <= (others => '0');
   done <= '0';
else 
    if rising_edge(clk) then
        
        case state is
            -- here the registers should be passed from uitgang -> tijdsvertraging1 -> tijdsvertraging 2 
            when "000" =>
                          var_in_Reg_T2 := in_Reg_T1;
                          var_in_Reg_T1 := sample_in;
                          var_out_Reg_T1:=uitgang;
                          var_out_Reg_T2:=out_Reg_T1;
                          state <= "001";
            
            when "001" => 
                        case(operation) is
                        -- multiplication of the register met tijdsvertraging 2 met coefficient b2
                        when "00" =>
                                    mul_reset <= '1';
                                    mul_a <= b2;
                                    mul_b <= var_in_Reg_T2;
                                    operation <= "01";
                         when "01" =>
                                    if (mul_done = '1') then
                                        in_mul_result <= mul_result;
                                        mul_start <= '0';
                                        operation <= "10";
                                    else
                                        mul_reset <= '0'; 
                                        mul_start <= '1';    
                                    end if; 
                         -- multiplication of the register met tijdsvertraging 2 met coefficient b2                                                     
                         when "10" => 
                                    mul_reset <= '1';
                                    mul_a <= a2;
                                    mul_b <= var_out_Reg_T2;
                                    operation <= "11";
                           
                        when "11" =>
                                    if (mul_done = '1') then
                                        out_mul_result <= mul_result;
                                        mul_start <= '0';
                                        state <= "010";
                                        operation <= "00";
                                     else
                                        mul_reset <= '0';
                                        mul_start <= '1';
                                     end if; 
                        when others => operation <= "00"; 
                        end case;
                     
           when "010" => 
                        case(operation) is
                        when "00" =>
                                    add_a <= out_mul_result;
                                    add_b <= in_mul_result; 
                                    add_reset <= '1';
                                    operation <= "01";
                         when "01" => 
                                   if (add_done = '1') then
                                   sum_result_2 <= add_result;
                                   add_start <= '0';
                                   state <= "011";
                                   operation <= "00";
                                   else
                                   add_reset <= '0';
                                   add_start <= '1';
                                   end if; 
                          when others => operation <= "00";         
                          end case;
            
            when "011" =>
                        case(operation) is
                        -- multiplication of the register met tijdsvertraging 1 met coefficient b1
                        when "00" =>
                                    mul_reset <= '1';
                                    mul_a <= b1;
                                    mul_b <= var_in_Reg_T1;
                                    operation <= "01";
                        when "01" =>
                                    if (mul_done = '1') then
                                        in_mul_result <= mul_result;
                                        mul_start <= '0';
                                        operation <= "10";
                                    else
                                        mul_reset <= '0';
                                        mul_start <= '1';     
                                    end if; 
                        -- multiplication of the register met tijdsvertraging 1 met coefficient a1                                                       
                        when "10" => 
                                    mul_reset <= '1';
                                    mul_a <= a1;
                                    mul_b <= var_out_Reg_T1;
                                    operation <= "11";
                                                     
                        when "11" =>
                                    if (mul_done = '1') then
                                       out_mul_result <= mul_result;
                                       mul_start <= '0';
                                       state <= "100";
                                       operation <= "00";
                                    else
                                       mul_reset <= '0';
                                       mul_start <= '1';                                       
                                    end if;  
                        when others => operation <= "00";
                        end case;
         when "100" =>
                      case(operation) is 
                      when "00" =>
                                    add_a <= out_mul_result;
                                    add_b <= in_mul_result;
                                    add_reset <= '1';
                                    operation <= "01";
                      when "01" => 
                                    if (add_done = '1') then
                                        temp_result <= add_result;
                                        add_start <= '0';
                                        operation <= "10";
                                    else
                                        add_reset <= '0';
                                        add_start <= '1';
                                    end if;
                       when "10" =>
                                   add_a <= sum_result_1;
                                   add_b <= temp_result;
                                   add_reset <= '1';
                                   operation <= "11";
                        when "11" => 
                                     if (add_done = '1') then
                                    sum_result_1 <= add_result;
                                    add_start <= '0';
                                    state <= "101";
                                    operation <= "00";
                                  else
                                    add_reset <= '0';
                                    add_start <= '1';
                                  end if;  
                       when others => operation <= "00";         
                       end case;
         
         when "101" =>
                      case(operation) is
                      -- multiplication of the register met ingang met coefficient b0
                      when "00" =>
                                  mul_reset <= '1';
                                  mul_a <= ingang;
                                  mul_b <= b0;   
                                  operation <= "01";
                      when "01" =>
                                  if (mul_done = '1') then
                                    in_mul_result <= mul_result;
                                    mul_start <= '0';
                                   state <= "110";
                                   operation <= "00";
                                  else
                                    mul_reset <= '0';
                                    mul_start <= '1';     
                                  end if; 
                       when others => operation <= "00";           
                       end case;
           when "110" =>
                        case(operation) is 
                        when "00" =>
                                    add_a <= out_mul_result;
                                    add_b <= sum_result_1;
                                    add_reset <= '1';
                                   operation <= "01";
                        when "01" => 
                                    if (add_done = '1') then
                                        uitgang <= add_result;
                                        add_start <= '0';
                                        state <= "111"; -- nieuwe staat te schrijven (idle state wat te doen als de biquad gedaan heeft)
                                        operation <= "00";
                                    else
                                        add_reset <= '0';
                                        add_start <= '1';
                                    end if; 
                        when others => operation <= "00";         
                        end case;
        when "111" =>
                      --idle case
                      --hier wordt eventueel gewacht op een start om het process opnieuw te starten
                      
                                 
                               
                                    
        when others => state <= "000";
                      
              
        end case;
    
   
        
    
    end if; 
end if;



end process;

sample_out <= uitgang ;

end Behavioral;
