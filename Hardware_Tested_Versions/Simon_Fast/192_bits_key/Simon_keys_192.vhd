-- This is the component for generating subkeys for the performance based solution. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET.all;

entity SIMON_keys_192 is -- all these signals are required to validate the testbench provided 
port
(	
	key_in_1     : in unsigned(63 downto 0);-- key input 1
	key_in_2 	 : in unsigned(63 downto 0);-- key input 2
	key_in_3	 : in unsigned(63 downto 0);-- key input 3
	z_in	  	 : in unsigned(63 downto 0);-- input z
	key_out1     : out unsigned(63 downto 0);-- key output1
	key_out2     : out unsigned(63 downto 0);-- key output1
	z_out 		 : out unsigned(63 downto 0)-- output z value shifted twice
);

end entity; 

architecture rtl of SIMON_keys_192 is

signal int_z 	  : unsigned(63 downto 0);
signal int_subkey : unsigned(63 downto 0);
 
begin
 
		int_subkey <= (c xor (z_in and one) xor key_in_1 
		xor ROR_64(key_in_3,3) xor ROR_64(key_in_3,4)); -- generate key 
		
		key_out1 <= int_subkey;-- output the first produced subkey 

		int_z <= shift_right(z_in,1);-- shift z once 
			
		key_out2 <= (c xor (int_z and one) xor key_in_2 
		xor ROR_64(int_subkey,3) xor ROR_64(int_subkey,4)); -- generate key 
		
		z_out <= shift_right(int_z,1); -- shift z once for ouput 

end architecture;