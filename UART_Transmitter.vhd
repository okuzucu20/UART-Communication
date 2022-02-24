----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:31:40 01/06/2022 
-- Design Name: 
-- Module Name:    MSG_2_UART - Behavioral 
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

entity UART_Transmitter is
	 GENERIC(
	   clks_per_bit  : INTEGER := 10_416; -- Clock frequency (100_000_000) over baud rate (9_600)
		data_length   : INTEGER := 5);
    Port ( 
		clk	 		  : in     STD_LOGIC;
		en 			  : in 	  STD_LOGIC;
		msg 			  : in     STD_LOGIC_VECTOR (data_length-1 downto 0);
      tx_serial 	  : inout  STD_LOGIC;
		transmitted	  : out    STD_LOGIC);
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is

	type conversion_mode_types is (idle, start_bit, data_bit, stop_bit, reset);
	
	signal current_mode : conversion_mode_types := idle;

	signal data_index   : INTEGER range 0 to (data_length-1)  := 0;
	signal clk_counter  : INTEGER range 0 to (clks_per_bit-1) := 0;
	
	signal saved_msg    : STD_LOGIC_VECTOR(data_length-1 downto 0) := (others => '0');

begin

	conversion_process: process(clk)
	BEGIN
		
		IF RISING_EDGE(clk) THEN
	
			CASE current_mode IS
				
				-- Idle Mode
				WHEN idle =>
					
					tx_serial   <= '1';
					clk_counter <= 0;
					data_index  <= 0;
					transmitted   <= '0';
					
					IF (en = '1') THEN
						saved_msg    <= msg;
						current_mode <= start_bit;
					END IF;
					
				-- Start bit of the transaction
				WHEN start_bit =>
				
					tx_serial   <= '0';
				
					IF (clk_counter = clks_per_bit-1) THEN
						clk_counter  <= 0;
						data_index   <= 0;
						current_mode <= data_bit;
					ELSE
						clk_counter  <= clk_counter + 1;
					END IF;
				
				-- Serialize data bits
				WHEN data_bit =>
				
					IF (data_index = data_length) THEN
						data_index   <= 0;
						clk_counter  <= 0;
						current_mode <= stop_bit;
					ELSE
			
						tx_serial <= saved_msg(data_index);
					
						IF (clk_counter = clks_per_bit-1) THEN
							data_index  <= data_index + 1;
							clk_counter <= 0;
						ELSE
							clk_counter <= clk_counter + 1;
						END IF;
					
					END IF;
						
				-- Signal the end of the transaction
				WHEN stop_bit =>
					
					tx_serial <= '1';
					
					IF (clk_counter = clks_per_bit - 1) THEN
						clk_counter  <= 0;
						transmitted    <= '1';
						current_mode <= reset;
					ELSE
						clk_counter  <= clk_counter + 1;
					END IF;
					
				-- Reset
				WHEN reset =>
				
					tx_serial  	 <= '1';
					transmitted 	 <= '0';
					current_mode <= idle;
			
			END CASE;
	
		END IF;
		
	END PROCESS;


end Behavioral;

