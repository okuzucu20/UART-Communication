----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:27:06 01/04/2022 
-- Design Name: 
-- Module Name:    UART_Rx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_Receiver is
	 GENERIC(
	   clks_per_bit  : INTEGER := 10_416; -- Clock frequency (100_000_000) over baud rate (9_600)
		data_length   : INTEGER := 5);
    PORT( 
		rx_serial	  : IN  STD_LOGIC;
      clk 			  : IN  STD_LOGIC;
      msg 			  : OUT STD_LOGIC_VECTOR(data_length-1 downto 0);
		rx_processed  : OUT STD_lOGIC);
end UART_Receiver;

architecture Behavioral of UART_Receiver is

	type receive_mode_types is (idle, start_bit, data_bit, stop_bit, reset);
	
	signal receive_mode   : receive_mode_types := idle;

	signal data_index      : INTEGER range 0 to (data_length - 1) := 0;
	signal clk_counter     : INTEGER range 0 to (clks_per_bit - 1) := 0;
	
	signal gathered_msg    : STD_LOGIC_VECTOR(data_length-1 downto 0);

begin

	serial_process: process(clk)
	BEGIN
		
		IF RISING_EDGE(clk) THEN
		
			CASE receive_mode IS 
				
				-- Idle Mode (indefinite)
				WHEN idle =>
				
					rx_processed <= '0';
					data_index   <= 0;
					clk_counter  <= 0;
				
					IF rx_serial = '0' THEN
						receive_mode <= start_bit;
					END IF;

				-- Check the correctness of start bit (1)
				WHEN start_bit =>
				
					IF (clk_counter = (clks_per_bit/2)) THEN
						
						IF (rx_serial = '1') THEN
							receive_mode <= idle;
						END IF;
						clk_counter <= clk_counter + 1;
						
					ELSIF (clk_counter = (clks_per_bit-1)) THEN
						receive_mode <= data_bit;
						data_index <= 0;
						clk_counter <= 0;
					ELSE
						clk_counter <= clk_counter + 1;
					END IF;
				
				-- Data Frame (data_length)
				WHEN data_bit =>
				
					IF (data_index = data_length) THEN
						data_index <= 0;
						clk_counter <= 0;
						receive_mode <= stop_bit;
					ELSE
						IF (clk_counter = (clks_per_bit/2)) THEN
							gathered_msg(data_index) <= rx_serial;
							clk_counter <= clk_counter + 1;
						ELSIF (clk_counter = clks_per_bit-1) THEN
							clk_counter <= 0;
							data_index <= data_index + 1;
						ELSE
							clk_counter <= clk_counter + 1;
						END IF;
					END IF;
					
				-- Stop Bit (1)
				WHEN stop_bit =>
				
					IF (clk_counter = clks_per_bit - 1) THEN
						receive_mode <= reset;
						rx_processed <= '1';
						clk_counter <= 0;
					ELSE
						clk_counter <= clk_counter + 1;
					END IF;
					
				-- Reset after reading stop bit (1 clock cycle)
				WHEN reset =>
					receive_mode <= idle;
					rx_processed <= '0';
				
			END CASE;
			
		END IF;
		
	END PROCESS;
	
	msg <= gathered_msg;

end Behavioral;

