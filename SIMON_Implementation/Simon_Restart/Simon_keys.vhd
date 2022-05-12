library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SIMON_keys is -- all these signals are required to validate the testbench provided 
port
(	
	key_in_1    : in unsigned(63 downto 0); -- key input 1
	key_in_2 	: in unsigned(63 downto 0);-- key input 2
	z_in	  	: in unsigned(63 downto 0);-- input z
	key_out     : out unsigned(63 downto 0);-- key output1
	z_out 		: out unsigned(63 downto 0)-- output shifted z value 
);

end entity; 

architecture rtl of SIMON_keys is

-- one represented as 64-bit
constant one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";
constant c : unsigned(63 downto 0):= x"fffffffffffffffc"; -- constant value for both keys length 

-----------------------------------------------------------FUNCTION-------------------
function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate RIGHT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;
-------------------------------------------------------------------------------------------

begin
 
		key_out <= (c xor (z_in and one) xor key_in_1 
		xor ROR_64(key_in_2,3) xor ROR_64(key_in_2,4));
	
		z_out <= shift_right(z_in,1); -- shift value for z 

end architecture;