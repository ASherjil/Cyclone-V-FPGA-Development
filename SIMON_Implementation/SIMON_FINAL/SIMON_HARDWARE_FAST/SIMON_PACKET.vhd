-- This packages contains all the usefull array types 
-- Also contains repeated constants and functions 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- use library for unsigned 

package SIMON_PACKET is

 -- one represented as 64-bit
constant one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";
constant c : unsigned(63 downto 0):= x"fffffffffffffffc"; -- constant value for both keys length 
type t_store_data is array(0 to 34) of unsigned(63 downto 0);-- store decrypted data 
type t_subkeys is array(0 to 68) of unsigned(63 downto 0);-- store generated subkeys
type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);-- store keys as 64-bit
type t_data_in is array (0 to 1) of unsigned(63 downto 0);-- store data as 64-bit 

function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate RIGHT circular shift 32 bits
	return unsigned;

function ROL_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate LEFT circular shift 32 bits
	return unsigned;

function f(x : in unsigned(63 downto 0)) -- helper function for emulating the "R2" function
	return unsigned;

   
end package SIMON_PACKET;
 
-- Package Body Section

package body SIMON_PACKET is
 
  function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate RIGHT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;

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


end package body SIMON_PACKET;