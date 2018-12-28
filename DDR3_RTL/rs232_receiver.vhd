-- Copyright (c) 2018 Frank Buss (fb@frank-buss.de)
--
-- Simple RS232 receiver with generic baudrate and 8N1 mode.
-- stb_o goes high for one cycle, when a byte is received, which is in dat_o.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity rs232_receiver is
	generic (system_speed, baudrate : integer);
	port (
		clk_i : in std_logic;
		dat_o : out unsigned(7 downto 0);
		rst_i : in std_logic;
		stb_o : out std_logic;
		rx    : in std_logic);
end entity rs232_receiver;

architecture rtl of rs232_receiver is
	constant max_counter : natural := system_speed / baudrate;

	type state_type is (
		wait_for_rx_start,
		wait_half_bit,
		receive_bits,
		wait_for_stop_bit);

	signal state : state_type := wait_for_rx_start;
	signal baudrate_counter : natural range 0 to max_counter;
	signal bit_counter : natural range 0 to 7;
	signal shift_register : unsigned(7 downto 0);
	signal rx_latch : std_logic;

begin

	update : process (clk_i)
	begin
		if rising_edge(clk_i) then
			rx_latch <= rx;
			if rst_i = '1' then
				state <= wait_for_rx_start;
				dat_o <= (others => '0');
				stb_o <= '0';
			else
				stb_o <= '0';
				case state is
					when wait_for_rx_start =>
						if rx_latch = '0' then
							-- start bit received, wait for a half bit time
							-- to sample bits in the middle of the signal
							state <= wait_half_bit;
							baudrate_counter <= max_counter / 2 - 1;
						end if;
					when wait_half_bit =>
						if baudrate_counter = 0 then
							-- now we are in the middle of the start bit,
							-- wait a full bit for the middle of the first bit
							state <= receive_bits;
							bit_counter <= 7;
							baudrate_counter <= max_counter - 1;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;
					when receive_bits =>
						-- sample a bit
						if baudrate_counter = 0 then
							shift_register <= rx_latch & shift_register(7 downto 1);
							if bit_counter = 0 then
								state <= wait_for_stop_bit;
							else
								bit_counter <= bit_counter - 1;
							end if;
							baudrate_counter <= max_counter - 1;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;
					when wait_for_stop_bit =>
						-- wait for the middle of the stop bit
						if baudrate_counter = 0 then
							state <= wait_for_rx_start;
							if rx_latch = '1' then
								dat_o <= shift_register;
								stb_o <= '1';
								-- else: missing stop bit, ignore
							end if;
						else
							baudrate_counter <= baudrate_counter - 1;
						end if;
				end case;
			end if;
		end if;
	end process;

end architecture rtl;
