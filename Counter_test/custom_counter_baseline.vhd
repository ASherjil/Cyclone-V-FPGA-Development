library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity custom_counter is

  port 
  (
    clk              : in  std_logic;
    reset            : in  std_logic;
    avs_s0_address   : in  std_logic_vector(2 downto 0);
    avs_s0_read      : in  std_logic;
    avs_s0_write     : in  std_logic;
    avs_s0_writedata : in  std_logic_vector(31 downto 0);
    avs_s0_readdata  : out std_logic_vector(31 downto 0)
  );

end entity custom_counter;

architecture rtl of custom_counter is

  signal r_CountControl : std_logic_vector(31 downto 0);
  signal r_CountFlags   : std_logic_vector(31 downto 0);
  signal r_CountVal     : unsigned(31 downto 0);
  signal r_CountReload  : unsigned(31 downto 0);

  signal r_CountRun      : std_logic; -- if this is set to 1, the counter should run
  signal r_CountReset    : std_logic;-- if this is set to 1, the counter should load the value in reload registor 
  signal r_CountRunning  : std_logic;-- when the counter is running, it is set to 1
  signal r_CountFinished : std_logic;-- when the counter has stopped, it is set to 1
 	 
  type t_State is (s0,s1);
  signal curr_state: t_State;

begin  -- architecture rtl

  -- purpose: Respond to read operation from Avalon bus
  -- type   : combinational
  -- inputs : avs_s0_read, avs_s0_address
  -- outputs: avs_s0_readdata
  read_proc : process (avs_s0_read, avs_s0_address,r_CountControl,r_CountFlags,r_CountVal,r_CountReload) is
  begin  -- process read_proc
    if avs_s0_read = '1' then
      case avs_s0_address is
        when b"000" => avs_s0_readdata <= r_CountControl;
        when b"001" => avs_s0_readdata <= r_CountFlags;
        when b"010" => avs_s0_readdata <= std_logic_vector(r_CountVal);
        when b"011" => avs_s0_readdata <= std_logic_vector(r_CountReload);
        when others => avs_s0_readdata <= (others => 'Z');
      end case;
	else
		avs_s0_readdata <= (others => 'Z');
    end if;
  end process read_proc;

  -- purpose: Respond to write operations from the Avalon bus
  -- type   : sequential
  -- inputs : clk, reset, avs_s0_write, avs_s0_address
  -- outputs: 
  write_proc : process (clk, reset) is
  begin  -- process write_proc
    if reset = '1' then                 -- asynchronous reset (active low)
      r_CountRun    <= '0';
      r_CountReset  <= '0';
      r_CountReload <= (others => '1');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if avs_s0_write = '1' then
        case avs_s0_address is
          when b"000" => (r_CountReset, r_CountRun) <= avs_s0_writedata(1 downto 0);
          when b"011" => r_CountReload              <= unsigned(avs_s0_writedata);
          when others => null;
        end case;
      end if;
    end if;
  end process write_proc;

  r_CountControl <= X"0000000" & b"00" & r_CountReset & r_CountRun;
  r_CountFlags   <= X"0000000" & b"00" & r_CountFinished & r_CountRunning;

FSM : process(clk,r_CountReset,r_CountVal,r_CountRun) is 
begin
	
	if rising_edge(clk) then
	
		if r_CountReset = '1' then 
		
			curr_state <= s0;
			
		elsif r_CountReset = '0' then
			
			--curr_state <= next_state;
			case curr_state is 
	
				when s0=>-- reseting state 
					r_CountVal <= r_CountReload; -- assign reset value 
					r_CountRunning <= '0';-- set to counter not running 
					
					if r_CountRun = '1' then 
						curr_state <= s1;
					end if;
					
				when s1=>-- counter running state 
					
					if r_CountVal = "00000000000000000000000000000000" then  -- the counter has ended  
						r_CountFinished <= '1';
						r_CountRunning <= '0';-- set to counter not running 
					
					elsif r_CountRun = '0' then -- the counter stopped prematurely 
						r_CountRunning <= '0';-- set to counter not running 
						
					else-- run counter 
						r_CountVal <= r_CountVal - 1; -- decrement counter 
						r_CountRunning <= '1'; 
						r_CountFinished <= '0';
					end if;--  close if statement for r_CountVal
					-- only go back to state s0 if reset 
				when others=> 
					curr_state <= s0; -- just go back to state s0  
			
			end case;--close case statement for curr_state 	
			
		end if;-- close if statement for r_CountReset
		
	end if; -- close if statement for rising edge of clock
end process FSM;



end architecture rtl;
