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
  signal avs_s0_address   :  std_logic_vector(4 downto 0); -- 20 registors being used 
  signal avs_s0_read      :  std_logic;
  signal avs_s0_write     :  std_logic;
  signal avs_s0_writedata :  std_logic_vector(31 downto 0);
  signal avs_s0_readdata  :  std_logic_vector(31 downto 0);


begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_Hardware
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
---------------------------------------------------------------------------
-- Check for restarting 
		
	wait for 500 ns;
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
	
-------------------------------------------------------Check for restarting 
	wait for 500 ns;
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
    avs_s0_writedata  <= x"51321318";  -- 1, key_word_in <= {0x13248994|51321318,0x98481320|20789452,}
														-- 	 {0x12354894|8784123F}
	wait for clk_period;
	avs_s0_address <= B"01100"; -- key_word_in signal address = 0xC
	avs_s0_writedata  <= x"13248994"; -- 2
    wait for clk_period;
	avs_s0_address <= B"01101"; -- key_word_in signal address = 0xD
    avs_s0_writedata  <= x"20789452"; -- 3
    wait for clk_period;
	avs_s0_address <= B"01110"; -- key_word_in signal address = 0xE
    avs_s0_writedata  <= x"98481320"; -- 4
    wait for clk_period;
	avs_s0_address <= B"01111"; -- key_word_in signal address = 0xF
	avs_s0_writedata  <= x"8784123F"; -- 5
    wait for clk_period;
	avs_s0_address <= B"10000"; -- key_word_in signal address = 0x10
    avs_s0_writedata  <= x"12354894"; -- 6
	wait for clk_period; -- 20 ns 
	avs_s0_address <= B"00001"; -- key_valid signal address = 0x1
    avs_s0_writedata    <= B"00000000000000000000000000000001"; -- key_valid <= '1';
    wait for clk_period;
    avs_s0_writedata    <= B"00000000000000000000000000000000"; -- key_valid <= '0';
	wait for clk_period;
	avs_s0_address <= B"00100"; -- data_word_in signal address = 0x4
    avs_s0_writedata  <= x"f1849c38"; -- data_word_in <=  {  0x776b8923|f1849c38, 0x16d57b89|c656b268}
	wait for clk_period;
	avs_s0_address <= B"10001"; -- data_word_in signal address = 0x11
    avs_s0_writedata <= x"776b8923"; --2 
    wait for clk_period;
	avs_s0_address <= B"10010"; -- data_word_in signal address = 0x12
    avs_s0_writedata <= x"c656b268";-- 3 
    wait for clk_period;
	avs_s0_address <= B"10011"; -- data_word_in signal address = 0x13
    avs_s0_writedata <= x"16d57b89";-- 4
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
	wait;
	
  end process;

end architecture;
