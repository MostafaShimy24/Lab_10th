library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv_tb is
end entity;

architecture sim of conv_tb is

    constant N            : integer := 40;
    constant INDEX_WIDTH  : integer := 6;

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';

    signal write_en    : std_logic := '0';
    signal write_index : unsigned(INDEX_WIDTH-1 downto 0) := (others => '0');
    signal x_in        : signed(7 downto 0) := (others => '0');
    signal w_in        : signed(7 downto 0) := (others => '0');

    signal start       : std_logic := '0';
    signal clear_done  : std_logic := '0';

    signal result : signed(31 downto 0);
    signal done   : std_logic;

begin

    clk <= not clk after 5 ns;

    DUT: entity work.conv
        generic map (
            N => N,
            INDEX_WIDTH => INDEX_WIDTH
        )
        port map (
            clk         => clk,
            rst         => rst,
            write_en    => write_en,
            write_index => write_index,
            x_in        => x_in,
            w_in        => w_in,
            start       => start,
            clear_done  => clear_done,
            result      => result,
            done        => done
        );

    process
        variable expected : signed(31 downto 0);
        variable temp32   : signed(63 downto 0);
    begin

        ------------------------------------------------
        -- RESET
        ------------------------------------------------
        rst <= '0';
        wait for 20 ns;
        rst <= '1';
        wait for 20 ns;

        ------------------------------------------------
        -- TEST 1: x = i+1, w = 1
        ------------------------------------------------
        expected := (others => '0');

        for i in 0 to N-1 loop

            write_index <= to_unsigned(i, INDEX_WIDTH);
            x_in        <= to_signed(i+1, 8);
            w_in        <= to_signed(1, 8);

            wait until rising_edge(clk);
            write_en <= '1';

            wait until rising_edge(clk);
            write_en <= '0';

            -- expected accumulation
            temp32 := resize(to_signed(i+1,8),32) *
                      resize(to_signed(1,8),32);
            expected := resize(expected + temp32,32);

        end loop;

        wait for 20 ns;

        -- Start compute
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        wait until done = '1';

        report "Test1 Result  = " & integer'image(to_integer(result));
        report "Expected      = " & integer'image(to_integer(expected));

        ------------------------------------------------
        -- Clear done
        ------------------------------------------------
        wait until rising_edge(clk);
        clear_done <= '1';
        wait until rising_edge(clk);
        clear_done <= '0';

        wait for 40 ns;

        ------------------------------------------------
        -- TEST 2: x = 2, w = 3
        ------------------------------------------------
        expected := (others => '0');

        for i in 0 to N-1 loop

            write_index <= to_unsigned(i, INDEX_WIDTH);
            x_in        <= to_signed(2, 8);
            w_in        <= to_signed(3, 8);

            wait until rising_edge(clk);
            write_en <= '1';

            wait until rising_edge(clk);
            write_en <= '0';

            temp32 := resize(to_signed(2,8),32) *
                      resize(to_signed(3,8),32);
            expected := resize(expected + temp32,32);

        end loop;

        wait for 20 ns;

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        wait until done = '1';

        report "Test2 Result  = " & integer'image(to_integer(result));
        report "Expected      = " & integer'image(to_integer(expected));

        ------------------------------------------------
        -- TEST 3: x = i, w = i
        ------------------------------------------------
        expected := (others => '0');

        for i in 0 to N-1 loop

            write_index <= to_unsigned(i, INDEX_WIDTH);
            x_in        <= to_signed(i, 8);
            w_in        <= to_signed(i, 8);

            wait until rising_edge(clk);
            write_en <= '1';

            wait until rising_edge(clk);
            write_en <= '0';

            temp32 := resize(to_signed(i,8),32) *
                      resize(to_signed(i,8),32);
            expected := resize(expected + temp32,32);

        end loop;

        wait for 20 ns;

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        wait until done = '1';

        report "Test3 Result  = " & integer'image(to_integer(result));
        report "Expected      = " & integer'image(to_integer(expected));

        wait;

    end process;

end architecture;
