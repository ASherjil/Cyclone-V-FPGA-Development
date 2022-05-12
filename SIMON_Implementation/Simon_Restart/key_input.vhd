library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity key_input is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	key_length 		 : in std_logic_vector(1 downto 0):= (others => '0'); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
	key_valid 		 : in std_logic; -- enable intialisation = '1', disable = '0'
	key_word_in 	 : in std_logic_vector(31 downto 0):= (others => '0'); -- key for initialising the encyrption algorithm 
	
);

end entity; 

architecture rtl of key_input is
begin 


key_in:	process(all) is --  process to take in key and store in an array  
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
	
		if rising_edge(clk) then -- only begin if key_valid = '1'
		
			if reset_n = '1' then 
			
				if key_valid = '1' then -- only run when key_valid = '1' 
						
						case key_seq is 
							
							when 0 =>
								key_start <= '0'; -- do not initialise 
								sub_key_first := unsigned(key_word_in);
								key_seq <= 1;
								
							when 1 => -- store into the first element of the array 
								sub_key_second := unsigned(key_word_in);
								key_64bit(0) <=  unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
								key_seq <= 2;
								
							when 2=>
								sub_key_first := unsigned(key_word_in); 
								key_seq <= 3;
								
							when 3=> -- store into the second element of the array
								sub_key_second := unsigned(key_word_in);
								key_64bit(1) <= unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)				
								key_seq <= 4;
								
								if key_length = "00" then 
									key_start<= '1';-- begin initialisation 
								end if;
								
							when 4=>
								sub_key_first := unsigned(key_word_in);
								key_seq <= 5;
								
							when 5=>-- store into the second element of the array
								key_seq <= 0;
								sub_key_second := unsigned(key_word_in);
								key_64bit(2) <= unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
								
								if key_length = "01" then 
									key_start<= '1';-- begin initialisation 
								end if;
								
							when others=>
								key_seq <= 0; -- do nothing 
							
						end case;-- close case statement for key_seq  
		
				end if; -- close if statement for key_valid 
				
			elsif reset_n = '0' then 
			
				key_64bit(0) <= (others=> '0');
				key_64bit(1) <= (others=> '0');
				key_64bit(2) <= (others=> '0');
				key_seq <= 0;
				key_start <= '0';
				
			end if; -- close if statement for reset_n 
			
		end if;-- if for rising_edge clock 
		
end process key_in;