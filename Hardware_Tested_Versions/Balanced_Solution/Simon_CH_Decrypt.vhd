----------------This VHDL file is for the decryption module hybrid solution 1.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_CH_PACKET.all; 

entity SIMON_CH_Decrypt is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	data_valid		 : in  std_logic; -- signal to indicate data has been received 
	key_length 		 : in  std_logic_vector(1 downto 0); -- legnth of key 128-bit or 192-bit
	continue		 : in  std_logic; -- signal to control the decryption process
	data_input       : in  t_data_in; -- input data to be decrypted
	encryption		 : in  std_logic; -- signal to set to decrytin
	data_check 		 : in  std_logic; -- signal required to prevent decryption to start to early 
	subkeys          : in  t_subkeys; -- subkeys signal array 
	
	data_ready 		 : out std_logic;-- when '1' specifies decryption has been completed 
	x	     		 : out unsigned(63 downto 0);-- output 64-bit decrypted data1
	y				 : out unsigned(63 downto 0)-- output 64-bit decryoted data2 
);

end entity; 

architecture rtl of SIMON_CH_Decrypt is

signal int_x	: unsigned(63 downto 0) := (others=> '0');-- intermediate signals used for computed decrypted data
signal int_y	: unsigned(63 downto 0) := (others=> '0');-- intermediate signals used for computed decrypted data
signal seq_dec1 : integer := 0; -- intermediate signal used for implementing sequential design(decryption)

begin 


-- purpose: decrypt data using subkeys and encrypted text  
-- type   : sequential with synchronous reset 
-- inputs : clock,reset_n, data_valid,encryption, data_check, continue, subkeys  
-- outputs: x and y, signal array  
decryption_begin: process(clk,data_valid,encryption,data_check) is -- begin decrypting 
					variable j : integer := 67; -- for loop starts at 67 for both 128-bit and 192-bit key length 
				begin
				
				if rising_edge(clk) then 
					
					if reset_n = '0' then
					-- enter code for reset_n
					int_x <= (others=> '0');
					int_y <= (others=> '0');
					x 	  <= (others=> '0');
					y 	  <= (others=> '0');
					j 	  := 67; -- start at 67 
					
					seq_dec1 <= 0;-- reset signal to restart decryption 
					data_ready <= '0'; -- reset data_ready signal
					
					elsif reset_n = '1' then 
					
						if (data_valid = '0' and encryption = '0' and 
						data_check = '1' and continue = '1') then-- check all the necessary signals 
							
							if key_length = "00" then  -- 128-bit
							
								if (j >= 0) then  -- for loop implementation "for (int j=67;j >= 0;j -= 2)"
								
									case seq_dec1 is 
										when 0=>-------------------------RUN ONLY ONCE{-
											int_x <=( data_input(0) xor f(data_input(1)) )
											xor subkeys(j);
											seq_dec1 <= 1;
										when 1=>
											int_y <= (data_input(1) xor f(int_x) )
											xor subkeys(j-1);
											j := j-2; -- decrement for loop variable 
											seq_dec1 <= 2;
										when 2=> -----------for loop start 
											int_x <= (int_x xor f(int_y)) 
											xor subkeys(j); 
											seq_dec1 <= 3;
										when 3=>
											int_y <= (int_y xor f(int_x)) 
											xor	subkeys(j-1);
											j := j-2; -- decrement by 2 
											seq_dec1 <= 2; -- ONLY go back to the state 2
										------------------------------------------------------
										when others=> null; -- do nothing 
									end case;
									
								else-- for loop from i = nrSubkeys-1  0 has finished 
									data_ready <= '1';-- data_ready is now 1, decryption done 
									x <= int_x;
									y <= int_y; -- data has been decrypted now assign values to x 
									-- y 
								end if;-- close if statement for j, for loop implementation 
							
							elsif key_length = "01" then -- if key is 192-bit  
								
								if (j >= 0) then -- for loop implementation 
								
									case seq_dec1 is  
										when 0=>
											int_x <= data_input(1);
											int_y <= (data_input(0) xor subkeys(j+1) )
											xor f(data_input(1));
												
											seq_dec1 <=1; -- move to the next state 
											
										when 1=>
											int_x <= (int_x xor f(int_y) )
											xor subkeys(j);
											
											seq_dec1 <= 2;
										when 2=>
											int_y <= (int_y xor f(int_x) )
											xor subkeys(j-1);
											j := j-2; -- decrement for loop variable
											seq_dec1 <= 1; -- now go back to state 1
											
										when others=> null; -- do nothing
										
									end case;
								else -- now the for loop has ended 
									
									data_ready <= '1';-- data_ready is now 1, decryption done 
									x <= int_x;
									y <= int_y;
										
								end if; -- close if statement for "for loop" j >= 0
								
							end if;-- close if statement for key length 
						
						end if; -- close if statement for data_valid, encryption, data_check 
								-- and continue signals 
						
					end if; -- close if statement for reset_n 
					
				end if;-- close if statement for rising edge of clock 
				
end process decryption_begin;


end architecture;