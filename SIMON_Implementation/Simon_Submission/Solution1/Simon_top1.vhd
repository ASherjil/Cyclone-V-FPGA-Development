-------------------------------------THIS IS THE VHDL Implementation of SIMON
-------------------------------------THIS SOLUTION CATERS FOR BOTH 128-BIT AND 192-BIT KEYS 
-------------------------------------USED FOR VALIDATION OF TESTBENCH PROVED FOR CW
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_C_PACKET.all; 

entity SIMON_top1 is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	key_length 		 : in std_logic_vector(1 downto 0):= (others => '0'); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
	key_valid 		 : in std_logic; -- enable intialisation = '1', disable = '0'
	key_word_in 	 : in std_logic_vector(31 downto 0):= (others => '0'); -- key for initialising the encyrption algorithm 
	data_valid,encryption : in std_logic;
	data_word_in 	 : in std_logic_vector (31 downto 0) := (others => '0');
	data_word_out 	 : out std_logic_vector (31 downto 0);
	data_ready 		 : out std_logic := '0'
);

end entity; 

architecture rtl of SIMON_top1 is
--------------------------------------SIGNALS FOR KEYS INITIALISATION-------------------------
signal subkeys   : t_subkeys;-- store subkeys in this array 
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
signal key_start : std_logic := '0';-- signal to star generating subkeys 
-----------------------------------------SIGNALS FOR DATA STORAGE AND ENCRYPTION/DECRYPTION 
signal data_input  : t_data_in; -- data to be encrypted 
signal data_check  : std_logic := '0'; -- signal to prevent starting the encryption/decryption too early 
signal data_flag1  : std_logic := '0'; -- signal for MUX, data_ready for encryption
signal data_flag2  : std_logic := '0';-- signal for MUX, data_ready for decryption
signal data_out1   : unsigned(31 downto 0); -- signal for MUX, data_word_out for encryption
signal data_out2   : unsigned(31 downto 0);-- signal for MUX, data_word_out for decryption 

begin
	
-- process(all) is implemented to ensure no signals are missed(VHDL 2008 only)


-----------------------------------------------------------GENERATE SUBKEYS---------------------------
keygen_C : entity work.Simon_keys1 port map
(
	clk      	=> clk,
	reset_n  	=> reset_n,
	key_valid 	=> key_valid,
	key_start	=> key_start,
	key_length  => key_length,
	key_64bit   => key_64bit,
	subkeys     => subkeys
);
--------------------------------------------------------DESCRIBE DATA MUX SWITCH------------------
-- when encrypting make data_read <= data_flag1
-- when decrypting make data_read <= data_flag2
data_ready <= data_flag1 when (encryption = '1') else data_flag2; 
-- when encrypting make data_word_out <= data_out1
-- when decrypting make data_word_out <= data_out2
data_word_out <= std_logic_vector(data_out1) when (encryption = '1') else std_logic_vector(data_out2);
-- data transfer for output 32-bit per clock cycle 
--------------------------------------------------------------ENCRYPTION--------------------------
Encrypt1_C : entity work.Simon_Encrypt1 port map
(
	clk              => clk       ,
    reset_n          => reset_n   ,
	data_valid       => data_valid, 
	data_check 		 => data_check,		
	encryption 		 => encryption,
	key_length       => key_length,
	subkeys			 => subkeys   ,
	data_input		 => data_input, 
	data_flag1 		 => data_flag1,
	data_out1   	 => data_out1 
);
--------------------------------------------------------------DECRYPTION------------------------
Decrypt1_C : entity work.Simon_Decrypt1 port map
(
	clk              => clk       ,
    reset_n          => reset_n   ,
	data_valid       => data_valid, 
	data_check 		 => data_check,		
	encryption 		 => encryption,
	key_length       => key_length,
	subkeys			 => subkeys   ,
	data_input		 => data_input, 
	data_flag2 		 => data_flag2,
	data_out2   	 => data_out2 
);
-------------------------------------------------------------STORE INCOMING KEYS-------------
key_incoming : entity work.key_in1 port map
(
	clk              => clk        ,
    reset_n          => reset_n    ,
	key_length       => key_length ,
	key_valid		 => key_valid  ,
	key_word_in	     => key_word_in,	
	key_start		 => key_start  ,
	key_64bit  		 => key_64bit
);
------------------------------------------------------------STORE INCOMING DATA----------------
data_incoming : entity work.data_in1 port map
(
	clk              => clk,
    reset_n          => reset_n,
	data_valid       => data_valid,
	data_word_in     => data_word_in,
	data_check		 => data_check,
	data_input  	 => data_input
);
------------------------------------------------------------END--------------------------------
end architecture;
