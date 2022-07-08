-- This VHDL connects with the HPS component to store incoming data.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_CH_PACKET.all;

entity Simon_CH_store is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in  std_logic;
	reset_n 	     : in  std_logic;
	data_valid       : in  std_logic;--signal to start concatenate data in 64-bit array 
	key32_1 		 : in  unsigned(31 downto 0);
	key32_2 		 : in  unsigned(31 downto 0);
	key32_3 		 : in  unsigned(31 downto 0);
	key32_4 		 : in  unsigned(31 downto 0);
	key32_5 		 : in  unsigned(31 downto 0);
	key32_6 		 : in  unsigned(31 downto 0);
	data32_1		 : in  unsigned(31 downto 0);
	data32_2		 : in  unsigned(31 downto 0);
	data32_3		 : in  unsigned(31 downto 0);
	data32_4		 : in  unsigned(31 downto 0);
	key_valid        : in  std_logic; --signal to start concatenate data in 64-bit array 
	
	data_check       : out std_logic; -- signal to specify data has been stored
	key_start        : out std_logic; -- signal to specif keys have been stored 
	key_64bit        : out t_key_64bit;-- keys stored in array of 64-bit 
	data_input       : out t_data_in-- incoming data stored in array of 64-bit 
);
end entity; 

architecture rtl of Simon_CH_store is
begin 
--------------------------------------------------------------------------PERFORM CONCATENATIONS-----
-- purpose: store encrypted data 64-bit array 
-- type   : sequential with synchronous reset 
-- inputs : clock,reset_n, data_valid 
-- outputs: data_input signal array ,data_check 
data_in : process(clk,reset_n) is --  process to take in data and store in an array  
		begin 
		
			if (rising_edge(clk)) then
			
				if (reset_n = '1') then 
					if (data_valid = '1') then 
						data_input(0) <= data32_2 & data32_1;
						data_input(1) <= data32_4 & data32_3;
						data_check <= '1';-- now begin decryption 
					end if;
				elsif (reset_n = '0') then 
					data_check <= '0'; -- reset this data_check to stop decryption 
					data_input(0) <= (others=> '0');
					data_input(1) <= (others=> '0');
					data_check <= '0'; -- stop decryption 
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;

-- purpose: store 32-bit keys as an array of 64-bit key
-- type   : sequential with synchronous reset 
-- inputs : clock and key_valid signal 
-- outputs: key_64bit and key_start
key_in:	process(clk,reset_n) is --  process to take in key and store in an array  
		begin
	
		if (rising_edge(clk)) then -- only begin if key_valid = '1'
			
			if (reset_n = '1') then 
				if (key_valid = '1') then 			
						
						key_64bit(0) <= key32_2 & key32_1;
						key_64bit(1) <= key32_4 & key32_3;
						key_64bit(2) <= key32_6 & key32_5;
						key_start <= '1'; -- now begin initialisation 
						
				end if; -- close if statement for key_valid 	
			
			elsif reset_n = '0' then 
				
				key_64bit(0) <= (others=> '0');
				key_64bit(1) <= (others=> '0');
				key_64bit(2) <= (others=> '0');
				key_start <= '0';-- do this to prevent initialisation 
			
			end if; -- close if statement for reset_n 
		
		end if;-- close if statement for rising_edge clock 
end process key_in;

------------------------------------------------------------------------------------END 
end architecture;

