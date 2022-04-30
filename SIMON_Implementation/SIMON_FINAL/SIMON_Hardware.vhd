-- Contains only decryption for A9 interfacing 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Simon_Hardware is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in std_logic;
	reset 			 : in std_logic;
	avs_s0_address   : in  std_logic_vector(4 downto 0); -- 20 registors being used 
	avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
    avs_s0_readdata  : out std_logic_vector(31 downto 0)
);
end entity; 

architecture rtl of Simon_Hardware is
--------------------------------------Intermedaite signals for avalon bus----------------------
signal reset_n 			 : std_logic;
signal key_length 		 : std_logic_vector(1 downto 0); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
signal key_valid 		 : std_logic; -- enable intialisation = '1', disable = '0'
signal key_word_in 	 	 : std_logic_vector(31 downto 0); -- key for initialising the encyrption algorithm 
signal data_valid        : std_logic;
signal encryption 		 : std_logic;
signal data_word_in 	 : std_logic_vector (31 downto 0);
signal data_word_out 	 : std_logic_vector (31 downto 0);
signal data_ready 		 : std_logic;
-------------------------------------Intermediate signals and arrays for Computations and Control 
signal nrSubkeys : integer;
type t_subkeys is array(0 to 71) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;

type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
signal key32_1 : unsigned (31 downto 0);
signal key32_2 : unsigned (31 downto 0);
signal key32_3 : unsigned (31 downto 0);
signal key32_4 : unsigned (31 downto 0);
signal key32_5 : unsigned (31 downto 0);
signal key32_6 : unsigned (31 downto 0);

signal seq0: integer := 0; -- intermediate signal used for implementing sequential design(decryption)
signal seq1 : std_logic := '0';-- intermediate signal for outputting data and decrypting 192-bit key 

type t_data_in is array (0 to 1) of unsigned(63 downto 0);
signal data_input : t_data_in; -- data to be encrypted 
signal data32_1: unsigned(31 downto 0);
signal data32_2: unsigned(31 downto 0);
signal data32_3: unsigned(31 downto 0);
signal data32_4: unsigned(31 downto 0);

signal i : integer := 0; -- signal for taking data in, intermediate signal for sequential circuit
signal l : integer; 
signal data_check : std_logic := '0'; -- signal to prevent starting the encryption/decryption too early 
----------------------------------------------------------------------------------------------
signal seq3 : integer := 0;-- variable used to design sequential circuit 
signal c : unsigned(63 downto 0);
signal continue : std_logic := '0';
signal key_start : std_logic := '0';
signal z : unsigned(63 downto 0);
signal one : unsigned(63 downto 0);-- 1 represented as 64-bit
signal x : unsigned(63 downto 0);
signal y : unsigned(63 downto 0);
-----------------------------------------------------------------------------------------------
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
	
-- process(all) was implemented to ensure no signals are missed(VHDL 2008 only works in Questasim)
-- and NOT Quartus Prime 21.1

--------------------------------------------------AVALON BUS READ AND WRITE PROCESS---------------
  -- purpose: Respond to write operations from the Avalon bus
  -- type   : sequential
  -- inputs : clk, reset, avs_s0_write, avs_s0_address
  -- outputs: 
write_proc : process (clk, reset) is
begin  -- process write_proc
  if reset = '1'  then                 -- reset active high 
	--reset_n <= '0'; -- make reset_n low 
  elsif rising_edge(clk) then  -- rising clock edge
	--reset_n <= '1'; -- enable reset_n to 1
	
    if avs_s0_write = '1' then
      case avs_s0_address is
		when b"00000" => key_length <= avs_s0_writedata(1 downto 0); --registor #0
		when b"00001" => key_valid <= avs_s0_writedata(0);----registor #1
		when b"00010" => data_valid <= avs_s0_writedata(0);----registor #2
		when b"00011" => encryption <= avs_s0_writedata(0);----registor #3
		
		when b"01011" => reset_n <= avs_s0_writedata(0);----registor #11
		
		when b"00101" => key32_1  <= unsigned(avs_s0_writedata);-----registor #5
		when b"01100" => key32_2  <= unsigned(avs_s0_writedata);-----registor #12
		when b"01101" => key32_3  <= unsigned(avs_s0_writedata);-----registor #13
		when b"01110" => key32_4  <= unsigned(avs_s0_writedata);-----registor #14
		when b"01111" => key32_5  <= unsigned(avs_s0_writedata);-----registor #15
		when b"10000" => key32_6  <= unsigned(avs_s0_writedata);-----registor #16
		
		when b"00100" => data32_1 <= unsigned(avs_s0_writedata);-----registor #4
		when b"10001" => data32_2 <= unsigned(avs_s0_writedata);-----registor #17
		when b"10010" => data32_3 <= unsigned(avs_s0_writedata);-----registor #18
		when b"10011" => data32_4 <= unsigned(avs_s0_writedata);-----registor #19
		
        when others => null;-- do nothing 
      end case;
    end if;
  end if;
end process write_proc;
  
  
-- purpose: Respond to read operation from Avalon bus
-- type   : combinational
-- inputs : avs_s0_read, avs_s0_address
-- outputs: avs_s0_readdata
read_proc : process (avs_s0_read, avs_s0_address,data_ready,x,y) is
begin  -- process read_proc
  if avs_s0_read = '1' then
    case avs_s0_address is
      when b"00110" => avs_s0_readdata <= (B"0000000000000000000000000000000" & data_ready); -- registor# 6
      when b"00111" => avs_s0_readdata <= std_logic_vector(x(31 downto 0));-- registor# 7
	  when b"01000" => avs_s0_readdata <= std_logic_vector(x(63 downto 32)); -- registor# 8
	  when b"01001" => avs_s0_readdata <= std_logic_vector(y(31 downto 0)); -- registor# 9
	  when b"01010" => avs_s0_readdata <= std_logic_vector(y(63 downto 32)); -- registor# 10	  
      when others => avs_s0_readdata <= (others=> 'Z'); -- do nothing 
    end case;
  else
	 avs_s0_readdata <= (others=> 'Z');
  end if;
end process read_proc; 


--------------------------------------------------SIMON ALGORITHM---------------------------------

key_in:	process(clk,key_valid) is --  process to take in key and store in an array  
	--	variable j: integer := 0;-- this variable is used instead to implement a sequential design, 
	--	variable sub_key_first : unsigned(31 downto 0);
	--	variable sub_key_second : unsigned(31 downto 0);
	begin
	
		
		if (rising_edge(clk)) then -- only begin if key_valid = '1'
			
			if (reset_n = '1') then 
				if (key_valid = '1') then 			
						
						key_64bit(0) <= key32_2 & key32_1;
						key_64bit(1) <= key32_4 & key32_3;
						key_64bit(2) <= key32_6 & key32_5;
						key_start <= '1';
						
				end if; -- close if statement for key_valid 	
			
			elsif reset_n = '0' then 
				
			--	sub_key_first := (others=>'0');
			--	sub_key_second := (others => '0');
			key_64bit(0) <= (others=> '0');
			key_64bit(1) <= (others=> '0');
			key_64bit(2) <= (others=> '0');
		--	j := 0; -- reset 
			key_start <= '0';-- do this to prevent initialisation 
			
			end if; -- close if statement for reset_n 
		
		end if;-- close if statement for rising_edge clock 
end process key_in;
	
		
init:process(clk,reset_n,key_valid,key_64bit) is -- initialisation process for simon algorithm
		--variable seq0 : integer := 0;-- variable used to design sequential circuit 
		--variable c : unsigned(63 downto 0):= x"fffffffffffffffc";
		--variable subkeys_var : t_subkeys;
		--variable z : unsigned(63 downto 0);
		--variable one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";-- 1 represented as 64-bit 	
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 	
				
					-- reset_n == 0 do not execute  
					nrSubkeys <= 0;
					subkeys <= (others=> (others=>'0'));
					one <= B"0000000000000000000000000000000000000000000000000000000000000001";
					z <= (others => '0');
					c <= x"fffffffffffffffc"; -- assign reset value to c 
					continue <= '0';
					seq3 <= 0;
					l <= 3; -- for 192-bit key_length
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if (key_valid = '0' and key_start= '1') then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit
						
							z <= x"7369f885192c0ef5"; -- assign value to z
							nrSubkeys <= 68; -- nrsubkeys 
						
							subkeys(1) <= key_64bit(0);
							subkeys(0) <= key_64bit(1);
								
							case seq3 is
							
								when 0 =>
									continue <= '0';
									--	for i in 2 to 66 loop
									if l < 67 then 
										subkeys(l) <= (c xor (z and one) xor subkeys(l-2) 
										xor ROR_64(subkeys(l-1),3) xor ROR_64(subkeys(l-1),4));
										z<= shift_right(z,1);
									--	end loop;
										l <= l +1;
									else 
										seq3 <= 1;
									end if; -- close if statement for 	
								when 1 =>
									subkeys(66) <= (c xor one xor subkeys(64) xor ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4));
									seq3 <= 2;
								when 2 =>
									subkeys(67) <= (c xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
									continue <= '1';
								--	seq0 := 3; 
								when others=> null;
								
							end case;
									
									
						elsif key_length = "01" then -- key length is 192-bit
							
							case seq3 is 
								when 0=> 
									
									continue <= '0';
									z <= x"fc2ce51207a635db"; -- assign value to z
									nrSubkeys <= 69; -- nrsubkeys 
									
									subkeys(0) <= key_64bit(2);
									subkeys(1) <= key_64bit(1);
									subkeys(2) <= key_64bit(0);
									
									seq3 <= 1;
									
								when 1=>
									--for i in 3 to 67 loop 
									if l < 67 then 
										subkeys(l) <= (c xor (z and one) xor subkeys(l-3) xor ROR_64(subkeys(l-1),3) 
										xor ROR_64(subkeys(l-1),4) );
										z<= shift_right(z,1);
										l <= l+1;
									--end loop;
									else  -- for loop is completed 
										seq3 <= 2;
									end if;
								when 2=>
									subkeys(67) <=	(c xor subkeys(64) xor ROR_64(subkeys(66), 3) xor ROR_64(subkeys(66), 4) );
									seq3 <= 3;
								when 3=>
									subkeys(68) <= (c xor one xor subkeys(65) xor ROR_64(subkeys(67),3) xor ROR_64(subkeys(67),4) );
									continue <= '1';-- now start decrypting 
									
								when others=> null; -- stop 
							end case;
							
						end if;-- close if statement for key_length 
				
					end if; -- close if statement for key_valid 
					
				end if;-- close if statement for reset_n
			
			end if;-- close if statement for rising_edge(clk)
	
end process init;
	
	
data_in : process(clk,i,reset_n,data_valid) is --  process to take in data and store in an array  
			--variable data1 : unsigned(31 downto 0);
			--variable data2 : unsigned(31 downto 0);
		begin 
		
			if (rising_edge(clk)) then
			
				if (reset_n = '1' and data_valid = '1') then 

					data_input(0) <= data32_2 & data32_1;
					data_input(1) <= data32_4 & data32_3;
					data_check <= '1';
								
				elsif (reset_n = '0') then 
				
					data_check <= '0'; -- reset this data_check to stop decryption 
					data_input(0) <= (others=> '0');
					data_input(1) <= (others=> '0');
					i <= 0; -- reset 
					
				end if; -- close if statement for reset_n
				
			end if;-- close if statement for risinge_edge of clock 
			
end process data_in;


decryption_begin: process(clk,data_valid,encryption,data_check) is -- begin decrypting 
					variable j : integer := 67; -- for loop starts at 67 for both 128-bit and 192-bit key length 
					--variable x : unsigned(63 downto 0);
					--variable y : unsigned(63 downto 0);
					variable t : unsigned(63 downto 0);
				begin
				
				if rising_edge(clk) then 
					
					if reset_n = '0' then
					-- enter code for reset_n
					x <= (others=> '0');
					y <= (others=> '0');
					t := (others=> '0');
					j := 67; -- start at 67 
					
					seq0 <= 0;
					seq1 <= '0';
					data_ready <= '0';
					
					elsif reset_n = '1' then 
					
						if (data_valid = '0' and encryption = '0' and 
						data_check = '1' and continue = '1') then
							
							if key_length = "00" then  -- 128-bit
							
								if (j >= 0) then  -- for loop implementation "for (int j=67;j >= 0;j -= 2)"
								
									case seq0 is 
										when 0=>
											y <= data_input(0) xor f(data_input(1));
											seq0 <= 1;
										when 1=>
											y <= y xor subkeys(j);
											seq0 <= 2;
										when 2=>
											x <= data_input(1) xor f(y);
											seq0 <= 3;
										when 3=>
											x <= x xor subkeys(j-1);
											seq0 <= 4;
											j := j-2; -- decrement by 2
										when 4=>
											y <= y xor f(x) ; -- call f function
											seq0 <= 5;-- increment 
										when 5 =>
											y <= y xor subkeys(j);
											seq0 <= 6;-- increment 
										when 6 =>
											x <= x xor f(y); -- call f function
											seq0 <= 7;-- increment 
										when 7 =>
											x <= x xor subkeys(j-1); 
											j := j-2; -- decrement by 2 
											seq0 <= 4;-- increment but ONLY go back to case 4	
										when others=> null; -- do nothing 
									end case;
									
								else-- for loop from i=nrSubkeys-1  0 has finished 
									
									if seq1 = '1' then 
										case seq0 is  
											when 0=>  -- now transfer the remaining data        
												data_word_out <= std_logic_vector(x(63 downto 32));
												seq0 <= 1;   
											when 1=>         
												data_word_out <= std_logic_vector(y(31 downto 0));
												seq0 <= 2;   
											when 2=>         
												data_word_out <= std_logic_vector(y(63 downto 32));
												data_ready<= '0';-- now stop and make data_ready <= '0'
											when others=>
												null;
										end case;
										
									elsif seq1 = '0' then -- for the first run make 
									
										seq1 <= '1';
										data_ready <= '1';
										seq0 <= 0;
										
										data_word_out <= std_logic_vector(x(31 downto 0));-- transfer the first 32-bit of data 
										
									end if; -- close if statement for control flag 
								
								end if;-- close if statement for j, for loop implementation 
							
							elsif key_length = "01" then -- if key is 192-bit  
								
								if (j >= 0) then -- for loop implementation 
								
									case seq0 is  
										when 0=>--------------------------RUNS ONLY ONCE-{-
											t := data_input(1); -- t = y
											seq0 <= 1;
										when 1=>
											y <= data_input(0); -- y = x
											seq0 <= 2;
										when 2=>
											x <= t;
											seq0 <= 3;
										when 3=>
											y <= y xor subkeys(68);
											seq0 <= 4;
										when 4=>
											y <= y xor f(x);
											seq0 <= 5;
										--------------------------------------------------}-
										when 5=>------------------------START OF FOR LOOP-{-
											x <= x xor f(y);
											seq0 <=6;
										when 6=>
											x <= x xor subkeys(j);
											seq0 <= 7;
										when 7=>
											y <= y xor f(x);
											seq0 <= 8;
										when 8=>
											y <= y xor subkeys(j-1);
											j := j-2; -- decrement variable for "for loop"
											seq0 <= 5; -- GO BACK ONLY TO CASE 5----------}-
										
										when others=> null; -- do nothing
										
									end case;
								else -- now the for loop has ended 
								
										if seq1 = '1' then
										
											case seq0 is 
												when 0=>  -- output the remaining data to data_word_out        
													data_word_out <= std_logic_vector(x(63 downto 32));
													seq0 <= 1;   
												when 1=>         
													data_word_out <= std_logic_vector(y(31 downto 0));
													seq0 <= 2;   
												when 2=>         
													data_word_out <= std_logic_vector(y(63 downto 32));
												--	data_ready <= '0'; -- now stop, data_read <= '0'
												when others=>
													null;
											end case;
										
										elsif seq1 = '0' then -- once the for loop is finished, output the data 
										
											seq1 <= '1';
											data_ready <= '1';-- data_ready is now 1
											seq0 <= 0;-- reset this signal back to 0 
											data_word_out <= std_logic_vector(x(31 downto 0));-- output the first 32-bit 
											
										end if;-- close if statement for control_flag2
										
								end if; -- close if statement for "for loop" j >= 0
								
							end if;-- close if statement for key length 
						
						end if; -- close if statement for data_valid, encryption, data_check 
								-- and continue signals 
						
					end if; -- close if statement for reset_n 
					
				end if;-- close if statement for rising edge of clock 
				
end process decryption_begin;

end architecture;
