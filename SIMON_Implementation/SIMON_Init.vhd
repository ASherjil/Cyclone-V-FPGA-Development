library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIMON_Init is 
port
(	
	clk              : in  std_logic;
    reset_n            : in  std_logic;
 
	key_length : in std_logic_vector(1 downto 0); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
	key_valid : in std_logic; -- enable intialisation = '1', disable = '0'
	key_word_in : inout std_logic_vector(31 downto 0); -- key for initialising the encyrption algorithm 
	
	nrSubkeys : out integer -- used for the next stage: encryption
);

end entity; 

architecture rtl of SIMON_Init is
--------------------------------------Intermediate signals and array for initialisation 
type t_subkeys is array(0 to 71) of unsigned(63 downto 0);
signal subkeys : t_subkeys;

signal sub_key_first : unsigned(31 downto 0) := (others=> '0');
signal sub_key_second : unsigned(31 downto 0) := (others=> '0');

signal key_64bit : unsigned(63 downto 0);
type t_key_64bit is array(0 to 1) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
--------------------------------------------------------------------
-------------------------------------------------FUNCITON DEFINITION

function ROR_64(x : unsigned(63 downto 0); n : unsigned(31 downto 0))-- Rotate Right circular shift 32 bits
	return unsigned(63 downto 0) variable shifted : unsigned(63 downto 0);
begin
	shifted <= right_shift(x,n) OR left_shift(x,(64-n));
	return shifted;
end function;
---------------------------------------------------------------------
begin
	
	process(clk) is
		variable i: integer := 0;
	begin
		
		if (rising_edge(clk) and key_valid = '1') then -- only begin if key_valid = '1'
			
			
			if i = 4 then -- reset i variable
				i := 0;
			end if;
			
			case i is 
				
				when 0 =>sub_key_first <= key_word_in;
				when 1 => -- store into the first element of the array 
					sub_key_second <= key_word_in;
					key_64bit(0) <=  sub_key_second & sub_key_first; -- store 64-bit key (second<<31 | first)
					
				when 2=>sub_key_first <= key_word_in; 
				when 3=> -- store into the second element of the array
					sub_key_second <= key_word_in;
					key_64bit(1) <= sub_key_second & sub_key_first; -- store 64-bit key (second<<31 | first)				
					
				when others=>
					null; -- do nothing 
				
			i := i+1;-- increment 
			
		end if;
	end process;
	
		
	process(clk,reset_n) is 
	
		variable c : unsigned(63 downto 0):= x"fffffffffffffffc"; 
		variable z : unsigned(63 downto 0);
		variable i : unsigned(63 downto 0);
		
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 
					key_valid <= '0';		
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if key_valid = '0' then -- is key_valid = 0 then begin initialisation 
					
						if key_len = "00" then  -- key length is 128-bit
						
							z := x"7369f885192c0ef5"; -- assign value to z
							nrSubkeys <= 68; -- nrsubkeys 
							
							subkeys(1) <= key_64bit(0);
							subkeys(0) <= key_64bit(1);
							
							for i in 2 to 66 loop
								subkeys(i) <= c xor (z and 1) xor subkeys(i-1) xor ROR_64(x=>subkeys(i-1),n=>3) xor ROR_64(x=>subkeys(i-1),n=>4);
							end loop;
							
							subkeys(66) <= c xor 1 xor subkeys(64) xor ROR_64(x=>subkeys(65),n=>3) xor ROR_64(x=>subkeys(65),n=>4);
							subkeys(67) <= c xor subkeys(65) xor ROR_64(x=>subkeys(66),n=>3) xor ROR_64(x=>subkeys(66),n=>4);
							
						elsif key_len = "01" then -- key length is 192-bit
						
							
						end if;
				
					end if;
					
				end if;
			
			end if;
	
	end process;
		
end architecture;
