library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity RTC_tb is
end entity;

architecture sim of RTC_tb is
    
    constant ClockFrequencyHz : integer := 50e6; -- 50 MHz
    constant ClockPeriod : time := 1000 ms / ClockFrequencyHz; -- 20 ns
	
	signal CLOCK_50 : std_logic;
     
	signal real_time : std_logic_vector(6 downto 0);
	signal HEX0 : std_logic_vector(6 downto 0);
	signal HEX1 : std_logic_vector(6 downto 0);
	
	signal reset : std_logic;
--	signal inti : integer := 0;
	
begin

	 -- The Device Under Test (DUT)
    i_RTC : entity work.RTC
    port map 
	(
        CLOCK_50 => CLOCK_50,
		HEX0 => HEX0,
		HEX1 => HEX1,
		real_time =>real_time,
		reset => reset
	);
	
	clk_process : process is -- clock process, 20 ns period 
	begin
		CLOCK_50 <= '0';
		wait for ClockPeriod / 2;
		CLOCK_50 <= '1';
		wait for ClockPeriod / 2;
	end process clk_process;
		
	
	in_time : process is
		variable inti : integer := 0;
	begin 
	
		if inti = 99 then
			inti := 0;
		end if ;
	
		real_time <= std_logic_vector(to_unsigned(inti,real_time'length));

			inti := inti +1 ; -- increment this 
			
		wait for 9 ns;
	end process in_time;
	
end architecture;
