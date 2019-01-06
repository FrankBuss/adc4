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
		avl_address : out STD_LOGIC_VECTOR(ADDR_W - 1 downto 0);
		avl_readdatavalid : in std_logic;
		avl_readdata : in STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		avl_writedata : out STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		avl_read : out std_logic;
		avl_write : out std_logic;
		avl_burstbegin : out std_logic;
		avl_size : out STD_LOGIC_VECTOR(7 downto 0);

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

	signal i_start_sequence : std_logic;
	signal i_start_ready : std_logic;
	signal last_start_sequence : std_logic;
	signal address : unsigned(ADDR_W - 1 downto 0);
	signal reading : std_logic;
	signal wren : std_logic;
	signal i_readdata : STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
	signal i_wren : STD_LOGIC;

	signal count : unsigned(127 downto 0);
	signal max_count : unsigned(127 downto 0);

	-- DDR RAM write FIFO
	signal write_fifo_rdreq : STD_LOGIC;
	signal write_fifo_wrreq : STD_LOGIC;
	signal write_fifo_rdempty : STD_LOGIC;
	signal write_fifo_wrfull : STD_LOGIC;

	-- DDR RAM read FIFO
	signal read_fifo_aclr : STD_LOGIC;
	signal read_fifo_rdreq : STD_LOGIC;
	signal read_fifo_wrreq : STD_LOGIC;
	signal read_fifo_rdempty : STD_LOGIC;
	signal read_fifo_wrfull : STD_LOGIC;

	type state_type is (
		start,
		write_data1,
		write_data2,
		read_data1,
		read_data2);

	signal state : state_type;

begin

	write_fifo_inst : entity write_fifo port map
		(
		data => writedata,
		rdclk => ram_clock,
		rdreq => write_fifo_rdreq,
		wrclk => logic_clock,
		wrreq => write_fifo_wrreq,
		q => avl_writedata,
		rdempty => write_fifo_rdempty,
		wrfull => write_fifo_wrfull
		);

	read_fifo_inst : entity read_fifo port map
		(
		aclr => read_fifo_aclr,
		data => avl_readdata,
		rdclk => logic_clock,
		rdreq => read_fifo_rdreq,
		wrclk => ram_clock,
		wrreq => read_fifo_wrreq,
		q => readdata,
		rdempty => read_fifo_rdempty,
		wrfull => read_fifo_wrfull
		);

	process (ram_clock)
	begin
		if rising_edge(ram_clock) then
			if iRST_n = '0' then
				avl_write <= '0';
				max_count <= (others => '0');
				state <= start;
				last_start_sequence <= '0';
				read_fifo_aclr <= '0';
				i_start_ready <= '0';
				i_start_sequence <= '0';
			else
				i_start_sequence <= start_sequence;
				read_fifo_aclr <= '0';
				read_fifo_wrreq <= '0';
				write_fifo_rdreq <= '0';
				avl_write <= '0';
				case state is
					when start =>
						last_start_sequence <= i_start_sequence;
						if avl_waitrequest = '0' and i_start_sequence = '1' then
							if read_sequence = '1' then

								-- read DDR RAM until read FIFO is full
								if read_fifo_wrfull = '0' then
									avl_address <= std_logic_vector(address);
									avl_read <= '1';
									state <= read_data1;
								else
									-- start reading, when read FIFO is full
									i_start_ready <= '1';
								end if;
							else
								-- always ready to write, assuming RAM is akways faster than logic_clock with FIFO
								i_start_ready <= '1';

								-- write DDR RAM when data is available in write FIFO
								if write_fifo_rdempty = '0' then
									avl_address <= std_logic_vector(address);
									address <= address + 1;
									write_fifo_rdreq <= '1';
									state <= write_data1;
								end if;
							end if;
						end if;
						if last_start_sequence = '0' and i_start_sequence = '1' then
							reading <= read_sequence;
							--address <= unsigned(start_address);
							address <= (others => '0');
							avl_address <= (others => '0');
							read_fifo_aclr <= '1';
						end if;
					when write_data1 =>
						-- write FIFO RAM latency
						state <= write_data2;
					when write_data2 =>
						-- write the data from write FIFO q to DDR RAM writedata
						avl_write <= '1';
						state <= start;
					when read_data1 =>
						if avl_waitrequest = '0' and avl_readdatavalid = '1' then
							-- write the data from DDR RAM readdata to read FIFO data
							read_fifo_wrreq <= '1';
							address <= address + 1;
							state <= read_data2;
						end if;
					when read_data2 =>
						-- delay to latch the read_fifo_wrfull signal, if asserted
						state <= start;
				end case;

				-- reset everything at the end of a sequence
				if i_start_sequence = '0' then
					i_start_ready <= '0';
					max_count <= (others => '0');
					state <= start;
					read_fifo_aclr <= '0';
					avl_write <= '0';
					avl_read <= '0';
				end if;
			end if;
		end if;
	end process;

	process (logic_clock)
	begin
		if rising_edge(logic_clock) then
			write_fifo_wrreq <= '0';
			read_fifo_rdreq <= '0';
			if start_sequence = '1' then
				if reading = '1' then
					read_fifo_rdreq <= next_data;
				else
					write_fifo_wrreq <= next_data;
				end if;
			end if;
			start_ready <= i_start_ready;
		end if;
	end process;

	avl_size <= x"01";

end Behavior;
