library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


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

type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long

type t_data_in is array (0 to 1) of unsigned(63 downto 0);
signal data_input : t_data_in; -- data to be encrypted 

type t_subkeys is array(0 to 68) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;
signal zs      : t_subkeys;
signal z1      : unsigned(63 downto 0);
signal key_start : std_logic := '0';

----------------------------------------------------------
type t_store_data is array(0 to 34) of unsigned(63 downto 0);
signal enc_x : t_store_data;
signal enc_y : t_store_data;-- signal array to store x and y values 
signal dec_x : t_store_data;
signal dec_y : t_store_data;-- signal array to store x and y values 
signal x_enc_final : unsigned(63 downto 0);
signal y_enc_final : unsigned(63 downto 0);
signal x_dec_final : unsigned(63 downto 0);
signal y_dec_final : unsigned(63 downto 0);
----------------------------------------Sequential signals------------------------------------------
signal key_seq : integer := 0; -- signal for storing key in 64-bit signal array 
signal data_seq : integer := 0; -- signal for taking data in, intermediate signal for sequential circuit 
signal continue_signal : std_logic := '0'; -- signal for continuing 
signal output_seq : integer := 0;
--------------------------------------------------------------------------------------------------------
-- one represented as 64-bit
constant one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";
constant c : unsigned(63 downto 0):= x"fffffffffffffffc"; -- constant value for both keys length 

-----------------------------------------------------------FUNCTION-------------------
function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate RIGHT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;
-------------------------------------------------------------------------------------------
	
begin

key_in:	process(all) is --  process to take in key and store in an array  
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
	
		if rising_edge(clk) then -- only begin if key_valid = '1'
		
			if reset_n = '1' then 
			
				if key_valid = '1' then -- only run when key_valid = '1' 
						
						case key_seq is 
							
							when 0 =>
								sub_key_first := unsigned(key_word_in);
								key_seq <= 1;
								
							when 1 => -- store into the first element of the array 
								sub_key_second := unsigned(key_word_in);
								key_64bit(0) <=  unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
								key_seq <= 2;
								
							when 2=>
								sub_key_first := unsigned(key_word_in); 
								key_seq <= 3;
								
							when 3=> -- store into the second element of the array
								sub_key_second := unsigned(key_word_in);
								key_64bit(1) <= unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)				
								key_seq <= 4;
								
							when 4=>
								sub_key_first := unsigned(key_word_in);
								key_seq <= 5;
								
							when 5=>-- store into the second element of the array
								key_seq <= 0;
								sub_key_second := unsigned(key_word_in);
								key_64bit(2) <= unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
								
							when others=>
								key_seq <= 0; -- do nothing 
							
						end case;-- close case statement for key_seq  
		
				end if; -- close if statement for key_valid 
				
			elsif reset_n = '0' then 
			
				key_64bit(0) <= (others=> '0');
				key_64bit(1) <= (others=> '0');
				key_64bit(2) <= (others=> '0');
				key_seq <= 0;
				
			end if; -- close if statement for reset_n 
			
		end if;-- if for rising_edge clock 
		
end process key_in;

data_in : process(all) is --  process to take in data and store in an array  
			variable data1 : unsigned(31 downto 0);
			variable data2 : unsigned(31 downto 0);
		begin 
		
			if (rising_edge(clk)) then
			
				if (reset_n = '1') then 	
						
					if (data_valid = '1' or continue_signal = '1') then	
					
						case data_seq is 
							when 0 =>
								data1 := unsigned(data_word_in);
								data_seq <= 1; -- move to the next state 
							when 1 =>
								data2:= unsigned(data_word_in);
								data_input(0) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								data_seq <= 2; -- move to the next state 
							when 2=>
								data1 := unsigned(data_word_in);
								data_seq<= 3;-- move to the next state 
							when 3=>
								data2 := unsigned(data_word_in);-- go back to the first state  
								data_input(1) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								continue_signal <= '1';
								data_seq <= 4;
							when 4=>
								data_ready <= '1';
								
								if encryption = '1' then 
									data_word_out <= std_logic_vector(x_enc_final(31 downto 0));
								elsif encryption = '0' then 
									data_word_out <= std_logic_vector(x_dec_final(31 downto 0));
								end if;
								
								data_seq <= 5;								
							when 5=>
								if encryption = '1' then 
									data_word_out <= std_logic_vector(x_enc_final(63 downto 32));
								elsif encryption = '0' then 
									data_word_out <= std_logic_vector(x_dec_final(63 downto 32));
								end if;
								
								data_seq <= 6;
							when 6=>
							
								if encryption = '1' then 
									data_word_out <= std_logic_vector(y_enc_final(31 downto 0));
								elsif encryption = '0' then 
									data_word_out <= std_logic_vector(y_dec_final(31 downto 0));
								end if;
								
								data_seq <= 7;
							when 7=> 
							
								if encryption = '1' then 
									data_word_out <= std_logic_vector(y_enc_final(63 downto 32));
								elsif encryption = '0' then 
									data_word_out <= std_logic_vector(y_dec_final(63 downto 32));
								end if;
								
								continue_signal <= '0';
								data_ready <= '0';
								-- stay in this state unless reset
							when others=>
								data_seq <= 0;
						end case;
						
					end if; --close if statement for data_valid 
								
				elsif (reset_n = '0') then 
				
					data_input(0) <= (others=>'0');
					data_input(1) <= (others=> '0');
					data_seq <= 0;
					data_ready <= '0';
					continue_signal  <= '0';
					
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;

---------------------------------MUX SWITCH for key length---------------------------
z1 <= (x"7369f885192c0ef5") when (key_length = "00") else (x"fc2ce51207a635db");
-- if key length is 128bit: z is x"7369f885192c0ef5"
-- elseif key_length is 192-bit z is x"fc2ce51207a635db"
------------------------------------------------------Begin Key Initialisation-------
zs(0) <= z1; -- assign initial values
zs(1) <= shift_right(zs(0),1); 

subkeys(0) <= key_64bit(1);-- assign initial values 
subkeys(1)	<= key_64bit(0);-- assign initial values 

subkeys(2) <= (c xor (zs(0) and one) xor subkeys(0)-- generate 2nd subkeys
			xor ROR_64(subkeys(1),3) xor ROR_64(subkeys(1),4));

generator1 : for i in 1 to 63 generate 

generate_keys : entity work.SIMON_keys port map-- begin generator 1
(
	key_in_1  => subkeys(i),
	key_in_2  => subkeys(i+1),
	z_in 	  => zs(i),
	key_out   => subkeys(i+2),
	z_out     => zs(i+1)
);

end generate generator1;

subkeys(66) <= (c xor one xor subkeys(64)-- generate remaining subkeys
		xor ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4)); 
		
subkeys(67) <= (c xor one xor subkeys(65)-- generate remaining subkeys
		xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4));
		
---------------------------------------------------------------ENCRYPTION------------
x_enc_final <= enc_x(34);
y_enc_final <= enc_y(34);
x_dec_final <= dec_x(34);
y_dec_final <= dec_y(34);-- assign the final encrypted/decrypted values 

enc_x(0) <= data_input(0);-- assign initial data 
enc_y(0) <= data_input(1);

generator2 : for i in 0 to 33 generate -- begin generator 2

encrypt_data : entity work.SIMON_Encrypt port map
(
	encryption   => encryption,
	x_in         => enc_x(i),
	y_in         => enc_y(i),
	subkey_in1   => subkeys(i*2),--max_index = (33*2)+1 = 67
	subkey_in2   => subkeys((i*2)+1),
	x_out        => enc_x(i+1),
	y_out		 => enc_y(i+1)
);
end generate generator2;
------------------------------------------------------DECRYPTION-------------------
dec_x(0) <= data_input(0);-- assign initial data 
dec_y(0) <= data_input(1);

generator3 : for i in 0 to 33 generate -- begin generator 3

decrypt_data : entity work.SIMON_Decrypt port map
(
	encryption   => encryption,
	x_in         => dec_x(i),
	y_in         => dec_y(i),
	subkey_in1   => subkeys(67 - (i*2)),--max_index = (33*2)+1 = 67
	subkey_in2   => subkeys(67- ((i*2)+1)),
	x_out        => dec_x(i+1),
	y_out		 => dec_y(i+1)
);
end generate generator3;




end architecture;

	