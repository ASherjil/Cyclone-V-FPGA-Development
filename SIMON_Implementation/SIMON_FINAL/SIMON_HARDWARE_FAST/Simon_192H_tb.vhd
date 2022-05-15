--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity Simon_192H_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of Simon_192H_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  signal clk 			  :  std_logic := '1';
  signal reset 			  :  std_logic;
  signal avs_s0_address   :  std_logic_vector(3 downto 0); -- 15 registors being used 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_192_topH
  port map
  (
    clk               => clk,
    reset             => reset,
    avs_s0_address	  => avs_s0_address,
    avs_s0_read       => avs_s0_read ,
	avs_s0_write      => avs_s0_write, 
    avs_s0_writedata  => avs_s0_writedata,
    avs_s0_readdata   => avs_s0_readdata
  );

  STIM: process
  begin
 -----------------------------------------------------------------Check #1 for 192-bit key legnth 
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
	avs_s0_read <= '0';
	wait for clk_period;
	avs_s0_address <= B"0000"; -- reset_n signal address = 0
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"0001"; -- key_word_in signal address = 1
    avs_s0_writedata  <= x"DEADBEEF";  -- 1, keys ={0x01234567|DEADBEEF,0xDEADBEEF|89ABCDEF,0x76453210|FEDCBA98}
	wait for clk_period;
	avs_s0_address <= B"0010"; -- key_word_in signal address = 2
	avs_s0_writedata  <= x"01234567"; -- 2
    wait for clk_period;
	avs_s0_address <= B"0011"; -- key_word_in signal address = 3
    avs_s0_writedata  <= x"89ABCDEF"; -- 3
    wait for clk_period;
	avs_s0_address <= B"0100"; -- key_word_in signal address = 4
    avs_s0_writedata  <= x"DEADBEEF"; -- 4
    wait for clk_period;
	avs_s0_address <= B"0101"; -- key_word_in signal address = 5
	avs_s0_writedata  <= x"FEDCBA98"; -- 5
    wait for clk_period;
	avs_s0_address <= B"0110"; -- key_word_in signal address = 6
    avs_s0_writedata  <= x"76453210"; -- 6
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"0111"; -- data_word_in signal address = 7
    avs_s0_writedata  <= x"adf9977e"; -- encrypted data={0x71b89d8a|adf9977e,0xc81a2142|2196b841}
	wait for clk_period;
	avs_s0_address <= B"1000"; -- data_word_in signal address = 8
    avs_s0_writedata <= x"71b89d8a"; --2 
    wait for clk_period;
	avs_s0_address <= B"1001"; -- data_word_in signal address = 9
    avs_s0_writedata <= x"2196b841";-- 3 
    wait for clk_period;
	avs_s0_address <= B"1010"; -- data_word_in signal address = 10
    avs_s0_writedata <= x"c81a2142";-- 4
	wait for clk_period;
	avs_s0_read <= '1';
	avs_s0_address <= B"1011"; -- data_word_out signal address = 11
    wait for clk_period;
	avs_s0_address <= B"1100"; -- data_word_out signal address = 12
    wait for clk_period;
	avs_s0_address <= B"1101"; -- data_word_out signal address = 13
    wait for clk_period;
    avs_s0_address <= B"1110"; -- data_word_out signal address = 14

---------------------------------------------------------------Check #1 completed
---------------------------------------------------------------Check #2 for another key 	
	wait for 100 ns; -- create time gap 
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
	avs_s0_read <= '0';
	wait for clk_period;
	avs_s0_address <= B"0000"; -- reset_n signal address = 0
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"0001"; -- key_word_in signal address = 1
    avs_s0_writedata  <= x"38471234";  -- 1, keys = {0x01238412|38471234,0x89413220|89851322,
										--	0x31351848|35132132}
	wait for clk_period;
	avs_s0_address <= B"0010"; -- key_word_in signal address = 2
	avs_s0_writedata  <= x"01238412"; -- 2
    wait for clk_period;
	avs_s0_address <= B"0011"; -- key_word_in signal address = 3
    avs_s0_writedata  <= x"89851322"; -- 3
    wait for clk_period;
	avs_s0_address <= B"0100"; -- key_word_in signal address = 4
    avs_s0_writedata  <= x"89413220"; -- 4
    wait for clk_period;
	avs_s0_address <= B"0101"; -- key_word_in signal address = 5
	avs_s0_writedata  <= x"35132132"; -- 5
    wait for clk_period;
	avs_s0_address <= B"0110"; -- key_word_in signal address = 6
    avs_s0_writedata  <= x"31351848"; -- 6
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"0111"; -- data_word_in signal address = 7
    avs_s0_writedata  <= x"caa766d0"; -- encrypted data={0x2c27a93a|caa766d0,0x2459e57d|4b124834}
	wait for clk_period;
	avs_s0_address <= B"1000"; -- data_word_in signal address = 8
    avs_s0_writedata <= x"2c27a93a"; --2 
    wait for clk_period;
	avs_s0_address <= B"1001"; -- data_word_in signal address = 9
    avs_s0_writedata <= x"4b124834";-- 3 
    wait for clk_period;
	avs_s0_address <= B"1010"; -- data_word_in signal address = 10
    avs_s0_writedata <= x"2459e57d";-- 4
	wait for clk_period;
	avs_s0_read <= '1';
    wait for clk_period;
	avs_s0_address <= B"1011"; -- data_word_out signal address = 11
    wait for clk_period;
	avs_s0_address <= B"1100"; -- data_word_out signal address = 12
    wait for clk_period;
	avs_s0_address <= B"1101"; -- data_word_out signal address = 13
    wait for clk_period;
    avs_s0_address <= B"1110"; -- data_word_out signal address = 14
	
--------------------------------------------------------------Check 2 completed 
	wait;-- do not loop back(stop)
	
  end process;

end architecture;