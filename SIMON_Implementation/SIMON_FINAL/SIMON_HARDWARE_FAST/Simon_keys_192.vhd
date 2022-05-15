-- This is the component for generating subkeys

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET.all;

entity SIMON_keys_192 is -- all these signals are required to validate the testbench provided 
port
(	
	key_in_1    : in unsigned(63 downto 0); -- key input 1
	key_in_2 	: in unsigned(63 downto 0);-- key input 2
	z_in	  	: in unsigned(63 downto 0);-- input z
	key_out     : out unsigned(63 downto 0);-- key output1
	z_out 		: out unsigned(63 downto 0)-- output shifted z value 
);

end entity; 

architecture rtl of SIMON_keys_192 is

begin
 
		key_out <= (c xor (z_in and one) xor key_in_1 
		xor ROR_64(key_in_2,3) xor ROR_64(key_in_2,4)); -- generate key 
	
		z_out <= shift_right(z_in,1); -- shift value for z 

end architecture;