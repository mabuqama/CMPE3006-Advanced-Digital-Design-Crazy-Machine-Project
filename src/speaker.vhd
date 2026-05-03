library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity speaker is
    Port ( 	input : in  STD_LOGIC;
				noise: out STD_LOGIC);
end speaker;

architecture Behavioral of speaker is
 
begin
noise <= not input;

end Behavioral;
