-- HPS Component for interfacing with Cortex A9
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_PACKET.all;

entity Simon_192_HPS is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in std_logic;
	reset 			 : in std_logic;
	avs_s0_address   : in  std_logic_vector(3 downto 0); -- 20 registors being used 
	avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
	x   			 : in  unsigned(63 downto 0);
	y   			 : in  unsigned(63 downto 0);
	
	key_64bit        : out t_key_64bit;
	data_input       : out t_data_in;
    avs_s0_readdata  : out std_logic_vector(31 downto 0)
);
end entity; 

architecture rtl of Simon_192_HPS is

signal reset_n : std_logic;
-----------------------------------KEY AND DATA AS 32-BIT 
signal key32_1 : unsigned (31 downto 0);
signal key32_2 : unsigned (31 downto 0);
signal key32_3 : unsigned (31 downto 0);
signal key32_4 : unsigned (31 downto 0);
signal key32_5 : unsigned (31 downto 0);
signal key32_6 : unsigned (31 downto 0);
signal data32_1: unsigned(31 downto 0);
signal data32_2: unsigned(31 downto 0);
signal data32_3: unsigned(31 downto 0);
signal data32_4: unsigned(31 downto 0);

begin
	
-- process(all) was implemented to ensure no signals are missed(VHDL 2008 only works in Questasim)
-- and NOT Quartus Prime Lite 21.1

--------------------------------------------------AVALON BUS READ AND WRITE PROCESS---------------
  -- purpose: Respond to write operations from the Avalon bus
  -- type   : sequential with asychronous reset 
  -- inputs : clk, reset, avs_s0_write, avs_s0_address
  -- outputs: none 
write_proc : process (clk, reset) is
begin  -- process write_proc
  if reset = '1'  then                 -- reset active high 
	reset_n <= '0';-- reset  
	
  elsif rising_edge(clk) then  -- rising clock edge
    if avs_s0_write = '1' then
      case avs_s0_address is
		
		when b"0000" => reset_n <= avs_s0_writedata(0);----registor #0
		
		when b"0001" => key32_1  <= unsigned(avs_s0_writedata);-----registor #1
		when b"0010" => key32_2  <= unsigned(avs_s0_writedata);-----registor #2
		when b"0011" => key32_3  <= unsigned(avs_s0_writedata);-----registor #3
		when b"0100" => key32_4  <= unsigned(avs_s0_writedata);-----registor #4
		when b"0101" => key32_5  <= unsigned(avs_s0_writedata);-----registor #5
		when b"0110" => key32_6  <= unsigned(avs_s0_writedata);-----registor #6
		
		when b"0111" => data32_1 <= unsigned(avs_s0_writedata);-----registor #7
		when b"1000" => data32_2 <= unsigned(avs_s0_writedata);-----registor #8
		when b"1001" => data32_3 <= unsigned(avs_s0_writedata);-----registor #9
		when b"1010" => data32_4 <= unsigned(avs_s0_writedata);-----registor #10
		
        when others => reset_n <= '1'; -- do nothing   
      end case;
    end if;
  end if;
end process write_proc;
  
  
-- purpose: Respond to read operation from Avalon bus
-- type   : combinational
-- inputs : avs_s0_read, avs_s0_address
-- outputs: avs_s0_readdata
read_proc : process (avs_s0_read,avs_s0_address,x,y) is
begin  -- process read_proc
  if avs_s0_read = '1' then
    case avs_s0_address is
      when b"1011"  => avs_s0_readdata <= std_logic_vector(x(31 downto 0));-- registor# 11
	  when b"1100"  => avs_s0_readdata <= std_logic_vector(x(63 downto 32)); -- registor# 12
	  when b"1101"  => avs_s0_readdata <= std_logic_vector(y(31 downto 0)); -- registor# 13
	  when b"1110"  => avs_s0_readdata <= std_logic_vector(y(63 downto 32)); -- registor# 14	  
      when others   => avs_s0_readdata <= (others=> 'Z'); -- do nothing 
    end case;
  else
	 avs_s0_readdata <= (others=> 'Z');
  end if;
end process read_proc; 

--------------------------------------------------------------------------PERFORM CONCATENATIONS-----
-- purpose: store encrypted data 64-bit array 
-- type   : combinational with else statement to prevent latch 
-- inputs : reset_n,data32_1...4 
-- outputs: data_input signal array 
data_in : process(reset_n,data32_1,
		data32_2,data32_3,data32_4) is --  process to take in data and store in an array  
		begin 
								
				if (reset_n = '0') then 
				
					data_input(0) <= (others=> '0');
					data_input(1) <= (others=> '0');
				else -- elseif  (reset_n = '1') then 
					data_input(0) <= data32_2 & data32_1;
					data_input(1) <= data32_4 & data32_3;
					
				end if; -- close if statement for reset_n
						
end process data_in;

-- purpose: store 32-bit keys as an array of 64-bit key
-- type   : Combinational with else statement for latch prevention
-- inputs : clock and key_valid signal 
-- outputs: key_64bit and key_start
key_in:	process(reset_n, key32_1,key32_2,key32_3,
		key32_4,key32_5,key32_6) is --  process to take in key and store in an array  
		begin
	
			if reset_n = '0' then 
				
				key_64bit(0) <= (others=> '0');
				key_64bit(1) <= (others=> '0');
				key_64bit(2) <= (others=> '0');
			else 		
				key_64bit(0) <= key32_2 & key32_1;
				key_64bit(1) <= key32_4 & key32_3;
				key_64bit(2) <= key32_6 & key32_5;
			
			end if; -- close if statement for reset_n 
		
end process key_in;

------------------------------------------------------------------------------------END 

end architecture;

