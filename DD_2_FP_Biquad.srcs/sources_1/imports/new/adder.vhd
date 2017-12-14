library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity DD2_FP_Adder is
  port(A      : in  std_logic_vector(31 downto 0);
       B      : in  std_logic_vector(31 downto 0);
       clk    : in  std_logic;
       reset  : in  std_logic;
       start  : in  std_logic;
       done   : out std_logic;
       result : out std_logic_vector(31 downto 0)
       );
end DD2_FP_Adder;

architecture Arch of DD2_FP_Adder is


  signal A_mantissa, B_mantissa : std_logic_vector (24 downto 0);
  signal A_exp, B_exp           : std_logic_vector (8 downto 0);
  signal A_sgn, B_sgn           : std_logic;
  signal sum                    : std_logic_vector (31 downto 0) := (others => '0');
  signal mantissa_sum           : std_logic_vector (24 downto 0);
  signal sig_reset              :std_logic := '1';
  signal state                  :std_logic_vector (2 downto 0) := (others => '0');

begin

process (clk, sig_reset, state, start) is
    variable diff : signed(8 downto 0);
  begin
    if(sig_reset = '1') then
      state <= "000";
      done <= '0';                 
    elsif rising_edge(clk) then
      case state is
        when "000" =>
          if (start = '1') then
            A_sgn <= A(31);
            B_sgn <= B(31);
            A_mantissa <= "01" & A(22 downto 0);
            B_mantissa <= "01" & B(22 downto 0);
            A_exp <= '0' & A(30 downto 23); 
            B_exp <= '0' & B(30 downto 23);            
            state <= "001";
          end if;
          
          
        when "001" =>  
          if (signed(A_exp) - signed(B_exp))> 23 then
               mantissa_sum <= std_logic_vector(unsigned(A_mantissa));
               sum(31) <= A_sgn;
               state <= "100"; 
          elsif (signed(B_exp) - signed(A_exp))> 23 then
               mantissa_sum <= std_logic_vector(unsigned(B_mantissa));
               sum(31) <= B_sgn;
               A_exp <= B_exp;
               state <= "100";
          elsif(unsigned(A_exp) < unsigned(B_exp)) then
               A_mantissa <= '0' & A_mantissa(24 downto 1);
               A_exp <= std_logic_vector((unsigned(A_exp)+1));
          elsif (unsigned(B_exp) < unsigned(A_exp)) then
               B_mantissa <= '0' & B_mantissa(24 downto 1);
               B_exp <= std_logic_vector((unsigned(B_exp)+1));
          else
               state <= "010";
          end if;

        when "010" =>
          state <= "011";
          if (A_sgn xor B_sgn) = '0' then
            mantissa_sum <= std_logic_vector((unsigned(A_mantissa) + unsigned(B_mantissa)));
            sum(31)      <= A_sgn;
          elsif unsigned(A_mantissa) >= unsigned(B_mantissa) then
            mantissa_sum <= std_logic_vector((unsigned(A_mantissa) - unsigned(B_mantissa)));
            sum(31)      <= A_sgn;
          else
            mantissa_sum <= std_logic_vector((unsigned(B_mantissa) - unsigned(A_mantissa)));
            sum(31) <= B_sgn;
          end if;

        when "011" =>  
          if unsigned(mantissa_sum) = TO_UNSIGNED(0, 25) then
            mantissa_sum <= (others => '0');  
            A_exp <= (others => '0');
            state <= "100";     
          elsif(mantissa_sum(24) = '1') then  
            mantissa_sum <= '0' & mantissa_sum(24 downto 1);
            A_exp <= std_logic_vector((unsigned(A_exp)+ 1));
            state <= "100";
          elsif(mantissa_sum(23) = '0') then 
            for i in 22 downto 1 loop   
              if mantissa_sum(i) = '1' then
                mantissa_sum(24 downto 23-i) <= mantissa_sum(i+1 downto 0);
                mantissa_sum(22-i downto 0)  <= (others => '0');  
                A_exp<= std_logic_vector(unsigned(A_exp)- 23 + i);
                exit;
              end if;
            end loop;
            state <= "100";         
          else
            state <= "100";  
          end if;
           
        when "100" =>
          done <= '1';
          sum(22 downto 0) <= mantissa_sum(22 downto 0);
          sum(30 downto 23) <= A_exp(7 downto 0);
          if (start = '1') then
            state <= "000";
            done <= '0';
          end if;       
        when others => state <= "000";      
      end case;
    end if;
  end process;
  
  result <= sum;
  sig_reset <= reset;

end architecture;
