library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv is
    generic (
        N            : integer := 40;
        INDEX_WIDTH  : integer := 6
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- Software write interface
        write_en      : in  std_logic;
        write_index   : in  unsigned(INDEX_WIDTH-1 downto 0);
        x_in          : in  signed(7 downto 0);
        w_in          : in  signed(7 downto 0);

        -- Start compute
        start       : in  std_logic;
        clear_done  : in  std_logic;

        -- 32-bit signed result
        result  : out signed(31 downto 0);
        done    : out std_logic
    );
end entity;

architecture rtl of conv is

    type state_type is (IDLE, COMPUTE);
    signal state : state_type := IDLE;

    type mem_t is array (0 to N-1) of signed(7 downto 0);
    signal x_mem : mem_t := (others => (others => '0'));
    signal w_mem : mem_t := (others => (others => '0'));

    -- 32-bit accumulator
    signal acc        : signed(31 downto 0) := (others => '0');
    signal comp_index : integer range 0 to N := 0;
    signal done_r     : std_logic := '0';

begin

    process(clk)
        variable mult_sum  : signed(31 downto 0);
        variable m0,m1,m2,m3,m4,m5,m6,m7 : signed(15 downto 0);
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

                    -- Memory write
                    if write_en = '1' then
                        if to_integer(write_index) < N then
                            x_mem(to_integer(write_index)) <= x_in;
                            w_mem(to_integer(write_index)) <= w_in;
                        end if;
                    end if;

                    -- Clear done
                    if clear_done = '1' then
                        done_r <= '0';
                    end if;

                    -- Start compute
                    if start = '1' then
                        acc        <= (others => '0');
                        comp_index <= 0;
                        state      <= COMPUTE;
                    end if;

                ------------------------------------------------
                when COMPUTE =>

                    -- 8 parallel 8x8 multiplications (16-bit each)
                    m0 := x_mem(comp_index)     * w_mem(comp_index);
                    m1 := x_mem(comp_index + 1) * w_mem(comp_index + 1);
                    m2 := x_mem(comp_index + 2) * w_mem(comp_index + 2);
                    m3 := x_mem(comp_index + 3) * w_mem(comp_index + 3);
                    m4 := x_mem(comp_index + 4) * w_mem(comp_index + 4);
                    m5 := x_mem(comp_index + 5) * w_mem(comp_index + 5);
                    m6 := x_mem(comp_index + 6) * w_mem(comp_index + 6);
                    m7 := x_mem(comp_index + 7) * w_mem(comp_index + 7);

                    -- Extend to 32-bit and sum
                    mult_sum :=
                        resize(m0, 32) +
                        resize(m1, 32) +
                        resize(m2, 32) +
                        resize(m3, 32) +
                        resize(m4, 32) +
                        resize(m5, 32) +
                        resize(m6, 32) +
                        resize(m7, 32);

                    -- Accumulate into 32-bit accumulator
                    acc <= acc + mult_sum;

                    -- Done condition
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
