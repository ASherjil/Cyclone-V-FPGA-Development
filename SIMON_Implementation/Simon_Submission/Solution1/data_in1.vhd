-- Component used to store incoming 32-bit data into 64-bit signal array 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_C_PACKET.all; 

entity data_in1 is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	data_valid       : in  std_logic;
	data_word_in     : in  std_logic_vector(31 downto 0);
	
	data_check		 : out std_logic;
	data_input  	 : out t_data_in
);

end entity; 

architecture rtl of data_in1  is
signal data_seq : integer := 0;-- use signal for sequential process block  
begin 


-- purpose: To store incoming data in 64-bit array 
-- type   : sequential with sychronous reset 
-- inputs : clk, reset, data_valid  
-- outputs: data_input, data_check  
data_in : process(all) is --  process to take in data and store in an array  
			variable data1 : unsigned(31 downto 0);
			variable data2 : unsigned(31 downto 0);
		begin 
		
			if (rising_edge(clk)) then
			
				if (reset_n = '1') then 	
						
					if data_valid = '1' then	
					
						case data_seq is 
							when 0 =>
								data_check <= '0';
								data1 := unsigned(data_word_in);
								data_seq <= 1; -- move to the next state 
							when 1 =>
								data2:= unsigned(data_word_in);
								data_input(0) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								data_seq <= 2; -- move to the next state 
							when 2=>
								data1 := unsigned(data_word_in);
								data_seq<= 3;-- move to the next state 
							when 3=>
								data2 := unsigned(data_word_in);-- go back to the first state  
								data_input(1) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								data_check <= '1';
							when others=>
								data_seq <= 0;
						end case;
						
					end if; --close if statement for data_valid 
								
				elsif (reset_n = '0') then 
				
					data_input(0) <= (others=>'0');
					data_input(1) <= (others=> '0');
					data_check <= '0'; -- reset this data_check 
					data_seq <= 0;
					
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;

end architecture;