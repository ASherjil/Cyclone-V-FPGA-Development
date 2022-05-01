--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity counter_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of counter_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  signal clk 			  :  std_logic := '1';
  signal reset 			  :  std_logic;
  signal avs_s0_address   :  std_logic_vector(2 downto 0); -- 10 registors being used 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin

clk <= not clk after clk_period/2;

  DUT: entity work.custom_counter
  port map
  (
    clk               => clk,
    reset             => reset,
    avs_s0_address	  => avs_s0_address,
    avs_s0_read       => avs_s0_read ,
	avs_s0_write      => avs_s0_write, 
    avs_s0_writedata  => avs_s0_writedata,
    avs_s0_readdata   =>  avs_s0_readdata
  );
  
  
  
process is 
begin 

	avs_s0_write <= '1'; -- enable write(take input from HPS) 
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000010";
    wait for clk_period; -- 20 ns
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000000";
	wait for clk_period;
	avs_s0_address <= "011";             
	avs_s0_writedata <= "00000000000000000001111111111111"; -- = 0x1fff as binary 
	wait for clk_period;
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000001"; -- start counter 
	avs_s0_read <= '1';	
	wait for clk_period;
	avs_s0_address <= "001";
	wait until avs_s0_readdata = "00000000000000000000000000000010";
	
	avs_s0_write <= '1'; -- enable write(take input from HPS) 
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000010"; -- reset first 
    wait for clk_period; -- 20 ns
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000000";-- reset set to 0
	wait for clk_period;
	avs_s0_address <= "011";             
	avs_s0_writedata <= "00000000000000001111111111111111"; -- = 0xffff as binary 
	wait for clk_period;
	avs_s0_address <= "000";
	avs_s0_writedata <= "00000000000000000000000000000001"; -- start counter 
	avs_s0_read <= '1';	
	
	
	wait;
	
end process;
  
  
end architecture;
 
  