--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity Hardware_192key_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of Hardware_192key_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  signal clk 			  :  std_logic := '1';
  signal reset 			  :  std_logic;
  signal avs_s0_address   :  std_logic_vector(2 downto 0); -- 8 registors being used 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_Hardware1
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

  STIM: process
  begin
    reset      <= '0';
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
    wait for 4*clk_period; -- 20 ns * 4 = 80 ns
	reset      <= '1';
	wait for clk_period;
	avs_s0_address <= B"011"; -- encryption signal address = 0x3
    avs_s0_writedata  <= (others=> '0');  -- Set to Encryption to '0'= Decryption
	wait for clk_period; -- wait for 20 ns 
	avs_s0_address <= B"000"; -- key_length signal address = 0x0
    avs_s0_writedata <= B"00000000000000000000000000000001"; -- Set "01" to 192 bit
	wait for clk_period;
	avs_s0_address <= B"101"; -- key_word_in signal address = 0x5
    avs_s0_writedata  <= x"DEADBEEF";  -- 1, key_word_in <= 
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- key_valid <= '1';
    wait for clk_period;
	avs_s0_address <= B"101"; -- key_word_in signal address = 0x5
    avs_s0_writedata  <= x"01234567"; -- 2
    wait for clk_period;
    avs_s0_writedata  <= x"89ABCDEF"; -- 3
    wait for clk_period;
    avs_s0_writedata  <= x"DEADBEEF"; -- 4
    wait for clk_period;
	avs_s0_writedata  <= x"BEEF1ABC"; -- 5
    wait for clk_period;
    avs_s0_writedata  <= x"ABCDEF01"; -- 6
    wait for clk_period;
	avs_s0_address <= B"001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_valid <= '0';
	wait for clk_period; 
	avs_s0_address <= B"101"; -- key_word_in signal address = 0x5
	avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_word_in <= (others => '0');
	wait for clk_period;
	avs_s0_address <= B"100"; -- data_word_in signal address = 0x4
    avs_s0_writedata    <= x"415530FB"; -- data_word_in <=  0xc93b9a19415530fb
	wait for clk_period;
	avs_s0_address <= B"010"; -- data_valid signal address = 0x2
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- data_valid <= '1';
    wait for clk_period;
	avs_s0_address <= B"100"; -- data_word_in signal address = 0x4
    avs_s0_writedata <= x"C93b9a19"; --2 
    wait for clk_period;
    avs_s0_writedata <= x"d493bad9";-- 3 -- data_word_in <= 0x3845720ed493bad9
    wait for clk_period;
    avs_s0_writedata <= x"3845720e";-- 4
    wait for clk_period;
	avs_s0_address <= B"010"; -- data_valid signal address = 0x2
	avs_s0_writedata  <= B"00000000000000000000000000000000"; -- data_valid <= '0';
	wait for clk_period;
	avs_s0_address <= B"100"; -- data_word_in signal address = 0x4
    avs_s0_writedata <= B"00000000000000000000000000000000"; -- data_word_in <=(others=> '0');
	wait for clk_period;
	avs_s0_read <= '1';
	avs_s0_address <= B"110"; -- data_ready signal address = 0x6
    wait until avs_s0_readdata(0) = '1'; -- wait until data_ready = '1'
    wait for clk_period;
	avs_s0_address <= B"111"; -- data_word_out signal address = 0x7
   -- data_word_out <= avs_s0_readdata; -- 1
    wait for clk_period;
   -- data_word_out <= avs_s0_readdata; -- 2
    wait for clk_period;
   -- data_word_out <= avs_s0_readdata;-- 3
    wait for clk_period;
   -- data_word_out <= avs_s0_readdata;
    -----------------------------------------------------------------
    wait;
  end process;

end architecture;