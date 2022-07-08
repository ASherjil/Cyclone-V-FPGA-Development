-- This is the VHDL component for generating subkeys 128-bit 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET_128.all; -- use the package file for constants and types

entity SIMON_keys_128 is -- all these signals are required to validate the testbench provided 
port
(	
	key_in_1     : in  unsigned(63 downto 0);-- key input 1
	key_in_2 	 : in  unsigned(63 downto 0);-- key input 2
	z_in	  	 : in  unsigned(63 downto 0);-- input z
	key_out1     : out unsigned(63 downto 0);-- key output1
	key_out2     : out unsigned(63 downto 0);-- key output1
	z_out 		 : out unsigned(63 downto 0)-- output shifted z value 
);

end entity; 

architecture rtl of SIMON_keys_128 is

signal int_z 	  : unsigned(63 downto 0);
signal int_subkey : unsigned(63 downto 0);

begin
 
	int_subkey <= (c xor (z_in and one) xor key_in_1 
	xor ROR_64(key_in_2,3) xor ROR_64(key_in_2,4)); -- generate key 
	
	key_out1 <= int_subkey; -- output the newly generated subkey 

	int_z <= shift_right(z_in,1); -- shift the value of z and store in intermediate signal
		
	key_out2 <= (c xor (int_z and one) xor key_in_2 
	xor ROR_64(int_subkey,3) xor ROR_64(int_subkey,4)); -- generate the next subkeys and output 
	
	z_out <= shift_right(int_z,1); -- shift value for z 


end architecture;