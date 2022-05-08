library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SIMON_top is -- all these signals are required to validate the testbench provided 
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

architecture rtl of SIMON_top is
--------------------------------------SIGNALS FOR KEYS INITIALISATION-------------------------
signal nrSubkeys : integer;
type t_subkeys is array(0 to 68) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;

type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
constant one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";-- one represented as 64-bit ;
constant c : unsigned(63 downto 0):= x"fffffffffffffffc"; -- constant value for both keys 
signal key_start : std_logic := '0';

--------------------------------------SIGNALS FOR SEQUENTIAL PROCESSES 

signal seq1 : integer := 0; -- intermediate signal used for implementing sequential design(encryption)
signal seq2: integer := 0; -- intermediate signal used for implementing sequential design(decryption)
signal key_seq : integer := 0; -- signal for storing key in 64-bit signal array 
signal control_flag1 : std_logic := '0'; -- intermediate flag for outputting data and encrypting 192-bit key 
signal control_flag2 : std_logic := '0';-- intermediate flag for outputting data and decrypting 192-bit key 

-----------------------------------------SIGNALS FOR DATA STORAGE AND ENCRYPTION/DECRYPTION 
type t_data_in is array (0 to 1) of unsigned(63 downto 0);
signal data_input : t_data_in; -- data to be encrypted 
signal i : integer := 0; -- signal for taking data in, intermediate signal for sequential circuit 
signal data_check : std_logic := '0'; -- signal to prevent starting the encryption/decryption too early 
signal data_flag1 : std_logic := '0'; -- signal for MUX, data_ready for encryption
signal data_flag2 : std_logic := '0';-- signal for MUX, data_ready for decryption
signal data_out1 : unsigned(31 downto 0); -- signal for MUX, data_word_out for encryption
signal data_out2 : unsigned(31 downto 0);-- signal for MUX, data_word_out for decryption 

--------------------------------------------------------FUNCITONS------------------------------

function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate RIGHT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;

function ROL_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate LEFT circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_left(x,n) OR shift_right(x,(64-n)) );
	return unsigned(shifted);
end function;

function f(x : in unsigned(63 downto 0)) -- helper function for emulating the "R2" function
		return unsigned is variable rolled : unsigned(63 downto 0);
begin
		rolled := ( (ROL_64(x,1) and ROL_64(x,8)) xor ROL_64(x,2) );
		return unsigned(rolled);
end function;
---------------------------------------------------------------------------------------
begin
	
-- process(all) is implemented to ensure no signals are missed(VHDL 2008 only)

key_in:	process(all) is --  process to take in key and store in an array  
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
	
		if rising_edge(clk) then -- only begin if key_valid = '1'
		
			if reset_n = '1' then 
			
				if key_valid = '1' then -- only run when key_valid = '1' 
						
						case key_seq is 
							
							when 0 =>
								key_start <= '0'; -- do not initialise 
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
								
								if key_length = "00" then 
									key_start<= '1';-- begin initialisation 
								end if;
								
							when 4=>
								sub_key_first := unsigned(key_word_in);
								key_seq <= 5;
								
							when 5=>-- store into the second element of the array
								key_seq <= 0;
								sub_key_second := unsigned(key_word_in);
								key_64bit(2) <= unsigned(sub_key_second) 
								& unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
								
								if key_length = "01" then 
									key_start<= '1';-- begin initialisation 
								end if;
								
							when others=>
								key_seq <= 0; -- do nothing 
							
						end case;-- close case statement for key_seq  
		
				end if; -- close if statement for key_valid 
				
			elsif reset_n = '0' then 
			
				key_64bit(0) <= (others=> '0');
				key_64bit(1) <= (others=> '0');
				key_64bit(2) <= (others=> '0');
				key_seq <= 0;
				key_start <= '0';
				
			end if; -- close if statement for reset_n 
			
		end if;-- if for rising_edge clock 
		
end process key_in;
	
		
init: process(all) is -- initialisation process for simon algorithm 
		variable z : unsigned(63 downto 0);
		variable subkeys_vars : t_subkeys;
		variable seq0 : integer := 0;
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 
				
				subkeys <= (others=> (others=>'0')); -- subkeys is now reset
				nrSubkeys <= 0;
				seq0 := 0;
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if ((key_valid = '0') and (key_start = '1')) then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit

							case seq0 is
							
									when 0=>
									
										nrSubkeys <= 68; -- nrsubkeys 	
										z := x"7369f885192c0ef5"; -- assign value to z
										subkeys_vars(1) := key_64bit(0);
										subkeys_vars(0) := key_64bit(1);
										
										seq0 := 1;
									
									when 1=>
									
										for i in 2 to 66 loop
											subkeys_vars(i) := (c xor (z and one) xor subkeys_vars(i-2) 
											xor ROR_64(subkeys_vars(i-1),3) xor ROR_64(subkeys_vars(i-1),4));
											z:= shift_right(z,1);
										end loop;
									
										seq0 := 2;
										
									when 2=>
										subkeys_vars(66) := (c xor one xor subkeys_vars(64) 
										xor ROR_64(subkeys_vars(65),3) xor ROR_64(subkeys_vars(65),4));
										
										seq0 :=3;
									when 3=>
									
										subkeys_vars(67) := (c xor subkeys_vars(65) 
										xor ROR_64(subkeys_vars(66),3) xor ROR_64(subkeys_vars(66),4) );
										
										subkeys <= subkeys_vars; -- now assign the variable value to signal
									
									when others=> -- do nothing 
										seq0 := 0;
										
									end case; 
								
						elsif key_length = "01" then -- key length is 192-bit
					
							case seq0 is 
							
								when 0=>
								
									nrSubkeys <= 69; -- nrsubkeys 
									z:= x"fc2ce51207a635db"; -- assign value to z
									subkeys_vars(0) := key_64bit(2);
									subkeys_vars(1) := key_64bit(1);
									subkeys_vars(2) := key_64bit(0);
									
									seq0 := 1;
								
								when 1=>
								
									for i in 3 to 67 loop 
										subkeys_vars(i) := (c xor (z and one) xor 
										subkeys_vars(i-3) xor ROR_64(subkeys_vars(i-1),3) 
										xor ROR_64(subkeys_vars(i-1),4) );
										
										z:= shift_right(z,1);
									end loop;
									
									seq0 := 2;
									
								when 2 =>
								
									subkeys_vars(67) :=	(c xor subkeys_vars(64) xor 
									ROR_64(subkeys_vars(66), 3) xor ROR_64(subkeys_vars(66), 4) );
								
									seq0 := 3;
									
								when 3=>
								
									subkeys_vars(68) := (c xor one xor subkeys_vars(65) xor 
									ROR_64(subkeys_vars(67),3) xor ROR_64(subkeys_vars(67),4) );
									
									subkeys <= subkeys_vars;-- assign variable to signal 
									
								when others =>
									seq0 := 0;
									
								end case; 
									
						end if;-- close if statement for key_length 
				
					end if; -- close if statement for key_valid 
					
				end if;-- close if statement for reset_n
			
			end if;-- close if statement for rising_edge(clk)
	
end process init;
	
	
data_in : process(all) is --  process to take in data and store in an array  
			variable data1 : unsigned(31 downto 0);
			variable data2 : unsigned(31 downto 0);
		begin 
		
			if (rising_edge(clk)) then
			
				if (reset_n = '1') then 	
						
					if data_valid = '1' then	
					
						case i is 
							when 0 =>
								data_check <= '0';
								data1 := unsigned(data_word_in);
								i <= 1; -- move to the next state 
							when 1 =>
								data2:= unsigned(data_word_in);
								data_input(0) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								i <= 2; -- move to the next state 
							when 2=>
								data1 := unsigned(data_word_in);
								i<= 3;-- move to the next state 
							when 3=>
								data2 := unsigned(data_word_in);-- go back to the first state  
								data_input(1) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
								data_check <= '1';
							when others=>
								i <= 0;
						end case;
						
					end if; --close if statement for data_valid 
								
				elsif (reset_n = '0') then 
				
					data_input(0) <= (others=>'0');
					data_input(1) <= (others=> '0');
					data_check <= '0'; -- reset this data_check 
					i <= 0;
					
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;

--------------------------------------------------------DESCRIBE DATA SWITCH MUX-----------------------
-- when encrypting make data_read <= data_flag1
-- when decrypting make data_read <= data_flag2
data_ready <= data_flag1 when (encryption = '1') else data_flag2; 
-- when encrypting make data_word_out <= data_out1
-- when decrypting make data_word_out <= data_out2
data_word_out <= std_logic_vector(data_out1) when (encryption = '1') else std_logic_vector(data_out2);
-- data transfer for output 32-bit per clock cycle 
-------------------------------------------------------------------------------------------------------

encryption_begin: process(all) is  -- begin encrypting 
				variable k : integer := 0; -- intermediate variable for loop implementation 
				variable x : unsigned(63 downto 0);
				variable y : unsigned(63 downto 0);
				variable t : unsigned(63 downto 0);
				variable int_x : t_subkeys;
				variable int_y : t_subkeys;
			begin	
				
				if rising_edge(clk) then 
									
					if reset_n = '0' then 
					
					x := (others => '0'); -- reset everything 
					y := (others=> '0');
					int_x :=(others=> (others=>'0'));
					int_y := (others=> (others=>'0'));
					seq1 <= 0;
					control_flag1 <= '0';
					data_flag1 <= '0';
					data_out1 <= (others=>'0');
					k := 0;
				
					elsif reset_n = '1' then 
						
						if (data_valid = '0' and 
						encryption = '1' and data_check = '1') then
							
							if key_length = "00" then -- key length is 128-bit
						
									case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
											when 0=>
											
												int_x(0) := data_input(0);
												int_y(0) := data_input(1); 
												
												seq1 <= 1;
											when 1=>
											
												while k < 68 loop
														int_y(k+1) := int_y(k) xor f(int_x(k));
														int_y(k+2) := int_y(k+1) xor subkeys(k);	
														int_x(k+1) := int_x(k) xor f(int_y(k+2));
														int_x(k+2) := int_x(k+1) xor subkeys(k+1);
													k := k +2; -- increment by 2
												end loop;
												
												seq1<= 2;
							
											when 2 =>
												y := int_y(68);
												x := int_x(68);
												seq1 <= 3;-- increment 
											when 3 =>
											
												data_flag1 <= '1'; -- make data_ready = '1'											
												data_out1 <= (x(31 downto 0)); -- transfer first peice of data 
												seq1 <= 4;-- increment 
												
											when 4 =>									
												data_out1 <= (x(63 downto 32));  
												seq1 <= 5;-- increment 
											
											when 5=>
												data_out1 <= (y(31 downto 0));
												seq1 <= 6;
												
											when 6=>
												data_out1 <= (y(63 downto 32));
												data_flag1 <= '0'; -- make data_ready = '0'	
											
											-- stay in state 7 unless reset 
											when others=>
												seq1 <= 0; -- do nothing 
									end case;
								
								
							elsif key_length = "01" then -- key length is 192-bit
									
									case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
										when 0=>
										
											int_x(0) := data_input(0);
											int_y(0) := data_input(1); 
											
											seq1 <= 1;
											
										when 1=>
										
											while k < 68 loop
													int_y(k+1) := int_y(k) xor f(int_x(k));
													int_y(k+2) := int_y(k+1) xor subkeys(k);	
													int_x(k+1) := int_x(k) xor f(int_y(k+2));
													int_x(k+2) := int_x(k+1) xor subkeys(k+1);
												k := k +2; -- increment by 2
											end loop;
											seq1<= 2;
										when 2 =>
											x := int_x(68);
											y := int_y(68);
											
											seq1 <= 3;
										when 3=>
											y := y xor f(x);
											seq1 <= 4;
										when 4=>
											y := y xor subkeys(68);
											seq1 <= 5;
										when 5 =>
											t := x;
											seq1 <= 6;
										when 6 =>
											x := y;
											seq1 <= 7;
										when 7 =>
											y := t;
											seq1 <= 8;
										when 8 =>
											data_flag1 <= '1'; -- this makes data_ready <= '1'
											data_out1 <= (x(31 downto 0));
											seq1 <= 9;
										when 9=>
											data_out1 <= (x(63 downto 32));
											seq1 <= 10;
										when 10=>
											data_out1 <= (y(31 downto 0));
											seq1 <= 11;
										when 11=>
											data_out1 <= (y(63 downto 32));
											data_flag1 <= '0';-- this makes data_ready <= '0'
											-- stay in state 12 unless reset 
										when others=>
											seq1<= 0;
										end case;
							end if; -- close if statement for key length 
							
						end if; -- close if statement for data valid and encryption 
						
					end if; -- close if statement for reset_n
					
				end if; -- close if statement for rising edge clock 
end process encryption_begin;


decryption_begin: process(all) is -- begin decrypting 
variable k : integer := 0; -- variable for while loop 
variable x : unsigned(63 downto 0);
variable y : unsigned(63 downto 0);
variable t : unsigned(63 downto 0);
variable int_x : t_subkeys;
variable int_y : t_subkeys;

				begin
				
				if rising_edge(clk) then 
					
					if reset_n = '0' then
				
						seq2 <= 0; -- reset everything
						x := (others=> '0');
						y := (others=> '0');
						int_x :=(others => (others => '0'));
						int_y := (others => (others => '0'));
						data_flag2 <= '0';
						data_out2 <= (others=> '0');
						k := 0;
					
					elsif reset_n = '1' then 
					
						if (data_valid = '0' and 
						encryption = '0' and data_check = '1') then
							
							if key_length = "00" then  -- 128-bit
							
								case seq2 is  
										
										when 0=>
										
											int_x(0) := data_input(0);
											int_y(0) := data_input(1);									
											seq2 <=1;
											
										when 1=>
												while k < 67 loop
														int_x(k+1) := int_x(k) xor f(int_y(k));
														int_x(k+2) := int_x(k+1) xor subkeys(67-k);	
														int_y(k+1) := int_y(k) xor f(int_x(k+2));
														int_y(k+2) := int_y(k+1) xor subkeys(67 - (k+1));
													k := k +2; -- increment by 2
												end loop;
											seq2<= 2;
										when 2=>
											x := int_x(68);
											y := int_y(68);	
											seq2<= 3;
										when 3=>
											data_out2 <= x(31 downto 0);-- output the first 32-bit 
											data_flag2 <= '1';-- data_ready is now 1
											seq2 <= 4;
										when 4=>
											data_out2 <= x(63 downto 32);
											seq2 <= 5;   
										when 5=>         
											data_out2 <= y(31 downto 0);
											seq2 <= 6; 
										when 6=>
											data_out2 <= y(63 downto 32);
											data_flag2 <= '0'; -- now stop, data_ready <= '0'
											
										when others=> 
											seq2 <= 0; -- do nothing
										
									end case;
							
							elsif key_length = "01" then -- if key is 192-bit  
								
								case seq2 is  
										when 0=>
											t := data_input(1); -- t = y
											seq2 <= 1;
										when 1=>
											y := data_input(0); -- y = x
											seq2 <= 2;
										when 2=>
											x := t;
											seq2 <= 3;
										when 3=>
											y := y xor subkeys(68);
											seq2 <= 4;
										when 4=>
											y := y xor f(x);
											seq2 <= 5;
										when 5=>
											int_x(0) := x;
											int_y(0) := y;									
											seq2 <=6;
											
										when 6=>
												while k < 68 loop
														int_x(k+1) := int_x(k) xor f(int_y(k));
														int_x(k+2) := int_x(k+1) xor subkeys(67-k);	
														int_y(k+1) := int_y(k) xor f(int_x(k+2));
														int_y(k+2) := int_y(k+1) xor subkeys(67 - (k+1));
													k := k +2; -- increment by 2
												end loop;
												
											seq2 <= 7;
										when 7=>
											x := int_x(68);
											y := int_y(68);	
											seq2 <= 8;
										when 8=> -- transfer data to data_word_out 
											data_out2 <= x(31 downto 0); 
											data_flag2 <= '1';-- data_ready is now 1
											seq2 <= 9;
										when 9=>
											data_out2 <= x(63 downto 32);
											seq2 <= 10;
										when 10=>
											data_out2 <= y(31 downto 0);
											seq2 <= 11; 
										when 11=>
											data_out2 <= y(63 downto 32);
											data_flag2 <= '0'; -- now stop, data_ready <= '0'
											-- stay in state 11 unless reset 
										when others=> 
											seq2 <= 0; -- does nothing
										
									end case;
								
							end if;-- close if statement for key length 
						
						end if; -- close if statement for data_valid and encryption 
						
					end if; -- close if statement for reset_n 
					
				end if;-- close if statement for rising edge of clock 
				
end process decryption_begin;

end architecture;
