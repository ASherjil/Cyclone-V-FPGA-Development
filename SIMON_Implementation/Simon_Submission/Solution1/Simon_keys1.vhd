library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_C_PACKET.all; 

entity SIMON_keys1 is -- all these signals are required to validate the testbench provided 
port
(	
	clk              : in  std_logic;
    reset_n          : in  std_logic;
	key_valid		 : in  std_logic;
	key_length 		 : in  std_logic_vector(1 downto 0);
	key_start		 : in  std_logic;
	key_64bit        : in  t_key_64bit;
	subkeys			 : out t_subkeys -- output the subkeys 
);

end entity; 

architecture rtl of SIMON_keys1  is
begin 


  -- purpose: To generate subkeys 
  -- type   : sequential with sychronous reset 
  -- inputs : clk, reset, key_valid, key_start 
  -- outputs: subkeys 
init: process(all) is -- initialisation process for simon algorithm 
		variable z : unsigned(63 downto 0);-- variable to store value for z 
		variable subkeys_vars : t_subkeys; -- use variable to update instantly in sequential process 
		variable seq0 : integer := 0;-- variable to control state 
	begin 
	
			if rising_edge(clk) then -- begin on the rising edge of the clock 
			
				if reset_n = '0' then -- reset 
				
				subkeys <= (others=> (others=>'0')); -- subkeys is now reset
				seq0 := 0; -- reset back to state 1 
					
				elsif reset_n = '1' then -- only begin if reset is 1  
					
					if ((key_valid = '0') and (key_start = '1')) then -- is key_valid = 0 then begin initialisation 
					
						if key_length = "00" then  -- key length is 128-bit

							case seq0 is
									when 0=>
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
								when others => -- do nothing 
									seq0 := 0;
								end case; 
									
						end if;-- close if statement for key_length 
				
					end if; -- close if statement for key_valid 
					
				end if;-- close if statement for reset_n
			
			end if;-- close if statement for rising_edge(clk)
	
end process init;


end architecture;

