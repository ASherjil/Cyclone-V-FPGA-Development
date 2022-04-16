--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity SIMON_Init_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of SIMON_Init_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  -- Input signals
  signal clk : std_logic := '1';
  signal reset_n : std_logic := '0';
  signal key_word_in : std_logic_vector(31 downto 0) := (others => '0');
  signal key_length : std_logic_vector(1 downto 0) := (others => '0');
  signal  key_valid: std_logic := '0';
  signal nrSubkeys : integer;

begin
  clk <= not clk after clk_period/2;

  DUT: entity work.SIMON_Init
  port map(
    clk           => clk,
    reset_n       => reset_n,
    key_length    => key_length,
    key_valid     => key_valid,
    key_word_in   => key_word_in,
    nrSubkeys    => nrSubkeys
  );

  STIM: process
  begin
  
    reset_n      <= '0';
    wait for 4*clk_period; -- 20 ns * 4 = 80 ns
 --   encryption   <= '1';  -- Set to Encryption 
    key_length   <= "00"; -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
    reset_n      <= '1';
    wait for clk_period; -- 20 ns 
    key_valid    <= '1';
    key_word_in  <= x"DEADBEEF";  -- 1, "Dead beef HAHA"
    wait for clk_period;
    key_word_in  <= x"01234567"; -- 2
    wait for clk_period;
    key_word_in  <= x"89ABCDEF"; -- 3
    wait for clk_period;
    key_word_in  <= x"DEADBEEF"; -- 4
    wait for clk_period;
    key_valid    <= '0';
    key_word_in  <= x"00000000"; -- 5 {key_word_in}
    wait for clk_period;
	
	-- test for key length 192 bits 
	
    wait;
  end process;

end architecture;
