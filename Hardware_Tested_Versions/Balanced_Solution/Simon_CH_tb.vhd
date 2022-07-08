----------This testbench is for validating 
-- the balanced solution which works for both keylength 128-bit and 
-- 192-bit. It contains 3 tests, the first one is for 
-- 192-bit, the second for 128-bit keys and another for 192-bit keys. 

library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity Simon_CH_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of Simon_CH_tb is
  -- Clock definition
  constant clk_period     : time := 20 ns;

  signal clk 			  :  std_logic := '1';
  signal reset 			  :  std_logic;
  signal avs_s0_address   :  std_logic_vector(4 downto 0); -- 20 registors being used 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_CH_top
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
	avs_s0_address <= B"01011"; -- reset_n signal address = 0xB
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"00011"; -- encryption signal address = 0x3
    avs_s0_writedata  <= (others=> '0');  -- Set to Encryption to '0'= Decryption
	wait for clk_period; -- wait for 20 ns 
	avs_s0_address <= B"00000"; -- key_length signal address = 0x0
    avs_s0_writedata <= B"00000000000000000000000000000001"; -- Set "01" to 192 bit
	wait for clk_period;
	avs_s0_address <= B"00101"; -- key_word_in signal address = 0x5
    avs_s0_writedata  <= x"DEADBEEF";  -- 1, key_word_in <= 
	wait for clk_period;
	avs_s0_address <= B"01100"; -- key_word_in signal address = 0xC
	avs_s0_writedata  <= x"01234567"; -- 2
    wait for clk_period;
	avs_s0_address <= B"01101"; -- key_word_in signal address = 0xD
    avs_s0_writedata  <= x"89ABCDEF"; -- 3
    wait for clk_period;
	avs_s0_address <= B"01110"; -- key_word_in signal address = 0xE
    avs_s0_writedata  <= x"DEADBEEF"; -- 4
    wait for clk_period;
	avs_s0_address <= B"01111"; -- key_word_in signal address = 0xF
	avs_s0_writedata  <= x"BEEF1ABC"; -- 5
    wait for clk_period;
	avs_s0_address <= B"10000"; -- key_word_in signal address = 0x10
    avs_s0_writedata  <= x"ABCDEF01"; -- 6
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"00001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- key_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_valid <= '0';
	wait for clk_period;
	avs_s0_address <= B"00100"; -- data_word_in signal address = 0x4
    avs_s0_writedata  <= x"415530FB"; -- data_word_in <=  0xc93b9a19415530fb
	wait for clk_period;
	avs_s0_address <= B"10001"; -- data_word_in signal address = 0x11
    avs_s0_writedata <= x"C93b9a19"; --2 
    wait for clk_period;
	avs_s0_address <= B"10010"; -- data_word_in signal address = 0x12
    avs_s0_writedata <= x"d493bad9";-- 3 -- data_word_in <= 0x3845720ed493bad9
    wait for clk_period;
	avs_s0_address <= B"10011"; -- data_word_in signal address = 0x13
    avs_s0_writedata <= x"3845720e";-- 4
    wait for clk_period;
	avs_s0_address <= B"00010"; -- data_valid signal address = 0x2
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- data_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- data_valid <= '0';
	wait for clk_period;
	avs_s0_read <= '1';
	avs_s0_address <= B"00110"; -- data_ready signal address = 0x6
    wait until avs_s0_readdata(0) = '1'; -- wait until data_ready = '1'
    wait for clk_period;
	avs_s0_address <= B"00111"; -- data_word_out signal address = 0x7
    wait for clk_period;
	avs_s0_address <= B"01000"; -- data_word_out signal address = 0x8
    wait for clk_period;
	avs_s0_address <= B"01001"; -- data_word_out signal address = 0x9
    wait for clk_period;
    avs_s0_address <= B"01010"; -- data_word_out signal address = 0xA
	
-------------------------------------------------------Now check for 128-bit key length 

	wait for 500 ns;-- create time gap 
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
	avs_s0_read <= '0';
	wait for clk_period;
	avs_s0_address <= B"01011"; -- reset_n signal address = 0xB
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"00011"; -- encryption signal address = 0x3
    avs_s0_writedata  <= (others=> '0');  -- Set to Encryption to '0'= Decryption
	wait for clk_period; -- wait for 20 ns 
	avs_s0_address <= B"00000"; -- key_length signal address = 0x0
    avs_s0_writedata <= B"00000000000000000000000000000000"; -- Set "00" to 128 bit key_length 
	wait for clk_period;
	avs_s0_address <= B"00101"; -- key_word_in signal address = 0x5
    avs_s0_writedata  <= x"89abcdef";  -- 1, key_word_in <=  {0x01234567|89abcdef,0x0fedcba9|87456321}										
	wait for clk_period;
	avs_s0_address <= B"01100"; -- key_word_in signal address = 0xC
	avs_s0_writedata  <= x"01234567"; -- 2
    wait for clk_period;
	avs_s0_address <= B"01101"; -- key_word_in signal address = 0xD
    avs_s0_writedata  <= x"87456321"; -- 3
    wait for clk_period;
	avs_s0_address <= B"01110"; -- key_word_in signal address = 0xE
    avs_s0_writedata  <= x"0fedcba9"; -- 4
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"00001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- key_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_valid <= '0';
	wait for clk_period;
	avs_s0_address <= B"00100"; -- data_word_in signal address = 0x4
    avs_s0_writedata  <= x"32713d11"; -- data_word_in <= {0x2c52530e|32713d11, 0x548e625f|df9bf565}
	wait for clk_period;
	avs_s0_address <= B"10001"; -- data_word_in signal address = 0x11
    avs_s0_writedata <= x"2c52530e"; --2 
    wait for clk_period;
	avs_s0_address <= B"10010"; -- data_word_in signal address = 0x12
    avs_s0_writedata <= x"df9bf565";-- 3 
    wait for clk_period;
	avs_s0_address <= B"10011"; -- data_word_in signal address = 0x13
    avs_s0_writedata <= x"548e625f";-- 4
    wait for clk_period;
	avs_s0_address <= B"00010"; -- data_valid signal address = 0x2
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- data_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- data_valid <= '0';
	wait for clk_period;
	avs_s0_read <= '1';
	avs_s0_address <= B"00110"; -- data_ready signal address = 0x6
    wait until avs_s0_readdata(0) = '1'; -- wait until data_ready = '1'
    wait for clk_period;
	avs_s0_address <= B"00111"; -- data_word_out signal address = 0x7
    wait for clk_period;
	avs_s0_address <= B"01000"; -- data_word_out signal address = 0x8
    wait for clk_period;
	avs_s0_address <= B"01001"; -- data_word_out signal address = 0x9
    wait for clk_period;
    avs_s0_address <= B"01010"; -- data_word_out signal address = 0xA
---------------------------------------------------------------------------
-- Check #2 for 192-bit key length(another check for 192-bit key )  
		
	wait for 500 ns; -- create time gap 
	avs_s0_write <= '1'; -- enable write(take input for HPS) 
	avs_s0_read <= '0';
	wait for clk_period;
	avs_s0_address <= B"01011"; -- reset_n signal address = 0xB
    avs_s0_writedata  <= (others=> '0');  -- set to reset_n = '0'
	wait for clk_period;
	avs_s0_writedata  <= B"00000000000000000000000000000001";  -- set to reset_n = '1'
	wait for clk_period;
	avs_s0_address <= B"00011"; -- encryption signal address = 0x3
    avs_s0_writedata  <= (others=> '0');  -- Set to Encryption to '0'= Decryption
	wait for clk_period; -- wait for 20 ns 
	avs_s0_address <= B"00000"; -- key_length signal address = 0x0
    avs_s0_writedata <= B"00000000000000000000000000000001"; -- Set "01" to 192 bit
	wait for clk_period;
	avs_s0_address <= B"00101"; -- key_word_in signal address = 0x5
    avs_s0_writedata  <= x"76543210";  -- 1, key_word_in <= {0xFEDCBA98|76543210, 0x09871233|51ABCEFD,0xFEDA1234|567890EF}
	wait for clk_period;
	avs_s0_address <= B"01100"; -- key_word_in signal address = 0xC
	avs_s0_writedata  <= x"FEDCBA98"; -- 2
    wait for clk_period;
	avs_s0_address <= B"01101"; -- key_word_in signal address = 0xD
    avs_s0_writedata  <= x"51ABCEFD"; -- 3
    wait for clk_period;
	avs_s0_address <= B"01110"; -- key_word_in signal address = 0xE
    avs_s0_writedata  <= x"09871233"; -- 4
    wait for clk_period;
	avs_s0_address <= B"01111"; -- key_word_in signal address = 0xF
	avs_s0_writedata  <= x"567890EF"; -- 5
    wait for clk_period;
	avs_s0_address <= B"10000"; -- key_word_in signal address = 0x10
    avs_s0_writedata  <= x"FEDA1234"; -- 6
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"00001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- key_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_valid <= '0';
	wait for clk_period;
	avs_s0_address <= B"00100"; -- data_word_in signal address = 0x4
    avs_s0_writedata  <= x"0caef09b"; -- data_word_in <=  0xf7598a2a|0caef09b
	wait for clk_period;
	avs_s0_address <= B"10001"; -- data_word_in signal address = 0x11
    avs_s0_writedata <= x"f7598a2a"; --2 
    wait for clk_period;
	avs_s0_address <= B"10010"; -- data_word_in signal address = 0x12
    avs_s0_writedata <= x"5a7b25cf";-- 3 -- data_word_in <=  0x0e8588a1|5a7b25cf
    wait for clk_period;
	avs_s0_address <= B"10011"; -- data_word_in signal address = 0x13
    avs_s0_writedata <= x"0e8588a1";-- 4
    wait for clk_period;
	avs_s0_address <= B"00010"; -- data_valid signal address = 0x2
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- data_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- data_valid <= '0';
	wait for clk_period;
	avs_s0_read <= '1';
	avs_s0_address <= B"00110"; -- data_ready signal address = 0x6
    wait until avs_s0_readdata(0) = '1'; -- wait until data_ready = '1'
    wait for clk_period;
	avs_s0_address <= B"00111"; -- data_word_out signal address = 0x7
    wait for clk_period;
	avs_s0_address <= B"01000"; -- data_word_out signal address = 0x8
    wait for clk_period;
	avs_s0_address <= B"01001"; -- data_word_out signal address = 0x9
    wait for clk_period;
    avs_s0_address <= B"01010"; -- data_word_out signal address = 0xA
	

	wait;-- do not loop back(stop)
	
  end process;

end architecture;