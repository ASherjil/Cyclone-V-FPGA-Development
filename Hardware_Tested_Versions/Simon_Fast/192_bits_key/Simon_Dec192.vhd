-- This is the component for ecnrypting data 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET.all;

entity SIMON_Dec192 is -- all these signals are required to validate the testbench provided 
port
(	
	x_in    	: in unsigned(63 downto 0);-- take x as input(data1)
	y_in 		: in unsigned(63 downto 0);-- take y as input(data2) 
	subkey_in1	: in unsigned(63 downto 0);-- take subkey1 as input
	subkey_in2	: in unsigned(63 downto 0);-- take subkey2 as input
	x_out		: out unsigned(63 downto 0);-- output the new x value
	y_out		: out unsigned(63 downto 0)-- output the new y value  
);

end entity; 

architecture rtl of SIMON_Dec192 is

signal x_int : unsigned(63 downto 0); -- intermediate signal for storing x value

begin

	x_int <= (x_in xor f(y_in)) xor subkey_in1; -- compute y
	x_out <=  x_int; -- assign output signal to y_int
	y_out <= (y_in xor f(x_int)) xor subkey_in2;-- compute x
				
end architecture;