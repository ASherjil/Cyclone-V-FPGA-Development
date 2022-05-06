--------------------------------------
-- Library
--------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

--------------------------------------
-- Entity
--------------------------------------
entity ram_infer_tb is
end entity;

--------------------------------------
-- Architecture
--------------------------------------
architecture sim of ram_infer_tb is
  -- Clock definition
  constant clk_period : time := 20 ns;

  signal clock 			  :  std_logic := '1';
  signal data 			  :  std_logic_vector (31 DOWNTO 0);
  signal write_address    :  integer range 0 to 31; 
  signal read_address     :  integer range 0 to 31;
  signal we				  :  std_logic; -- write signal 
  signal q				  :  std_logic_vector(31 downto 0);

begin

clock <= not clock after clk_period/2; -- generate clock 

DUT: entity work.ram_infer
port map
(
    clock             => clock,
    data              => data,
    write_address	  => write_address,
    read_address      => read_address ,
	we     			  => we, 
    q				  => q
);


process is 
begin 

	we<= '1'; -- write signal is 1 
	write_address <= 0;
	data<= (others=>'0'); -- write 0 to address of 0
	wait for clk_period;
	
	write_address <= 1;
	data<= x"00001fff";
	wait for clk_period;
	
	write_address<=2;
	data <= x"000abdcd";
	wait for clk_period;
	
	write_address <= 3;
	data<= x"00efabcd";
	wait for clk_period;
	
	write_address <=4;
	data <= x"00012310";
	wait for clk_period;
	
	we <= '0';-- stop writing to the RAM
	wait for clk_period;
	
	for i in 0 to 4 loop-- now display all values of the RAM 
		read_address <= i;			
	wait for clk_period;
	end loop;
	

wait;

end process;

end architecture;