----------VHDL Implementation of Simon Decryption 
----------This uses a while loop and variables to instantly
----------decrypt data. It makes the output of 1 statement the 
----------input of another. 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_C_PACKET.all; 

entity SIMON_Decrypt1 is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	data_valid       : in  std_logic; 
	data_check 		 : in  std_logic;		
	encryption 		 : in  std_logic;
	key_length       : in  std_logic_vector(1 downto 0);
	subkeys			 : in  t_subkeys;
	data_input       : in  t_data_in;
	
	data_flag2 		 : out std_logic;
	data_out2   	 : out unsigned(31 downto 0) 
);

end entity; 

architecture rtl of SIMON_Decrypt1  is
signal seq2: integer := 0; -- intermediate signal used for implementing sequential design(decryption)
begin 



-- purpose: To decrypt data 
-- type   : sequential with sychronous reset 
-- inputs : clk, reset, key_valid, key_start, encryption  
-- outputs: data_out2, data_flag2 
decryption_begin: process(all) is -- begin decrypting 
variable k : integer := 0; -- variable for while loop 
variable x : unsigned(63 downto 0);
variable y : unsigned(63 downto 0);
variable t : unsigned(63 downto 0);
variable int_x : t_subkeys;
variable int_y : t_subkeys;

				begin
				
				if rising_edge(clk) then 
					
					if reset_n = '0' then
				
						seq2 <= 0; -- reset everything
						x := (others=> '0');
						y := (others=> '0');
						int_x :=(others => (others => '0'));
						int_y := (others => (others => '0'));
						data_flag2 <= '0';
						data_out2 <= (others=> '0');
						k := 0;
					
					elsif reset_n = '1' then 
					
						if (data_valid = '0' and 
						encryption = '0' and data_check = '1') then
							
							if key_length = "00" then  -- 128-bit
							
								case seq2 is  
										
										when 0=>
										
											int_x(0) := data_input(0);
											int_y(0) := data_input(1);									
											seq2 <=1;
											
										when 1=>
												while k < 67 loop -- decrypt data in 1 clock cycle 
														int_x(k+1) := int_x(k) xor f(int_y(k));
														int_x(k+2) := int_x(k+1) xor subkeys(67-k);	
														int_y(k+1) := int_y(k) xor f(int_x(k+2));
														int_y(k+2) := int_y(k+1) xor subkeys(67 - (k+1));
													k := k +2; -- increment by 2
												end loop;
											seq2<= 2;
										when 2=>
											x := int_x(68);
											y := int_y(68);	
											seq2<= 3;
										when 3=>
											data_out2 <= x(31 downto 0);-- output the first 32-bit 
											data_flag2 <= '1';-- data_ready is now 1
											seq2 <= 4;
										when 4=>
											data_out2 <= x(63 downto 32);
											seq2 <= 5;   
										when 5=>         
											data_out2 <= y(31 downto 0);
											seq2 <= 6; 
										when 6=>
											data_out2 <= y(63 downto 32);
											data_flag2 <= '0'; -- now stop, data_ready <= '0'
											
										when others=> 
											seq2 <= 0; -- do nothing
										
									end case;
							
							elsif key_length = "01" then -- if key is 192-bit  
								
								case seq2 is  
										when 0=>
											t := data_input(1); -- t = y
											seq2 <= 1;
										when 1=>
											y := data_input(0); -- y = x
											seq2 <= 2;
										when 2=>
											x := t;
											seq2 <= 3;
										when 3=>
											y := y xor subkeys(68);
											seq2 <= 4;
										when 4=>
											y := y xor f(x);
											seq2 <= 5;
										when 5=>
											int_x(0) := x;
											int_y(0) := y;									
											seq2 <=6;
											
										when 6=>
												while k < 68 loop-- decrypt data in 1 clock cycle 
														int_x(k+1) := int_x(k) xor f(int_y(k));
														int_x(k+2) := int_x(k+1) xor subkeys(67-k);	
														int_y(k+1) := int_y(k) xor f(int_x(k+2));
														int_y(k+2) := int_y(k+1) xor subkeys(67 - (k+1));
													k := k +2; -- increment by 2
												end loop;
												
											seq2 <= 7;
										when 7=>
											x := int_x(68);
											y := int_y(68);	
											seq2 <= 8;
										when 8=> -- transfer data to data_word_out 
											data_out2 <= x(31 downto 0); 
											data_flag2 <= '1';-- data_ready is now 1
											seq2 <= 9;
										when 9=>
											data_out2 <= x(63 downto 32);
											seq2 <= 10;
										when 10=>
											data_out2 <= y(31 downto 0);
											seq2 <= 11; 
										when 11=>
											data_out2 <= y(63 downto 32);
											data_flag2 <= '0'; -- now stop, data_ready <= '0'
											-- stay in state 11 unless reset 
										when others=> 
											seq2 <= 0; -- does nothing
										
									end case;
								
							end if;-- close if statement for key length 
						
						end if; -- close if statement for data_valid and encryption 
						
					end if; -- close if statement for reset_n 
					
				end if;-- close if statement for rising edge of clock 
				
end process decryption_begin;



end architecture;
