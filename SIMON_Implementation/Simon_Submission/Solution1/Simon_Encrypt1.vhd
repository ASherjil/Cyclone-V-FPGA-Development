----------VHDL Implementation of Simon Encryption 
----------This uses a while loop and variables to instantly
----------Encryption data. It makes the output of 1 statement the 
----------input of another. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_C_PACKET.all; 

entity SIMON_Encrypt1 is -- all these signals are required to validate the testbench provided 
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
	
	data_flag1 		 : out std_logic;
	data_out1   	 : out unsigned(31 downto 0) 
);

end entity; 

architecture rtl of SIMON_Encrypt1  is
signal seq1 : integer := 0; -- intermediate signal used for implementing sequential design(encryption)
begin 



-- purpose: To encrypt data 
-- type   : sequential with sychronous reset 
-- inputs : clk, reset, key_valid, key_start, encryption  
-- outputs: data_out1, data_flag2 
encryption_begin: process(all) is  -- begin encrypting 
				variable k : integer := 0; -- intermediate variable for loop implementation 
				variable x : unsigned(63 downto 0); -- store the value of the encrypted data
				variable y : unsigned(63 downto 0);-- store the value of the encrypted data
				variable t : unsigned(63 downto 0);-- intermedate value for 192-bit keys 
				variable int_x : t_subkeys;-- storage for intermediate data values
				variable int_y : t_subkeys;-- storage for intermediate data values
			begin	
				
				if rising_edge(clk) then 
									
					if reset_n = '0' then -- reset everything
					
					x := (others => '0');  
					y := (others=> '0');
					int_x :=(others=> (others=>'0'));
					int_y := (others=> (others=>'0'));
					seq1 <= 0; -- reset signal for sequential process
					data_flag1 <= '0'; -- data_ready signal 
					data_out1 <= (others=>'0');-- signal for data_word_out
					k := 0;-- reset while loop variable 
				
					elsif reset_n = '1' then 
						
						if (data_valid = '0' and 
						encryption = '1' and data_check = '1') then
							
							if key_length = "00" then -- key length is 128-bit
						
									case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
											when 0=>
												int_x(0) := data_input(0);
												int_y(0) := data_input(1); 
												
												seq1 <= 1;
											when 1=>
												while k < 68 loop -- encrypt the data all in 1 clock cycle 
														int_y(k+1) := int_y(k) xor f(int_x(k));
														int_y(k+2) := int_y(k+1) xor subkeys(k);	
														int_x(k+1) := int_x(k) xor f(int_y(k+2));
														int_x(k+2) := int_x(k+1) xor subkeys(k+1);
													k := k +2; -- increment by 2
												end loop;
												
												seq1<= 2;
							
											when 2 =>
												y := int_y(68);
												x := int_x(68);
												seq1 <= 3;-- increment 
											when 3 =>
												data_flag1 <= '1'; -- make data_ready = '1'											
												data_out1 <= (x(31 downto 0)); -- transfer first peice of data 
												seq1 <= 4;
											when 4 =>									
												data_out1 <= (x(63 downto 32));  
												seq1 <= 5;
											when 5=>
												data_out1 <= (y(31 downto 0));
												seq1 <= 6;
												
											when 6=>
												data_out1 <= (y(63 downto 32));
												data_flag1 <= '0'; -- make data_ready = '0'	
											-- stay in state 7 unless reset 
											when others=>
												seq1 <= 0; -- do nothing 
									end case;
								
								
							elsif key_length = "01" then -- key length is 192-bit
									
									case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
										when 0=>
											int_x(0) := data_input(0);
											int_y(0) := data_input(1); 
					
											seq1 <= 1;
										when 1=>
											while k < 68 loop-- encrypt the data all in 1 clock cycle 
													int_y(k+1) := int_y(k) xor f(int_x(k));
													int_y(k+2) := int_y(k+1) xor subkeys(k);	
													int_x(k+1) := int_x(k) xor f(int_y(k+2));
													int_x(k+2) := int_x(k+1) xor subkeys(k+1);
												k := k +2; -- increment by 2
											end loop;
											seq1<= 2;
										when 2 =>
											x := int_x(68);
											y := int_y(68);
											
											seq1 <= 3;
										when 3=>
											y := y xor f(x);
											seq1 <= 4;
										when 4=>
											y := y xor subkeys(68);
											seq1 <= 5;
										when 5 =>
											t := x;
											seq1 <= 6;
										when 6 =>
											x := y;
											seq1 <= 7;
										when 7 =>
											y := t;
											seq1 <= 8;
										when 8 =>
											data_flag1 <= '1'; -- this makes data_ready <= '1'
											data_out1 <= (x(31 downto 0)); -- assign values for data_out1
											seq1 <= 9;
										when 9=>
											data_out1 <= (x(63 downto 32));
											seq1 <= 10;
										when 10=>
											data_out1 <= (y(31 downto 0));
											seq1 <= 11;
										when 11=>
											data_out1 <= (y(63 downto 32));
											data_flag1 <= '0';-- this makes data_ready <= '0'
											-- stay in state 12 unless reset 
										when others=>
											seq1<= 0;
										end case;
							end if; -- close if statement for key length 
							
						end if; -- close if statement for data valid and encryption 
						
					end if; -- close if statement for reset_n
					
				end if; -- close if statement for rising edge clock 
end process encryption_begin;



end architecture;

