-- HPS Component for interfacing with Cortex A9, balanced solution 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SIMON_CH_PACKET.all;

entity Simon_CH_HPS is -- all these signals are required to validate the testbench provided 
port
(	
	clk 			 : in  std_logic;
	reset 			 : in  std_logic;
	avs_s0_address   : in  std_logic_vector(4 downto 0); 
	avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
	x   			 : in  unsigned(63 downto 0);-- final decrypted data from the decryption module
	y   			 : in  unsigned(63 downto 0);-- final decrypted data from the decryption module
    data_ready       : in  std_logic; -- signal received from the decryption module 
	
	reset_n			 : out  std_logic ;-- signal system to allow the user to reset 
	data_valid       : out std_logic  ;-- signal concatenate the 32-bit data
	encryption		 : out std_logic  ;-- signal to specify to start encryption
	key_length   	 : out std_logic_vector(1 downto 0);
	key_valid        : out std_logic  ;-- signal to concatenate the 32-bit keys 
	key32_1 		 : out unsigned (31 downto 0);
	key32_2 		 : out unsigned (31 downto 0);
	key32_3 		 : out unsigned (31 downto 0);
	key32_4 		 : out unsigned (31 downto 0);
	key32_5 		 : out unsigned (31 downto 0);
	key32_6 		 : out unsigned (31 downto 0);
	data32_1		 : out unsigned (31 downto 0);
	data32_2		 : out unsigned (31 downto 0);
	data32_3		 : out unsigned (31 downto 0);
	data32_4		 : out unsigned (31 downto 0);
	avs_s0_readdata  : out std_logic_vector(31 downto 0)
	
);
end entity; 

architecture rtl of Simon_CH_HPS is


begin
	
-- process(all) was implemented to ensure no signals are missed(VHDL 2008 only works in Questasim)
-- and NOT Quartus Prime Lite 21.1
--------------------------------------------------AVALON BUS READ AND WRITE PROCESS---------------
  -- purpose: Respond to write operations from the Avalon bus
  -- type   : sequential with asychronous reset 
  -- inputs : clk, reset, avs_s0_write, avs_s0_address
  -- outputs: all the ones specfied in the port  
write_proc : process (clk, reset) is
begin  -- process write_proc
  if reset = '1'  then               
	reset_n <= '0';-- reset  
	
  elsif rising_edge(clk) then  -- rising clock edge
    if avs_s0_write = '1' then
      case avs_s0_address is
		when b"00000" => key_length <= avs_s0_writedata(1 downto 0); --registor #0
		when b"00001" => key_valid  <= avs_s0_writedata(0);----registor #1
		when b"00010" => data_valid <= avs_s0_writedata(0);----registor #2
		when b"00011" => encryption <= avs_s0_writedata(0);----registor #3
		when b"01011" => reset_n    <= avs_s0_writedata(0);----registor #11
		when b"00101" => key32_1    <= unsigned(avs_s0_writedata);-----registor #5
		when b"01100" => key32_2    <= unsigned(avs_s0_writedata);-----registor #12
		when b"01101" => key32_3    <= unsigned(avs_s0_writedata);-----registor #13
		when b"01110" => key32_4    <= unsigned(avs_s0_writedata);-----registor #14
		when b"01111" => key32_5    <= unsigned(avs_s0_writedata);-----registor #15
		when b"10000" => key32_6    <= unsigned(avs_s0_writedata);-----registor #16
		when b"00100" => data32_1   <= unsigned(avs_s0_writedata);-----registor #4
		when b"10001" => data32_2   <= unsigned(avs_s0_writedata);-----registor #17
		when b"10010" => data32_3   <= unsigned(avs_s0_writedata);-----registor #18
		when b"10011" => data32_4   <= unsigned(avs_s0_writedata);-----registor #19
        when others   => reset_n 	<= '1'; -- do nothing   
      end case;
    end if;
  end if;
end process write_proc;
  
  
-- purpose: Respond to read operation from Avalon bus
-- type   : combinational
-- inputs : avs_s0_read, avs_s0_address
-- outputs: all the ones specfied in the port  
read_proc : process (avs_s0_read,avs_s0_address,x,y) is
begin  -- process read_proc
  if avs_s0_read = '1' then
    case avs_s0_address is
      when b"00110" => avs_s0_readdata <= (B"0000000000000000000000000000000" & data_ready); -- registor# 6
      when b"00111" => avs_s0_readdata <= std_logic_vector(x(31 downto 0));-- registor# 7
	  when b"01000" => avs_s0_readdata <= std_logic_vector(x(63 downto 32)); -- registor# 8
	  when b"01001" => avs_s0_readdata <= std_logic_vector(y(31 downto 0)); -- registor# 9
	  when b"01010" => avs_s0_readdata <= std_logic_vector(y(63 downto 32)); -- registor# 10	    
      when others   => avs_s0_readdata <= (others=> 'Z'); -- do nothing 
    end case;
  else
	 avs_s0_readdata <= (others=> 'Z');
  end if;
end process read_proc; 

end architecture;