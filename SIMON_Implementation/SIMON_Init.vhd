library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIMON_Init is 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
 
	key_length : in std_logic_vector(1 downto 0); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
	key_valid : in std_logic; -- enable intialisation = '1', disable = '0'
	key_word_in : in std_logic_vector(31 downto 0); -- key for initialising the encyrption algorithm 
	
	nrSubkeys : out integer -- used for the next stage: encryption
);

end entity; 

architecture rtl of SIMON_Init is
--------------------------------------Intermediate signals and array for initialisation 
type t_subkeys is array(0 to 71) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;

--signal sub_key_first : unsigned(31 downto 0) := (others=> '0');
--signal sub_key_second : unsigned(31 downto 0) := (others=> '0');

type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
----------------------------------------------------------------------------------------

--------------------------------------------------------FUNCITON DEFINITION
function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate Right circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;
-----------------------------------------------------------------------------
--signal i : integer:=0;
begin
	
	process(clk,key_valid) is
		variable i: integer := 0;
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
		
		if (rising_edge(clk) and key_valid = '1') then -- only begin if key_valid = '1'
			
				if i = 6 then -- reset i signal 
					i := 0;
				end if;
				
				case i is 
					
					when 0 =>sub_key_first := unsigned(key_word_in);
					when 1 => -- store into the first element of the array 
						sub_key_second := unsigned(key_word_in);
						key_64bit(0) <=  unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
						
					when 2=>sub_key_first := unsigned(key_word_in); 
					when 3=> -- store into the second element of the array
						sub_key_second := unsigned(key_word_in);
						key_64bit(1) <= unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)				
						
					when 4=>sub_key_first := unsigned(key_word_in);
						
					when 5=>-- store into the second element of the array
						sub_key_second := unsigned(key_word_in);
						key_64bit(2) <= unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
						
					when others=>
						null; -- do nothing 
					
				end case;
	
				i := i+1;-- increment 
			
		end if;-- if for rising_edge clock 
	end process;
	
		
	process(clk,reset_n) is 
	
		variable c : unsigned(63 downto 0):= x"fffffffffffffffc"; 
		variable z : unsigned(63 downto 0);
		variable i : unsigned(63 downto 0);
		variable one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";
		
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 	
				-- enter code here  
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if key_valid = '0' then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit
						
							z := x"7369f885192c0ef5"; -- assign value to z
							nrSubkeys <= 68; -- nrsubkeys 
							
							subkeys(1) <= key_64bit(0);
							subkeys(0) <= key_64bit(1);
							
							for i in 2 to 66 loop
								subkeys(i) <= (c xor (z and one) xor subkeys(i-2) xor ROR_64(subkeys(i-1),3) xor ROR_64(subkeys(i-1),4));
								z:= shift_right(z,1);
							end loop;
							
							subkeys(66) <= (c xor one xor subkeys(64) xor ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4));
							subkeys(67) <= (c xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
							
						elsif key_length = "01" then -- key length is 192-bit
							
							z:= x"fc2ce51207a635db"; -- assign value to z
							nrSubkeys <= 69; -- nrsubkeys 
							
							subkeys(0) <= key_64bit(2);
							subkeys(1) <= key_64bit(1);
							subkeys(2) <= key_64bit(0);
							
							for i in 3 to 67 loop
								subkeys(i) <= (c xor (z and one) xor subkeys(i-2) xor ROR_64(subkeys(i-1),3) xor ROR_64(subkeys(i-1),4) );
								z:= shift_right(z,1);
							end loop;
							
							subkeys(67) <=	(c xor subkeys(64) xor ROR_64(subkeys(66), 3) xor ROR_64(subkeys(66), 4) );
							subkeys(68) <= (c xor one xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
							
						end if;
				
					end if;
					
				end if;
			
			end if;
	
	end process;
		
end architecture;
