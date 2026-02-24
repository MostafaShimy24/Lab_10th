library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv is
    generic (
        N            : integer := 40;
        DATA_WIDTH   : integer := 8;
        WEIGHT_WIDTH : integer := 8;
        INDEX_WIDTH  : integer := 6   -- 6 bits can address 0..63 (enough for 40)
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- Software write interface
        write_en      : in  std_logic;
        write_index   : in  unsigned(INDEX_WIDTH-1 downto 0);
        x_in          : in  signed(DATA_WIDTH-1 downto 0);
        w_in          : in  signed(WEIGHT_WIDTH-1 downto 0);

        -- Start compute
        start   : in  std_logic;
        clear_done : in std_logic;
        -- Output
        result  : out signed(DATA_WIDTH + WEIGHT_WIDTH + 6 downto 0);
        done    : out std_logic
    );
end entity;

architecture rtl of conv is

    constant ACC_WIDTH : integer := DATA_WIDTH + WEIGHT_WIDTH + 6;

    type state_type is (IDLE, COMPUTE);
    signal state : state_type := IDLE;

    type x_array_t is array (0 to N-1) of signed(DATA_WIDTH-1 downto 0);
    type w_array_t is array (0 to N-1) of signed(WEIGHT_WIDTH-1 downto 0);

    signal x_mem : x_array_t := (others => (others => '0'));
    signal w_mem : w_array_t := (others => (others => '0'));

    signal acc        : signed(ACC_WIDTH downto 0) := (others => '0');
    signal comp_index : integer range 0 to N := 0;

    signal done_r : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '0' then
                state      <= IDLE;
                acc        <= (others => '0');
                comp_index <= 0;
                done_r     <= '0';

            else

                case state is

                    ------------------------------------------------
                when IDLE =>
                
                    -- Allow software to write memory
                    if write_en = '1' then
                        if to_integer(write_index) < N then
                            x_mem(to_integer(write_index)) <= x_in;
                            w_mem(to_integer(write_index)) <= w_in;
                        end if;
                    end if;
                
                    -- Clear done when CPU asks
                    if clear_done = '1' then
                        done_r <= '0';
                    end if;
                
                    -- Start compute
                    if start = '1' then
                        acc        <= (others => '0');
                        comp_index <= 0;
                        done_r     <= '0';
                        state      <= COMPUTE;
                    end if;

                    when COMPUTE =>
                    
                        acc <= acc +
                            resize(
                                x_mem(comp_index)     * w_mem(comp_index)     +
                                x_mem(comp_index + 1) * w_mem(comp_index + 1) +
                                x_mem(comp_index + 2) * w_mem(comp_index + 2) +
                                x_mem(comp_index + 3) * w_mem(comp_index + 3) +
                                x_mem(comp_index + 4) * w_mem(comp_index + 4) +
                                x_mem(comp_index + 5) * w_mem(comp_index + 5) +
                                x_mem(comp_index + 6) * w_mem(comp_index + 6) +
                                x_mem(comp_index + 7) * w_mem(comp_index + 7),
                                acc'length
                            );
                    
                        if comp_index = N-8 then
                            done_r <= '1';
                            state  <= IDLE;
                        else
                            comp_index <= comp_index + 8;
                        end if;

                end case;

            end if;
        end if;
    end process;

    result <= acc;
    done   <= done_r;

end architecture;
