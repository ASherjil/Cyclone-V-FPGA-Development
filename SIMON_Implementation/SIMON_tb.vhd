-- Dual testbench for 128-bit keys and 192-bit keys 
--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity key_192_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of key_192_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  -- Input signals
  signal clk : std_logic := '1';
  signal reset_n : std_logic := '0';
  signal key_word_in : std_logic_vector(31 downto 0) := (others => '0');
  signal key_length : std_logic_vector(1 downto 0) := (others => '0');
  signal encryption, key_valid, data_valid : std_logic := '0';
  signal data_word_in : std_logic_vector (31 downto 0) := (others => '0');

  -- Output signals
  signal data_ready : std_logic;
  signal data_word_out : std_logic_vector (31 downto 0);

  -- Internal signals
  signal data_bkp : std_logic_vector (127 downto 0) := (others => '0');

begin
  clk <= not clk after clk_period/2;

  DUT: entity work.Simon_Init
  port map(
    clk           => clk,
    reset_n       => reset_n,
    encryption    => encryption,
    key_length    => key_length,
    key_valid     => key_valid,
    key_word_in   => key_word_in,
    data_valid    => data_valid,
    data_word_in  => data_word_in,
    data_word_out => data_word_out,
    data_ready    => data_ready
  );

  STIM: process
  begin
----------------------------------------------------------------TEST #1 FOR 128-BIT KEY 
	reset_n      <= '0';
    wait for 4*clk_period;
    encryption   <= '1';  -- Set to Encryption 
    key_length   <= "00"; -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
    reset_n      <= '1';
    wait for clk_period;
    key_valid    <= '1';
    key_word_in  <= x"DEADBEEF";
    wait for clk_period;
    key_word_in  <= x"01234567";
    wait for clk_period;
    key_word_in  <= x"89ABCDEF";
    wait for clk_period;
    key_word_in  <= x"DEADBEEF";
    wait for clk_period;
    key_valid    <= '0';
    key_word_in  <= x"00000000";
    data_valid   <= '1';
    data_word_in <= x"A5A5A5A5";
    wait for clk_period;
    data_word_in <= x"01234567";
    wait for clk_period;
    data_word_in <= x"FEDCBA98";
    wait for clk_period;
    data_word_in <= x"5A5A5A5A";
    wait for clk_period;
    data_valid   <= '0';
    data_word_in <= x"00000000";
    wait until data_ready = '1';
    wait for clk_period;
    data_bkp(127 downto 96) <= data_word_out;
    wait for clk_period;
    data_bkp(95 downto 64)  <= data_word_out;
    wait for clk_period;
    data_bkp(63 downto 32)  <= data_word_out;
    wait for clk_period;
    data_bkp(31 downto 0)   <= data_word_out;

    wait for 4*clk_period;
    reset_n      <= '0';
    wait for clk_period;
    encryption   <= '0';  -- Set to Decryption 
    key_length   <= "00"; -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
    reset_n      <= '1';
    wait for clk_period;
    key_valid    <= '1';
    key_word_in  <= x"DEADBEEF";
    wait for clk_period;
    key_word_in  <= x"01234567";
    wait for clk_period;
    key_word_in  <= x"89ABCDEF";
    wait for clk_period;
    key_word_in  <= x"DEADBEEF";
    wait for clk_period;
    key_valid    <= '0';
    key_word_in  <= x"00000000";
    data_valid   <= '1';
    data_word_in <= data_bkp(127 downto 96);
    wait for clk_period;
    data_word_in <= data_bkp(95 downto 64);
    wait for clk_period;
    data_word_in <= data_bkp(63 downto 32);
    wait for clk_period;
    data_word_in <= data_bkp(31 downto 0);
    wait for clk_period;
    data_valid   <= '0';
    data_word_in <= x"00000000";
    wait until data_ready = '1';
    wait for clk_period;
    data_bkp(127 downto 96) <= data_word_out;
    wait for clk_period;
    data_bkp(95 downto 64)  <= data_word_out;
    wait for clk_period;
    data_bkp(63 downto 32)  <= data_word_out;
    wait for clk_period;
    data_bkp(31 downto 0)   <= data_word_out;
	
----------------------------------------------------------------TEST #2 FOR 192-BIT KEY 
	wait for clk_period;
    reset_n      <= '0';
    wait for 4*clk_period; -- 20 ns * 4 = 80 ns
    encryption   <= '1';  -- Set to Encryption 
    key_length   <= "01"; -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
    reset_n      <= '1';
    wait for clk_period; -- 20 ns 
    key_valid    <= '1';
    key_word_in  <= x"DEADBEEF";  -- 1
    wait for clk_period;
    key_word_in  <= x"01234567"; -- 2
    wait for clk_period;
    key_word_in  <= x"89ABCDEF"; -- 3
    wait for clk_period;
    key_word_in  <= x"DEADBEEF"; -- 4
    wait for clk_period;
	key_word_in  <= x"BEEF1ABC"; -- 5
    wait for clk_period;
    key_word_in  <= x"ABCDEF01"; -- 6
    wait for clk_period;
    key_valid    <= '0';
    key_word_in  <= x"00000000"; -- 7 {key_word_in}
    data_valid   <= '1';
    data_word_in <= x"A5A5A5A5";  -- 1
    wait for clk_period;
    data_word_in <= x"01234567"; --2 
    wait for clk_period;
    data_word_in <= x"FEDCBA98";-- 3
    wait for clk_period;
    data_word_in <= x"5A5A5A5A";-- 4
    wait for clk_period;
    data_valid   <= '0';
    data_word_in <= x"00000000";-- 5 {data_word_in}
    wait until data_ready = '1';
    wait for clk_period;
    data_bkp(127 downto 96) <= data_word_out; -- 1
    wait for clk_period;
    data_bkp(95 downto 64)  <= data_word_out;-- 2
    wait for clk_period;
    data_bkp(63 downto 32)  <= data_word_out;-- 3
    wait for clk_period;
    data_bkp(31 downto 0)   <= data_word_out;-- 4 {encypted_text, uint64_t arr[2]}
	
    wait for 4*clk_period; -- 80 ns 
    reset_n      <= '0';
    wait for clk_period;
    encryption   <= '0';  -- Set to Decryption 
    key_length   <= "01"; -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
    reset_n      <= '1';
    wait for clk_period;
    key_valid    <= '1';
    key_word_in  <= x"DEADBEEF";
    wait for clk_period;
    key_word_in  <= x"01234567";
    wait for clk_period;
    key_word_in  <= x"89ABCDEF";
    wait for clk_period;
    key_word_in  <= x"DEADBEEF";
	wait for clk_period;
	key_word_in  <= x"BEEF1ABC"; -- 5
    wait for clk_period;
    key_word_in  <= x"ABCDEF01"; -- 6
	wait for clk_period;
    key_valid    <= '0';
    key_word_in  <= x"00000000"; -- 7 {key_word_in}
    data_valid   <= '1';
    data_word_in <= data_bkp(127 downto 96);
    wait for clk_period;
    data_word_in <= data_bkp(95 downto 64);
    wait for clk_period;
    data_word_in <= data_bkp(63 downto 32);
    wait for clk_period;
    data_word_in <= data_bkp(31 downto 0);
    wait for clk_period;
    data_valid   <= '0';
    data_word_in <= x"00000000";
    wait until data_ready = '1';
    wait for clk_period;
    data_bkp(127 downto 96) <= data_word_out;
    wait for clk_period;
    data_bkp(95 downto 64)  <= data_word_out;
    wait for clk_period;
    data_bkp(63 downto 32)  <= data_word_out;
    wait for clk_period;
    data_bkp(31 downto 0)   <= data_word_out;
    wait;-- STOP do not loop back 
  end process;

end architecture;
