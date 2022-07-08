--This is the testbench for 128-bit Simon fast.
-- It contains 2 checks with different keys
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity Simon_128H_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of Simon_128H_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  signal clk 			  :  std_logic := '1';
  signal reset 			  :  std_logic;
  signal avs_s0_address   :  std_logic_vector(3 downto 0); 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_128H_top
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
 -----------------------------------------------------------------Check #1 for 128-bit key legnth 
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
	avs_s0_read <= '0';
	wait for clk_period;
	avs_s0_address <= B"0000"; -- reset_n signal address = 0
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"0001"; -- key_word_in signal address = 1
    avs_s0_writedata  <= x"DEADBEEF";  -- 1, keys ={0x01234567|DEADBEEF,0xDEADBEEF|89ABCDEF}
	wait for clk_period;
	avs_s0_address <= B"0010"; -- key_word_in signal address = 2
	avs_s0_writedata  <= x"01234567"; -- 2
    wait for clk_period;
	avs_s0_address <= B"0011"; -- key_word_in signal address = 3
    avs_s0_writedata  <= x"89ABCDEF"; -- 3
    wait for clk_period;
	avs_s0_address <= B"0100"; -- key_word_in signal address = 4
    avs_s0_writedata  <= x"DEADBEEF"; -- 4
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"0111"; -- data_word_in signal address = 7
    avs_s0_writedata  <= x"cc429e9a"; -- encrypted data={0xacc86341|cc429e9a,0x41f78ae3|acead36a}
	wait for clk_period;
	avs_s0_address <= B"1000"; -- data_word_in signal address = 8
    avs_s0_writedata <= x"acc86341"; --2 
    wait for clk_period;
	avs_s0_address <= B"1001"; -- data_word_in signal address = 9
    avs_s0_writedata <= x"acead36a";-- 3 
    wait for clk_period;
	avs_s0_address <= B"1010"; -- data_word_in signal address = 10
    avs_s0_writedata <= x"41f78ae3";-- 4
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
    avs_s0_writedata  <= x"23122312";  -- 1, keys = {0x15131321|23122312,0x13121231|23213122}
	wait for clk_period;
	avs_s0_address <= B"0010"; -- key_word_in signal address = 2
	avs_s0_writedata  <= x"15131321"; -- 2
    wait for clk_period;
	avs_s0_address <= B"0011"; -- key_word_in signal address = 3
    avs_s0_writedata  <= x"23213122"; -- 3
    wait for clk_period;
	avs_s0_address <= B"0100"; -- key_word_in signal address = 4
    avs_s0_writedata  <= x"13121231"; -- 4
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"0111"; -- data_word_in signal address = 7
    avs_s0_writedata  <= x"f811a374"; -- encrypted data={0xc50f7e17|f811a374,0xbd429692|6e4cd58c}
	wait for clk_period;
	avs_s0_address <= B"1000"; -- data_word_in signal address = 8
    avs_s0_writedata <= x"c50f7e17"; --2 
    wait for clk_period;
	avs_s0_address <= B"1001"; -- data_word_in signal address = 9
    avs_s0_writedata <= x"6e4cd58c";-- 3 
    wait for clk_period;
	avs_s0_address <= B"1010"; -- data_word_in signal address = 10
    avs_s0_writedata <= x"bd429692";-- 4
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