-- This is the component for ecnrypting data 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SIMON_Enc192 is -- all these signals are required to validate the testbench provided 
port
(	
	encryption  : in std_logic;
	x_in    	: in unsigned(63 downto 0);-- take x as input(data1)
	y_in 		: in unsigned(63 downto 0);-- take y as input(data2) 
	subkey_in1	: in unsigned(63 downto 0);-- take subkey1 as input
	subkey_in2	: in unsigned(63 downto 0);-- take subkey2 as input
	x_out		: out unsigned(63 downto 0);-- output the new x value
	y_out		: out unsigned(63 downto 0)-- output the new y value  
);

end entity; 

architecture rtl of SIMON_Enc192 is
-----------------------------------------------------------FUNCTIONS-------------------
function ROL_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate LEFT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_left(x,n) OR shift_right(x,(64-n)) );
	return unsigned(shifted);
end function;

function f(x : in unsigned(63 downto 0)) -- helper function for emulating the "R2" function
		return unsigned is variable rolled : unsigned(63 downto 0);
begin
		rolled := ( (ROL_64(x,1) and ROL_64(x,8)) xor ROL_64(x,2) );
		return unsigned(rolled);
end function;
-------------------------------------------------------------------------------------------
signal y_int : unsigned(63 downto 0); -- intermediate signal for storing y value

begin

-- purpose: Encrypt data
-- type   : Combinational with an else statement to prevent latch  
-- inputs : encryption, x_in, y_in, subkey_in1,subkey_in2
-- outputs: x_out , y_out
process(all) is 
begin 

	if (encryption = '1') then 
		y_int <= (y_in xor f(x_in)) xor subkey_in1; -- compute y
		y_out <= y_int; -- assign output signal to y_int
		x_out <= (x_in xor f(y_int)) xor subkey_in2;-- compute x
	else -- do not execute if encryption is 0
		y_out <= (others=> '0');
		x_out <= (others=> '0');
	end if;
end process; 
		
end architecture;