-- This is the SIMON VHDL implementation that is optimised for speed and performance
-- It performs initialisation + decryption in 0 clock cycles 
-- This works for 128-bit key length 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET_128.all; -- use the package file for constants and types 

entity SIMON_128H_top is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in std_logic;
	reset 			 : in std_logic;
	avs_s0_address   : in  std_logic_vector(3 downto 0); 
	avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
    avs_s0_readdata  : out std_logic_vector(31 downto 0)
);

end entity; 

architecture rtl of SIMON_128H_top is

signal key_64bit   : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
signal data_input  : t_data_in; -- data to be encrypted stored in 64-bit  
signal subkeys     : t_subkeys; -- generated subkeys 
signal zs          : t_store_data;-- shifted z values 
----------------------------------------------------------
signal dec_x 	   : t_store_data;
signal dec_y 	   : t_store_data;-- signal array to store decrypted data1 and data2 values 
signal x_dec_final : unsigned(63 downto 0);-- decrypted value of data1 
signal y_dec_final : unsigned(63 downto 0);-- decrypted value of data2 

begin

----------------------------------------------------INSTANTIATE HPS ENTITY----------
Processor : entity work.Simon_128_HPS port map
(
	clk  			  => clk,
	reset 			  => reset,
	avs_s0_address    => avs_s0_address,
	avs_s0_read       => avs_s0_read,
    avs_s0_write      => avs_s0_write,  
    avs_s0_writedata  => avs_s0_writedata,
	x                 => x_dec_final,
	y                 => y_dec_final,
	
	key_64bit         => key_64bit,
	data_input        => data_input,
    avs_s0_readdata   => avs_s0_readdata
);
------------------------------------------------------Begin Key Initialisation-------
zs(0) <=  x"7369f885192c0ef5"; -- assign initial value for z 

subkeys(0)  <= key_64bit(1);-- assign initial values 
subkeys(1)	<= key_64bit(0);-- assign initial values 

generator1 : for i in 0 to 31 generate 

generate_keys : entity work.SIMON_keys_128 port map-- begin generator 1
(
	key_in_1  => subkeys(i*2),--  i=0
	key_in_2  => subkeys((i*2)+1),-- i*2+1
	z_in 	  => zs(i),
	key_out1  => subkeys((i*2)+2), 
	key_out2  => subkeys((i*2)+3), -- max-index = 31*2 +3 = 65
	z_out     => zs(i+1)
);

end generate generator1;

subkeys(66) <= (c xor one xor subkeys(64)  -- generate remaining subkeys 
				xor ROR_64(subkeys(65),3) 
				xor ROR_64(subkeys(65),4));

subkeys(67) <= (c xor subkeys(65) 
				xor ROR_64(subkeys(66),3) 
				xor ROR_64(subkeys(66),4));
		
------------------------------------------------------FINAL ENCRYPTED/DECRYPTED DATA---
x_dec_final <= dec_x(34);--decrypted data1 
y_dec_final <= dec_y(34);--decrypted data2
--------------------------------------------------------------DECRYPTION--------------
dec_x(0) <= data_input(0);-- assign initial data 
dec_y(0) <= data_input(1);

generator3 : for i in 0 to 33 generate -- begin generator 3

decrypt_data : entity work.SIMON_Decrypt_128 port map
(
	x_in         => dec_x(i),
	y_in         => dec_y(i),
	subkey_in1   => subkeys(67 - (i*2)),
	subkey_in2   => subkeys(67- ((i*2)+1)),--min_index = 67-(33*2+1)=0
	x_out        => dec_x(i+1),
	y_out		 => dec_y(i+1)
);
end generate generator3;
--------------------------------------------------------------END-------------------

end architecture;

	