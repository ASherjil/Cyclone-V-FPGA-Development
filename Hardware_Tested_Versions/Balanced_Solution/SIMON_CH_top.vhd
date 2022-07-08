-- This is the hyrbid solution which is balanced. It provides a nice mix between
-- performance and area. It supports both key lengths 128-bit and 192-bit. 
-- It contains subkey generation and decryption for interfacing with the Cortex A9 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Simon_CH_Packet.all;

entity Simon_CH_top is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in std_logic;
	reset 			 : in std_logic;
	avs_s0_address   : in  std_logic_vector(4 downto 0); 
	avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
    avs_s0_readdata  : out std_logic_vector(31 downto 0)
);
end entity; 

architecture rtl of Simon_CH_top is
--------------------------------------Intermedaite signals for avalon bus----------------------
signal reset_n 			 : std_logic;
signal key_length 		 : std_logic_vector(1 downto 0); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
signal key_valid 		 : std_logic; -- enable intialisation = '1', disable = '0'
signal data_valid        : std_logic;
signal encryption 		 : std_logic;
signal data_ready 		 : std_logic; 
-------------------------------------Key intialisation signals----------------------------------
signal subkeys   		 : t_subkeys;
signal key_64bit 		 : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
signal continue          : std_logic := '0';-- signal to begin/stop decryption 
signal key_start         : std_logic := '0'; -- signal to specify wheather key are taken in
--------------------------------------------------------------Signals for decryption-----------------
signal data_input        : t_data_in; -- data to be encrypted 
signal data_check        : std_logic := '0'; -- signal to prevent starting the encryption/decryption too early 
signal l                 : integer; -- signal used to implement for loop inside initialisation 
signal seq_init          : integer := 0;-- signal used to design sequential circuit
signal z                 : unsigned(63 downto 0);-- signal for computation initialisation 
-----------------------------------------------------------------------------------------------
signal key32_1 		     : unsigned (31 downto 0);-- keys and data as 32-bits 
signal key32_2 		     : unsigned (31 downto 0);
signal key32_3 		     : unsigned (31 downto 0);
signal key32_4 		     : unsigned (31 downto 0);
signal key32_5 		     : unsigned (31 downto 0);
signal key32_6 		     : unsigned (31 downto 0);
signal data32_1		     : unsigned (31 downto 0);
signal data32_2		     : unsigned (31 downto 0);
signal data32_3		     : unsigned (31 downto 0);
signal data32_4		     : unsigned (31 downto 0);
signal x 				 : unsigned (63 downto 0);-- decrypted data1
signal y 				 : unsigned (63 downto 0);-- decrypted data2
-----------------------------------------------------------------------------------------------
begin
	
-- process(all) was implemented to ensure no signals are missed(VHDL 2008 only works in Questasim)
-- and NOT Quartus Prime 21.1

--------------------------------------------HPS INSTANTIATION-------------------------
Processor : entity work.Simon_CH_HPS port map
(
	
	clk 			 => clk,
	reset 			 => reset,  
	avs_s0_address   => avs_s0_address , 
	avs_s0_read      => avs_s0_read,
    avs_s0_write     => avs_s0_write, 
    avs_s0_writedata => avs_s0_writedata,
	x   			 => x,
	y   			 => y,
    data_ready       => data_ready,
	reset_n			 => reset_n	,
	data_valid       => data_valid,
	encryption		 => encryption,
	key_length   	 => key_length     ,
	key_valid        => key_valid      ,
	key32_1 		 => key32_1, 
	key32_2 		 => key32_2,
	key32_3 		 => key32_3,
	key32_4 		 => key32_4,
	key32_5 		 => key32_5,
	key32_6 		 => key32_6,
	data32_1		 => data32_1,
	data32_2		 => data32_2,
	data32_3		 => data32_3,
	data32_4		 => data32_4,
	avs_s0_readdata  => avs_s0_readdata
);

-------------------------------------------------------Storage------------------------------
store_data : entity work.Simon_CH_Store port map
(	
	clk 			 => clk, 								
	reset_n 	     => reset_n,
	data_valid       => data_valid,
	key_valid        => key_valid,
	data_check       => data_check,
	key_start        => key_start,
	key_64bit        => key_64bit,
	data_input       => data_input,
	key32_1 		 => key32_1,
	key32_2 		 => key32_2,
	key32_3 		 => key32_3,
	key32_4 		 => key32_4,
	key32_5 		 => key32_5,
	key32_6 		 => key32_6,
	data32_1		 => data32_1,
	data32_2		 => data32_2,
	data32_3		 => data32_3,
	data32_4		 => data32_4
);

-------------------------------------------------------DECRYPTION----------------------------
decryption_data : entity work.Simon_CH_Decrypt port map
(
	clk              => clk,
    reset_n          => reset_n,
	data_valid		 => data_valid,
	key_length 		 => key_length,
	continue		 => continue,
	data_input       => data_input,
	encryption		 => encryption,
	data_ready 		 => data_ready,
	data_check       => data_check,
	subkeys			 => subkeys, 
	x	     		 => x,
	y				 => y 
);

-----------------------------------------------------SUBKEYS-GENERATION----------------------------
  -- This component could NOT be split into a different file due to a type subkeys used. The 
  -- subkyes required the previous values therefore it could not be an input or output. 
  
  -- purpose: To generate subkeys 
  -- type   : sequential with sychronous reset 
  -- inputs : clk, reset, key_valid, key_start 
  -- outputs: subkeys 
init:process(clk,reset_n,key_valid,key_64bit) is -- initialisation process for simon algorithm	
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 	
					subkeys <= (others=> (others=>'0')); -- subkeys is now reset 
					z <= (others => '0');-- value of z is assigned depending on the key length 	
					continue <= '0';
					seq_init <= 0; -- reset the state machine signal 
					l <= 3; -- for 192-bit key_length, also used for 128-bit key length 
					
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if (key_valid = '0' and key_start= '1') then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit
								
							case seq_init is
							
								when 0 =>
									continue <= '0'; -- make it zero to prevent decryption 
									z <= x"7369f885192c0ef5"; -- assign value to z
									subkeys(1) <= key_64bit(0);
									subkeys(0) <= key_64bit(1);
									seq_init <= 1; -- move to the next state
									
								when 1=>
									if ((l-1) < 66) then -- l is 3 therefore -1 to make it 2(for i in 2 to 66 loop) 
										subkeys(l-1) <= (c xor (z and one) xor subkeys((l-1)-2) 
										xor ROR_64(subkeys((l-1)-1),3) xor ROR_64(subkeys((l-1)-1),4));
										z<= shift_right(z,1);
										l <= l +1;
									else -- for loop is now complemented 
										subkeys(66) <= (c xor one xor subkeys(64) xor 
										ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4));
										seq_init <= 2; -- move to next state 
									end if; -- close if statement for "for loop"	
									
								when 2 =>
									subkeys(67) <= (c xor subkeys(65) xor ROR_64(subkeys(66),3) 
									xor ROR_64(subkeys(66),4) );
									continue <= '1'; -- now start decrypting 
									-- do not move to next state, only go back to state 0 when reset 
								when others=> null;
							end case;-- close case statements for seq_init
									
									
						elsif key_length = "01" then -- key length is 192-bit
							
							case seq_init is 
								when 0=> 
									continue <= '0'; -- do not start decrypting 
									z <= x"fc2ce51207a635db"; -- assign value to z
									subkeys(0) <= key_64bit(2);
									subkeys(1) <= key_64bit(1);
									subkeys(2) <= key_64bit(0);
									seq_init <= 1;-- move to the next state 
									
								when 1=>
									if l < 67 then --for i in 3 to 67 loop 
										subkeys(l) <= (c xor (z and one) xor subkeys(l-3) xor ROR_64(subkeys(l-1),3) 
										xor ROR_64(subkeys(l-1),4) );
										z<= shift_right(z,1);
										l <= l+1;-- increment variable each clock cycle 
									else  -- for loop is completed 
										subkeys(67) <=	(c xor subkeys(64) xor ROR_64(subkeys(66), 3) xor ROR_64(subkeys(66), 4) );
										seq_init <= 2;-- move to the next state when for loop is done 
									end if; -- close if statement for l<67, hardware loop 
								when 2=>
									subkeys(68) <= (c xor one xor subkeys(65) xor ROR_64(subkeys(67),3) xor ROR_64(subkeys(67),4) );
									continue <= '1';-- now start decrypting
								when others=> null; -- stop 
							end case;-- close case statements for seq_init
							
						end if;-- close if statement for key_length 
				
					end if; -- close if statement for key_valid 
					
				end if;-- close if statement for reset_n
			
			end if;-- close if statement for rising_edge(clk)
	
end process init;
-----------------------------------------------------END--------------------------------------------

end architecture;