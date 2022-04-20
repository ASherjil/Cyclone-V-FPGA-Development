library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SIMON_Init is 
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

architecture rtl of SIMON_Init is

--------------------------------------Intermediate signals and arrays--------------------------- 
signal nrSubkeys : integer;
type t_subkeys is array(0 to 71) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;


type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long

signal seq1 : integer := 0; -- intermediate signal used for implementing sequential design(encryption)
signal seq2: integer := 0; -- intermediate signal used for implementing sequential design(decryption)
signal control_flag1 : std_logic := '0'; -- intermediate flag for outputting data and encrypting 192-bit key 
signal control_flag2 : std_logic := '0';-- intermediate flag for outputting data and decrypting 192-bit key 

type t_data_in is array (0 to 1) of unsigned(63 downto 0);
signal data_input : t_data_in; -- data to be encrypted 
signal i : integer := 0; -- signal for taking data in, intermediate signal for sequential circuit 
signal flag1 : std_logic := '0'; -- signal to prevent starting the encryption/decryption too early 
signal data_flag1 : std_logic := '0'; -- signal for MUX, data_ready for encryption
signal data_flag2 : std_logic := '0';-- signal for MUX, data_ready for decryption
signal data_out1 : unsigned(31 downto 0); -- signal for MUX, data_word_out for encryption
signal data_out2 : unsigned(31 downto 0);-- signal for MUX, data_word_out for decryption 

--------------------------------------------------------FUNCITONS------------------------------

function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate Right circular shift 32 bits
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
	

key_in:	process(all) is --  process to take in data and store in an array  
		variable j: integer := 0;
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
	
		
		if (rising_edge(clk) and key_valid = '1') then -- only begin if key_valid = '1'
			
				if key_length = "00" then  -- 128-bit key 
					if j = 4 then -- reset j variable for 128-bit keys
						j := 0;
					end if;
				elsif key_length = "01" then -- 192-bit key
					if j = 6 then -- reset j variable for 192-bit keys 
						j := 0;
					end if;
				end if;-- close if statement for key_length detection 
				
				case j is 
					
					when 0 =>sub_key_first := unsigned(key_word_in);
					when 1 => -- store into the first element of the array 
						sub_key_second := unsigned(key_word_in);
						key_64bit(0) <=  unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
						
					when 2=>sub_key_first := unsigned(key_word_in); 
					when 3=> -- store into the second element of the array
						sub_key_second := unsigned(key_word_in);
						key_64bit(1) <= unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)				
						
					when 4=>sub_key_first := unsigned(key_word_in);
						
					when 5=>-- store into the second element of the array
						sub_key_second := unsigned(key_word_in);
						key_64bit(2) <= unsigned(sub_key_second) & unsigned(sub_key_first); -- store 64-bit key (second<<31 | first)
						
					when others=>
						null; -- do nothing 
					
				end case;
	
				j := j+1;-- increment the variable 
				
		end if;-- if for rising_edge clock 
	end process key_in;
	
		
init:process(all) is -- initialisation process for simon algorithm 
	
		variable c : unsigned(63 downto 0):= x"fffffffffffffffc"; 
		variable z : unsigned(63 downto 0);
		variable one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";		
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 	
				-- reset_n == 0 do not execute  
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if key_valid = '0' then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit
						
							z := x"7369f885192c0ef5"; -- assign value to z
							nrSubkeys <= 68; -- nrsubkeys 
							
							subkeys(1) <= key_64bit(0);
							subkeys(0) <= key_64bit(1);
							
							for i in 2 to 66 loop
								subkeys(i) <= (c xor (z and one) xor subkeys(i-2) xor ROR_64(subkeys(i-1),3) xor ROR_64(subkeys(i-1),4));
								z:= shift_right(z,1);
							end loop;
							
							subkeys(66) <= (c xor one xor subkeys(64) xor ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4));
							subkeys(67) <= (c xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
							
						elsif key_length = "01" then -- key length is 192-bit
							
							z:= x"fc2ce51207a635db"; -- assign value to z
							nrSubkeys <= 69; -- nrsubkeys 
							
							subkeys(0) <= key_64bit(2);
							subkeys(1) <= key_64bit(1);
							subkeys(2) <= key_64bit(0);
								
							for i in 3 to 67 loop 
								subkeys(i) <= (c xor (z and one) xor subkeys(i-3) xor ROR_64(subkeys(i-1),3) xor ROR_64(subkeys(i-1),4) );
								z:= shift_right(z,1);
							end loop;
						
							subkeys(67) <=	(c xor subkeys(64) xor ROR_64(subkeys(66), 3) xor ROR_64(subkeys(66), 4) );
							subkeys(68) <= (c xor one xor subkeys(65) xor ROR_64(subkeys(67),3) xor ROR_64(subkeys(67),4) );
							
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
			
				if (reset_n = '1' and data_valid = '1') then 			
					case i is 
						when 0 =>
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
							flag1 <= '1';
							i<= 0;
						when others=>
							null; -- do nothing 
					end case;
								
				elsif (reset_n = '0') then 
					flag1 <= '0'; -- reset this flag1 
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;

--------------------------------------------------------DESCRIBE DATA SWITCH MUX-----------------------
-- when encrypting make data_read <= data_flag1
-- when decrypting make data_read <= data_flag2
data_ready <= data_flag1 when (encryption = '1') else data_flag2; 
-- when encrypting make data_word_out <= data_out1
-- when decrypting make data_word_out <= data_out2
data_word_out <= std_logic_vector(data_out1) when (encryption = '1') else std_logic_vector(data_out2);-- data transfer for output 32-bit per clock cycle 
-------------------------------------------------------------------------------------------------------

encryption_begin: process(all) is  -- begin encrypting 
				variable j : integer := 0; -- intermediate variable for loop implementation 
				variable x : unsigned(63 downto 0);
				variable y : unsigned(63 downto 0);
				variable t : unsigned(63 downto 0);
			begin	
				
				if rising_edge(clk) then 
									
					if reset_n = '0' then 
			
					-- enter code here
				
					elsif reset_n = '1' then 
						
						if (data_valid = '0' and encryption = '1' and flag1 = '1') then --data_valid == 0 means that data is transferred
							
							if key_length = "00" then -- key length is 128-bit
							
								if j < nrSubkeys then -- same as : for (i = 0; i < nrSubkeys; i += 2)
								
										case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
												when 0=>
													y := data_input(1) xor f(data_input(0)) ; -- call f function
													seq1 <= 1;-- increment 
												when 1 =>
													y := y xor subkeys(j);
													seq1 <= 2;-- increment 
												when 2 =>
													x := data_input(0) xor f(y); -- call f function
													seq1 <= 3;-- increment 
												when 3 =>
													x := x xor subkeys(j+1); 
													j := j+2; -- j += 2;
													seq1 <= 4;-- increment 
												when 4=>
													y := y xor f(x) ; -- call f function
													seq1 <= 5;-- increment 
												when 5 =>
													y := y xor subkeys(j);
													seq1 <= 6;-- increment 
												when 6 =>
													x := x xor f(y); -- call f function
													seq1 <= 7;-- increment 
												when 7 =>
													x := x xor subkeys(j+1); 
													j := j+2; -- j += 2;
													seq1 <= 4;-- increment but ONLY go back to case 4
						
												when others=>
													null; -- do nothing 
											end case;
									
								else -- nrSubkeys  == 67
										if control_flag1 = '1' then 
										
											case seq1 is 
												when 0=>
													data_out1 <= (x(63 downto 32));
													seq1 <= 1;
												when 1=>
													data_out1 <= (y(31 downto 0));
													seq1 <= 2;
												when 2=>
													data_out1 <= (y(63 downto 32));	
													data_flag1 <= '0'; -- data_ready <= '0'
												when others=>
													null; -- do nothing 
											end case;
										
										elsif control_flag1 = '0' then -- for the first run make 
											control_flag1 <= '1'; -- enable sequential data transfer 
											data_flag1 <= '1'; -- make data_ready = '1'
											seq1 <= 0; -- reset seq1 signal to start case statements 
											
											data_out1 <= (x(31 downto 0)); -- transfer first peice of data 
											
										end if; -- close if statement for control flag 
										
								end if; -- close if statement for j < nrSubkeys 
								
							elsif key_length = "01" then -- key length is 192-bit
									
									if (j < (nrSubkeys-1)) then
																		
											case seq1 is 
												when 0=>
													y := data_input(1) xor f(data_input(0)) ; -- call f function
													seq1 <= 1;-- increment 
												when 1 =>
													y := y xor subkeys(j);
													seq1 <= 2;-- increment 
												when 2 =>
													x := data_input(0) xor f(y); -- call f function
													seq1 <= 3;-- increment 
												when 3 =>
													x := x xor subkeys(j+1); 
													j := j+2; -- j += 2;
													seq1 <= 4;-- increment 
												when 4=>
													y := y xor f(x) ; -- call f function
													seq1 <= 5;-- increment 
												when 5 =>
													y := y xor subkeys(j);
													seq1 <= 6;-- increment 
												when 6 =>
													x := x xor f(y); -- call f function
													seq1 <= 7;-- increment 
												when 7 =>
													x := x xor subkeys(j+1); 
													j := j+2; -- j += 2;
													seq1 <= 4;-- increment but ONLY go back to case 4
						
												when others=>
													null; -- do nothing 
											end case;
									else -- for loop from i=0 till (i<nrSubkeys-1) has finished 
											
										if control_flag1 = '1' then
											case seq1 is 
												when 0=> 
													y := y xor f(x);
													seq1 <= 1;
												when 1=>
													y := y xor subkeys(68);
													seq1 <= 2;
												when 2 =>
													t := x;
													seq1 <= 3;
												when 3 =>
													x := y;
													seq1 <= 4;
												when 4 =>
													y := t;
													seq1 <= 5;
												when 5 =>
													data_flag1 <= '1'; -- this makes data_ready <= '1'
													data_out1 <= (x(31 downto 0));
													seq1 <= 6;
												when 6=>
													data_out1 <= (x(63 downto 32));
													seq1 <= 7;
												when 7=>
													data_out1 <= (y(31 downto 0));
													seq1 <= 8;
												when 8=>
													data_out1 <= (y(63 downto 32));
													data_flag1 <= '0';-- this makes data_ready <= '0'
												when others=>
													null;
											end case;
											
										elsif control_flag1 = '0' then -- for the first run make 
											control_flag1 <= '1';
											seq1 <= 0; -- reset this 
										end if; -- close if statement for control flag 
										
									end if; -- close if statement for j< nrSubkeys-1
									
							end if; -- close if statement for key length 
							
						end if; -- close if statement for data valid and encryption 
						
					end if; -- close if statement for reset_n
					
				end if; -- close if statement for rising edge clock 
end process encryption_begin;


decryption_begin: process(all) is -- begin decrypting 
					variable j : integer := 67; -- for loop starts at 67 for both 128-bit and 192-bit key length 
					variable x : unsigned(63 downto 0);
					variable y : unsigned(63 downto 0);
					variable t : unsigned(63 downto 0);
				begin
				
				if rising_edge(clk) then 
					
					if reset_n = '0' then
					-- enter code for reset_n
					
					elsif reset_n = '1' then 
					
						if (data_valid = '0' and encryption = '0' and flag1 = '1') then 
							
							if key_length = "00" then  -- 128-bit
							
								if (j >= 0) then  -- for loop implementation "for (int j=67;j >= 0;j -= 2)"
								
									case seq2 is 
										when 0=>
											y := data_input(0) xor f(data_input(1));
											seq2 <= 1;
										when 1=>
											y := y xor subkeys(j);
											seq2 <= 2;
										when 2=>
											x := data_input(1) xor f(y);
											seq2 <= 3;
										when 3=>
											x := x xor subkeys(j-1);
											seq2 <= 4;
											j := j-2; -- decrement by 2
										when 4=>
											y := y xor f(x) ; -- call f function
											seq2 <= 5;-- increment 
										when 5 =>
											y := y xor subkeys(j);
											seq2 <= 6;-- increment 
										when 6 =>
											x := x xor f(y); -- call f function
											seq2 <= 7;-- increment 
										when 7 =>
											x := x xor subkeys(j-1); 
											j := j-2; -- decrement by 2 
											seq2 <= 4;-- increment but ONLY go back to case 4	
										when others=> null; -- do nothing 
									end case;
									
								else-- for loop from i=nrSubkeys-1  0 has finished 
									
									if control_flag2 = '1' then 
										case seq2 is  
											when 0=>  -- now transfer the remaining data        
												data_out2 <= (x(63 downto 32));
												seq2 <= 1;   
											when 1=>         
												data_out2 <= (y(31 downto 0));
												seq2 <= 2;   
											when 2=>         
												data_out2 <= (y(63 downto 32));
												data_flag2<= '0';-- now stop and make data_ready <= '0'
											when others=>
												null;
										end case;
										
									elsif control_flag2 = '0' then -- for the first run make 
										control_flag2 <= '1';
										data_flag2 <= '1';
										seq2 <= 0;
										
										data_out2 <= (x(31 downto 0));-- transfer the first 32-bit of data 
										
									end if; -- close if statement for control flag 
								
								end if;-- close if statement for j, for loop implementation 
							
							elsif key_length = "01" then -- if key is 192-bit  
								
								if (j >= 0) then -- for loop implementation 
								
									case seq2 is  
										when 0=>--------------------------RUNS ONLY ONCE-{-
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
										--------------------------------------------------}-
										when 5=>------------------------START OF FOR LOOP-{-
											x := x xor f(y);
											seq2 <=6;
										when 6=>
											x := x xor subkeys(j);
											seq2 <= 7;
										when 7=>
											y := y xor f(x);
											seq2 <= 8;
										when 8=>
											y := y xor subkeys(j-1);
											j := j-2; -- decrement variable for "for loop"
											seq2 <= 5; -- GO BACK ONLY TO CASE 5-----------}-
										
										when others=> null; -- do nothing
										
									end case;
								else -- now the for loop has ended 
										if control_flag2 = '1' then
										
											case seq2 is 
												when 0=>  -- output the remaining data to data_word_out        
													data_out2 <= (x(63 downto 32));
													seq2 <= 1;   
												when 1=>         
													data_out2 <= (y(31 downto 0));
													seq2 <= 2;   
												when 2=>         
													data_out2 <= (y(63 downto 32));
													data_flag2<= '0'; -- now stop, data_read <= '0'
												when others=>
													null;
											end case;
										
										
										elsif control_flag2 = '0' then -- once the for loop is finished, output the data 
											control_flag2 <= '1';
											data_flag2 <= '1';-- data_ready is now 1
											seq2 <= 0;-- reset this signal back to 0 
											data_out2 <= (x(31 downto 0));-- output the first 32-bit 
											
										end if;-- close if statement for control_flag2
										
								end if; -- close if statement for "for loop" j >= 0
								
							end if;-- close if statement for key length 
						
						end if; -- close if statement for data_valid and encryption 
						
					end if; -- close if statement for reset_n 
					
				end if;-- close if statement for rising edge of clock 
				
end process decryption_begin;

end architecture;
