library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

-- Usage: set start_sequence to high, and read_sequence to 1, if it is a read sequence,
-- or 0, if it is a write sequence, and set the start_address. Wait until start_ready gets 1.
-- Then set next_data to 1, when you write new data to the next address with writedata,
-- or when you read data (1 logic_clock cycle latency). The address will be incremented
-- each logic_clock, when next_data is 1. Set start_sequence to 0 to end the sequence.
-- First data is read when setting next_data first time to 1.

entity ram is
	generic (
		ADDR_W : integer := 26;
		DATA_W : integer := 128);
	port (
		iRST_n : in std_logic;
		ram_clock : in std_logic;
		logic_clock : in std_logic;

		avl_waitrequest : in std_logic;
		avl_address : in STD_LOGIC_VECTOR(ADDR_W - 1 downto 0);
		avl_readdatavalid : in std_logic;
		avl_readdata : in STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		avl_writedata : in STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		avl_read : out std_logic;
		avl_write : out std_logic;
		avl_burstbegin : out std_logic;
		avl_size : in STD_LOGIC_VECTOR(7 downto 0);

		start_sequence : in std_logic;
		read_sequence : in std_logic;
		start_ready : out std_logic;
		start_address : in STD_LOGIC_VECTOR(ADDR_W - 1 downto 0);
		readdata : out STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		writedata : in STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		next_data : in std_logic

		--		avl_waitrequest : in std_logic;
		--		avl_address : in STD_LOGIC_VECTOR(ADDR_W-1 downto 0);
		--		avl_readdatavalid: in std_logic;
		--		avl_readdata : in STD_LOGIC_VECTOR(DATA_W-1 downto 0);
		--		avl_writedata : in STD_LOGIC_VECTOR(DATA_W-1 downto 0);                     
		--		avl_read: out std_logic;
		--		avl_write: out std_logic;
		--		avl_burstbegin: out std_logic;
		--		avl_size: in STD_LOGIC_VECTOR(7 downto 0);                     
	);
end ram;

architecture Behavior of ram is

	signal last_start_sequence : std_logic;
	signal address : unsigned(ADDR_W - 1 downto 0);
	signal reading : std_logic;
	signal wren: std_logic;
	signal i_readdata : STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
	signal i_wren: STD_LOGIC;

begin

ramtest_inst : entity ramtest PORT MAP (
		address	 => std_logic_vector(address(14 downto 0)),
		clock	 => logic_clock,
		data	 => writedata,
		wren	 => wren,
		q	 => i_readdata
	);

	process(logic_clock)
	begin
		if rising_edge(logic_clock) then
			if iRST_n = '0' then
				i_wren <= '0';
			else
				wren <= i_wren;
				i_wren <= '0';
				if iRST_n = '0' then
					last_start_sequence <= '0';
					address <= (others => '0');
					reading <= '0';
				else
					if last_start_sequence = '0' and start_sequence = '1' then
						reading <= read_sequence;
						address <= unsigned(start_address);
					end if;
					last_start_sequence <= start_sequence;

					if start_sequence = '1' and next_data = '1' then
						readdata <= i_readdata;
						address <= address + 1;
						i_wren <= not reading;
					end if;
				end if;
			end if;
		end if;
			
	end process;

	start_ready <= '1';

end Behavior;
