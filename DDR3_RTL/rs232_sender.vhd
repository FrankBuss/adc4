-- Copyright (c) 2018 Frank Buss (fb@frank-buss.de)
--
-- Simple RS232 sender with generic baudrate and 8N1 mode.
--
-- Set dat_i to the byte to send and stb_i to 1 for one clock cycle.
-- On the next clock cycle, busy goes to 1 until sending is done.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs232_sender is
	generic (
		system_speed, -- clk_i speed, in hz
		baudrate : integer); -- baudrate, in bps
	port (
		clk_i : in std_logic;
		dat_i : in unsigned(7 downto 0);
		rst_i : in std_logic;
		stb_i : in std_logic;
		tx    : out std_logic;
		busy  : out std_logic);
end entity rs232_sender;

architecture rtl of rs232_sender is
	constant max_counter : natural := system_speed / baudrate;

	type state_type is (
		wait_for_strobe,
		send_start_bit,
		send_bits,
		send_stop_bit);

	signal state : state_type := wait_for_strobe;

	signal baudrate_counter : natural range 0 to max_counter;

	signal bit_counter : natural range 0 to 7;
	signal shift_register : unsigned(7 downto 0);

begin

	update : process (clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				tx <= '1';
				busy <= '0';
				state <= wait_for_strobe;
			else
				case state is
						-- wait until the master asserts valid data
					when wait_for_strobe =>
						busy <= '0';
						if stb_i = '1' then
							state <= send_start_bit;
							baudrate_counter <= max_counter - 1;
							tx <= '0';
							shift_register <= dat_i;
							busy <= '1';
						else
							tx <= '1';
						end if;

					when send_start_bit =>
						if baudrate_counter = 0 then
							state <= send_bits;
							baudrate_counter <= max_counter - 1;
							tx <= shift_register(0);
							bit_counter <= 7;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;

					when send_bits =>
						if baudrate_counter = 0 then
							if bit_counter = 0 then
								state <= send_stop_bit;
								tx <= '1';
							else
								tx <= shift_register(1);
								shift_register <= shift_right(shift_register, 1);
								bit_counter <= bit_counter - 1;
							end if;
							baudrate_counter <= max_counter - 1;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;

					when send_stop_bit =>
						if baudrate_counter = 0 then
							state <= wait_for_strobe;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;
				end case;

			end if;
		end if;
	end process;
end architecture rtl;
