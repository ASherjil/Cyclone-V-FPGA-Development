library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RTC is 
port
(
	CLOCK_50 : in std_logic; -- clock at 50 Mhz
	reset : in std_logic;
	real_time : in std_logic_vector(6 downto 0); -- time input, 6-bit = max of 128 
	HEX0 : out std_logic_vector(6 downto 0);
	HEX1 : out std_logic_vector(6 downto 0)
);

end entity; 

architecture rtl of RTC is
--signal storage : unsigned(7 downto 0);
 type t_BCD is array(0 to 9) of integer;
 signal BCD : t_BCD;
-- signal moder : integer := 0;
begin
		
		BCD(0)	<= 63;--0
		BCD(1)	<= 6;-- 1
		BCD(2)	<= 91;-- 2
		BCD(3)	<= 79 ;-- 3
		BCD(4)	<= 102;-- 4
		BCD(5)	<= 109;-- 5
		BCD(6)	<= 125;-- 6
		BCD(7)	<= 7;-- 7
		BCD(8)	<= 127;-- 8
		BCD(9)	<= 111; -- 9

	process(CLOCK_50) is 
		variable moder : integer := 0;
		variable storage : unsigned(6 downto 0);
	begin 
	
		if (CLOCK_50'event) then -- react at rising and falling edge of the clock 
			
				storage := unsigned(real_time); -- assign value of real_time to storage 
				
				
				moder := to_integer(storage mod 10); -- split up into first digit 
				
					HEX0 <= std_logic_vector(to_unsigned(BCD(moder),HEX0'length));
					
				if (storage > 9) then -- only divide when storage is larger than 10 
				
					storage := storage / 10;
					moder := to_integer(storage mod 10); -- split up second digit 
					HEX1 <= std_logic_vector(to_unsigned(BCD(moder),HEX1'length));
		
				elsif (storage < 10) then  -- if storage is less than 10 make it zero 
				
					HEX1 <= std_logic_vector(to_unsigned(BCD(0),HEX1'length)); -- make it zero
				
				end if;
		end if;	
	end process;
	
end architecture;
