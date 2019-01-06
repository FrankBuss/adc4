-- RS232 protocol:
-- 's' start measurement. Argument: uint32 number of samples
-- 't' start RAM test. Arguments: uint32 number of samples
-- '.' is sent back when measurement or RAM test is done
-- 'r' starts read back the measurement, as binary data. Arguments:
--     uint32 start address
--     uint32 number of samples
--     returns one additional byte for CRC8 checksum

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity adc is
	generic (
		ADDR_W : integer := 26;
		DATA_W : integer := 128);
	port (
		iCLK : in std_logic;
		iRST_n : in std_logic;
		rxd : in std_logic;
		txd : out std_logic;

		ram_start_sequence : out std_logic;
		ram_read_sequence : out std_logic;
		ram_start_ready : in std_logic;
		ram_start_address : out STD_LOGIC_VECTOR(ADDR_W - 1 downto 0);
		ram_readdata : in STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		ram_writedata : out STD_LOGIC_VECTOR(DATA_W - 1 downto 0);
		ram_next_data : out std_logic;

		gpio0 : inout STD_LOGIC_VECTOR(35 downto 0);
		gpio1 : inout STD_LOGIC_VECTOR(35 downto 0);
		test : out std_logic
	);
end adc;

architecture Behavior of adc is
	subtype byte is unsigned(7 downto 0);

	constant system_speed : natural := 50e6;
	constant baudrate : natural := 1000000;

	signal rs232_receiver_dat : byte;
	signal rs232_receiver_stb : std_logic;

	signal rs232_sender_dat : byte;
	signal rs232_sender_stb : std_logic;
	signal rs232_sender_busy : std_logic;

	type state_type is (
		wait_for_byte,
		read_samplerate_divider,
		read_address,
		read_sample_count,
		start_measurement,
		measure,
		start_read,
		read_data,
		send_checksum,
		dbuffer);

	signal state : state_type;
	signal command : state_type;

	function char_to_byte(c : character)
		return byte is
	begin
		return to_unsigned(character'pos(c), 8);
	end;

	signal counter : natural range 0 to 16;

	signal samplecounter : unsigned(ADDR_W - 1 downto 0);
	signal buffer_data : unsigned(DATA_W - 1 downto 0);

	signal adc_clock : std_logic;
	signal old_clock : std_logic;
	signal adc_in0 : std_logic_vector(31 downto 0);
	signal adc_in1 : std_logic_vector(31 downto 0);

	signal read_delay : std_logic;

	signal testcounter : unsigned(31 downto 0);

	signal max_sample_count : unsigned(31 downto 0);

	signal i_ram_writedata : STD_LOGIC_VECTOR(DATA_W - 1 downto 0);

	signal samplerate_divider : byte;
	signal samplerate_divider_counter : byte;
	
	signal address : unsigned(31 downto 0);

	signal crc8_init : std_logic;
	signal crc8_update : std_logic;
	signal crc8_data : byte;
	signal crc8_checksum : byte;

begin

	sender : entity rs232_sender
		generic map(system_speed, baudrate)
		port map(
			clk_i => iCLK,
			dat_i => rs232_sender_dat,
			rst_i => not iRST_n,
			stb_i => rs232_sender_stb,
			tx => txd,
			busy => rs232_sender_busy);

	receiver : entity rs232_receiver
		generic map(system_speed, baudrate)
		port map(
			clk_i => iCLK,
			dat_o => rs232_receiver_dat,
			rst_i => not iRST_n,
			stb_o => rs232_receiver_stb,
			rx => rxd);

	crc8_inst : entity crc8
		port map(
			iCLK => iCLK,
			init => crc8_init,
			update => crc8_update,
			data => crc8_data,
			checksum => crc8_checksum);

	process (iCLK)
	begin
		if rising_edge(iCLK) then
			if iRST_n = '0' or (rs232_receiver_stb = '1' and (state = read_data or state = dbuffer)) then
				-- the reset signal, and any incoming transfer, resets the state machine
				state <= wait_for_byte;
				ram_start_sequence <= '0';
				samplerate_divider <= (others => '0');
			else
				rs232_sender_stb <= '0';
				ram_next_data <= '0';
				crc8_update <= '0';
				crc8_init <= '0';

				if samplerate_divider_counter > 0 then
					samplerate_divider_counter <= samplerate_divider_counter - 1;
				else
					if adc_clock = '0' then
						adc_clock <= '1';
					else
						adc_clock <= '0';
					end if;
					samplerate_divider_counter <= samplerate_divider;
				end if;
				old_clock <= adc_clock;
				
				if read_delay = '0' then
					read_delay <= '1';
				else
					read_delay <= '0';
				end if;

				case state is
					when wait_for_byte =>
						if rs232_receiver_stb = '1' then
							samplecounter <= to_unsigned(1, ADDR_W);
							ram_start_address <= (others => '0');
							counter <= 4;
							case rs232_receiver_dat is
								when char_to_byte('s') =>
									ram_read_sequence <= '0';
									testcounter <= (others => '0');
									ram_start_sequence <= '1';
									command <= start_measurement;
									state <= read_sample_count;
								when char_to_byte('t') =>
									ram_read_sequence <= '0';
									testcounter <= x"00000042";
									ram_start_sequence <= '1';
									command <= start_measurement;
									state <= read_sample_count;
								when char_to_byte('r') =>
									crc8_init <= '1';
									command <= start_read;
									state <= read_address;
								when char_to_byte('d') =>
									state <= read_samplerate_divider;
								when others =>
									ram_start_sequence <= '0';
							end case;
						end if;
					when read_samplerate_divider =>
						if rs232_receiver_stb = '1' then
							samplerate_divider <= rs232_receiver_dat;
							state <= wait_for_byte;
						end if;
					when read_address =>
						if counter = 0 then
							counter <= 4;
							ram_read_sequence <= '1';
							ram_start_sequence <= '1';
							ram_start_address <= std_logic_vector(address(ADDR_W - 1 downto 0));
							state <= read_sample_count;
						else
							if rs232_receiver_stb = '1' then
								address <= address(23 downto 0) & rs232_receiver_dat;
								counter <= counter - 1;
							end if;
						end if;
					when read_sample_count =>
						if counter = 0 then
							state <= command;
						else
							if rs232_receiver_stb = '1' then
								max_sample_count <= max_sample_count(23 downto 0) & rs232_receiver_dat;
								counter <= counter - 1;
							end if;
						end if;
					when start_measurement =>
						if ram_start_ready = '1' then
							state <= measure;
						end if;
					when measure =>
						if samplecounter = max_sample_count(ADDR_W - 1 downto 0) then
							rs232_sender_dat <= char_to_byte('.');
							rs232_sender_stb <= '1';
							ram_start_sequence <= '0';
							state <= wait_for_byte;
						else
							if adc_clock = '1' and old_clock = '0' then
								if testcounter = x"00000000" then
									ram_writedata <= i_ram_writedata;
									i_ram_writedata <= std_logic_vector(to_unsigned(0, 64)) & adc_in1 & adc_in0;
								else
									ram_writedata <= std_logic_vector(to_unsigned(0, 96)) & std_logic_vector(testcounter);
									testcounter <= testcounter + 1;
								end if;
								ram_next_data <= '1';
								samplecounter <= samplecounter + 1;
							end if;
						end if;
					when start_read =>
						if read_delay = '1' then
							if ram_start_ready = '1' then
								ram_next_data <= '1';
								counter <= 4;
								state <= read_data;
							end if;
						end if;
					when read_data =>
						if read_delay = '1' then
							if counter > 0 then
								if rs232_sender_busy = '0' then
									rs232_sender_dat <= buffer_data(7 downto 0);
									crc8_data <= buffer_data(7 downto 0);
									crc8_update <= '1';
									buffer_data <= x"00" & buffer_data(127 downto 8);
									rs232_sender_stb <= '1';
									counter <= counter - 1;
								end if;
							else
								if samplecounter = max_sample_count(ADDR_W - 1 downto 0) then
									ram_start_sequence <= '0';
									state <= send_checksum;
								else
									ram_next_data <= '1';
									counter <= 4;
									samplecounter <= samplecounter + 1;
									state <= dbuffer;
								end if;
							end if;
						end if;
					when send_checksum =>
						if read_delay = '1' then
							if rs232_sender_busy = '0' then
								rs232_sender_dat <= crc8_checksum;
								rs232_sender_stb <= '1';
								state <= wait_for_byte;
							end if;
						end if;
					when dbuffer =>
						if read_delay = '1' then
							buffer_data <= unsigned(ram_readdata);
							state <= read_data;
						end if;
				end case;
			end if;
		end if;
	end process;

	-- ADC 1 to 4
	gpio0(34) <= adc_clock;
	gpio0(27) <= adc_clock;
	gpio0(9) <= adc_clock;
	gpio0(16) <= adc_clock;
	adc_in0 <= gpio0(17) & gpio0(14) & gpio0(15) & gpio0(12) & gpio0(13) & gpio0(10) & gpio0(11) & gpio0(8)
		& gpio0(6) & gpio0(7) & gpio0(4) & gpio0(5) & gpio0(2) & gpio0(3) & gpio0(0) & gpio0(1)
		& gpio0(24) & gpio0(25) & gpio0(22) & gpio0(23) & gpio0(20) & gpio0(21) & gpio0(18) & gpio0(19)
		& gpio0(35) & gpio0(32) & gpio0(33) & gpio0(30) & gpio0(31) & gpio0(28) & gpio0(29) & gpio0(26);

	-- ADC 5 to 8
	gpio1(34) <= adc_clock;
	gpio1(27) <= adc_clock;
	gpio1(9) <= adc_clock;
	gpio1(16) <= adc_clock;
	adc_in1 <= gpio1(17) & gpio1(14) & gpio1(15) & gpio1(12) & gpio1(13) & gpio1(10) & gpio1(11) & gpio1(8)
		& gpio1(6) & gpio1(7) & gpio1(4) & gpio1(5) & gpio1(2) & gpio1(3) & gpio1(0) & gpio1(1)
		& gpio1(24) & gpio1(25) & gpio1(22) & gpio1(23) & gpio1(20) & gpio1(21) & gpio1(18) & gpio1(19)
		& gpio1(35) & gpio1(32) & gpio1(33) & gpio1(30) & gpio1(31) & gpio1(28) & gpio1(29) & gpio1(26);

	test <= adc_clock;

end Behavior;
