library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SIMON_Init is 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	key_length : in std_logic_vector(1 downto 0):= (others => '0'); -- Set "00" to 128 bit, "01" to 192 bit, "10" to 256 bit
	key_valid : in std_logic; -- enable intialisation = '1', disable = '0'
	key_word_in : in std_logic_vector(31 downto 0):= (others => '0'); -- key for initialising the encyrption algorithm 
	data_valid,encryption : in std_logic;
	data_word_in : in std_logic_vector (31 downto 0) := (others => '0');
	--nrSubkeys : out integer -- used for the next stage: encryption
	data_word_out : out std_logic_vector (31 downto 0);
	data_ready : out std_logic := '0'
);

end entity; 

architecture rtl of SIMON_Init is
signal nrSubkeys : integer;
--------------------------------------Intermediate signals and array for initialisation 
type t_subkeys is array(0 to 71) of unsigned(63 downto 0);	
signal subkeys : t_subkeys;
signal i_sub : integer := 2; -- index for subkeys

type t_key_64bit is array(0 to 2) of unsigned(63 downto 0);
signal key_64bit : t_key_64bit; -- array of 2 length for storing 2 keys 64-bit long
signal seq1 : integer := 0; -- used to force sequential run for R2 procedure 
--signal sub_key_first : unsigned(31 downto 0);
--signal sub_key_second : unsigned(31 downto 0);


type t_data_in is array (0 to 1) of unsigned(63 downto 0);
signal data_input : t_data_in; -- data to be encrypted 
signal i : integer := 0;
signal flag1 : std_logic := '0';
--signal x : unsigned(63 downto 0);
--signal y : unsigned(63 downto 0);
--signal data1 : unsigned(31 downto 0);
--signal data2 : unsigned(31 downto 0);
----------------------------------------------------------------------------------------
type t_state is (s0,s1,s2,s3);
--signal state : t_state;
--------------------------------------------------------FUNCITON and PROCEDURES

function ROR_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate Right circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_right(x,n) OR shift_left(x,(64-n)) );
	return unsigned(shifted);
end function;

function ROL_64(x : in unsigned(63 downto 0); n : in integer)-- Rotate Right circular shift 32 bits
	return unsigned is variable shifted : unsigned(63 downto 0);
begin
	shifted := ( shift_left(x,n) OR shift_right(x,(64-n)) );
	return unsigned(shifted);
end function;

function f(x : in unsigned(63 downto 0)) -- helper function for R2 procedure 
		return unsigned is variable rolled : unsigned(63 downto 0);
begin
		rolled := ( (ROL_64(x,1) and ROL_64(x,8)) xor ROL_64(x,2) );
		return unsigned(rolled);
end function;

procedure R2 ( variable k : in unsigned(63 downto 0); variable l : in unsigned(63 downto 0);
			signal x : inout unsigned(63 downto 0); signal y : inout unsigned(63 downto 0)) is
begin 
			y <= y xor f(x); -- call f function
			y <= y xor k;
			x <= x xor f(y); -- call f function
			x <= x xor l;
end R2;			
-----------------------------------------------------------------------------
--signal i : integer:=0;
begin
	

key_in:	process(clk,key_valid) is -- process to take in key 
		variable i: integer := 0;
		variable sub_key_first : unsigned(31 downto 0) := (others=> '0');
		variable sub_key_second : unsigned(31 downto 0) := (others=> '0');
	begin
	
		
		if (rising_edge(clk) and key_valid = '1') then -- only begin if key_valid = '1'
			
				if i = 6 then -- reset i signal 
					i := 0;
				end if;
				
				case i is 
					
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
	
				i := i+1;-- increment 
		end if;-- if for rising_edge clock 
	end process key_in;
	
		
init:process(clk,reset_n) is -- initialisation process
	
		variable c : unsigned(63 downto 0):= x"fffffffffffffffc"; 
		variable z : unsigned(63 downto 0);
		--variable i : unsigned(63 downto 0);
		variable one : unsigned(63 downto 0):= B"0000000000000000000000000000000000000000000000000000000000000001";
		
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 	
				-- enter code here  
					
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
								--i_sub <= i_sub +1;
							end loop;
							
							subkeys(66) <= (c xor one xor subkeys(64) xor ROR_64(subkeys(65),3) xor ROR_64(subkeys(65),4));
							subkeys(67) <= (c xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
							
						elsif key_length = "01" then -- key length is 192-bit
							
							z:= x"fc2ce51207a635db"; -- assign value to z
							nrSubkeys <= 69; -- nrsubkeys 
							
							subkeys(0) <= key_64bit(2);
							subkeys(1) <= key_64bit(1);
							subkeys(2) <= key_64bit(0);
							
							--for i in 3 to 67 loop
							if ((i_sub+1) < 67) then
								subkeys(i_sub+1) <= (c xor (z and one) xor subkeys((i_sub+1)-2) xor ROR_64(subkeys((i_sub+1)-1),3) xor ROR_64(subkeys((i_sub+1)-1),4) );
								z:= shift_right(z,1);
							end if;
							--end loop;
							
							subkeys(67) <=	(c xor subkeys(64) xor ROR_64(subkeys(66), 3) xor ROR_64(subkeys(66), 4) );
							subkeys(68) <= (c xor one xor subkeys(65) xor ROR_64(subkeys(66),3) xor ROR_64(subkeys(66),4) );
							
						end if;
				
					end if;
					
				end if;
			
			end if;
	
	end process init;
	
	
data_in : process(clk,data_valid) is --  take in text to encrypt 
			--variable i: integer;
			variable data1 : unsigned(31 downto 0);
			variable data2 : unsigned(31 downto 0);
		begin 
		
			if (rising_edge(clk) and data_valid = '1') then
			
				if i = 4 then -- reset i signal 
					i <= 0;
				end if;
				
				case i is 
					when 0 =>data1 := unsigned(data_word_in);
					when 1 =>data2:= unsigned(data_word_in);
						data_input(0) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit	
					when 2=>data1 := unsigned(data_word_in);
					when 3=>data2 := unsigned(data_word_in);
						data_input(1) <=  unsigned(data2) & unsigned(data1); -- store data in 64bit
						flag1 <= '1';
					when others=>
						null; -- do nothing 
				end case;
				i <= i+1;-- increment 
			end if;
			
		end process data_in;
		


encryption_init: process(clk,reset_n) is 
				variable j : integer := 0; -- intermediate variable for loop implementation 
				variable x : unsigned(63 downto 0);
				variable y : unsigned(63 downto 0);
			begin	
				
				
				if rising_edge(clk) then 
									
					if reset_n = '0' then 
					-- enter code here
				
					elsif reset_n = '1' then 
						
						if (data_valid = '0' and encryption = '1' and flag1 = '1') then --data_valid == 0 means that data is transferred
								
							if key_length = "00" then -- key length is 128-bit
							
								if j < nrSubkeys then -- same as : for (i = 0; i < nrSubkeys; i += 2)
								
									if (seq1 > 3) then 
										seq1 <= 0;
									else
										seq1 <= seq1 +1;
									end if;
									
										case seq1 is --R2(subkeys(j),subkeys(j+1),data_input(0),data_input(1));
											when 0=>
												y := data_input(1) xor f(data_input(0)) ; -- call f function
											when 1 =>
												y := y xor subkeys(j);
											when 2 =>
												x := data_input(0) xor f(data_input(1)); -- call f function
											when 3 =>
												x := x xor subkeys(j+1);
												j := j+2; -- j += 2;
											
											when others=>
												null; -- do nothing 
										end case;
									
								else -- nrSubkeys  == 67
									data_ready <= '1';
								end if; -- close if statement for j < nrSubkeys 
								
							elsif key_length = "01" then -- key length is 192-bit
							
							end if; -- close if statement for key length 
							
						end if; -- close if state for data valid and encryption 
						
					end if; -- close if statement for reset_n
					
				end if; -- close if statement for rising edge clock 
			end process encryption_init;
		
end architecture;
