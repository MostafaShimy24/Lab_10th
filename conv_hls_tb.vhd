library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv_tb is
end entity;

architecture sim of conv_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal ap_clk       : std_logic := '0';
    signal ap_rst       : std_logic := '1';  -- ACTIVE HIGH
    signal ap_rst_r     : std_logic := '1';

    signal write_en     : std_logic := '0';
    signal write_index  : std_logic_vector(5 downto 0) := (others => '0');
    signal x_in         : std_logic_vector(7 downto 0) := (others => '0');
    signal w_in         : std_logic_vector(7 downto 0) := (others => '0');
    signal start_r      : std_logic := '0';
    signal clear_done   : std_logic := '0';

    signal result       : std_logic_vector(31 downto 0);
    signal done         : std_logic;

begin

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    dut: entity work.conv
        port map (
            ap_clk      => ap_clk,
            ap_rst      => ap_rst,
            ap_rst_r    => ap_rst_r,
            write_en    => write_en,
            write_index => write_index,
            x_in        => x_in,
            w_in        => w_in,
            start_r     => start_r,
            clear_done  => clear_done,
            result      => result,
            done        => done
        );

    ------------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------------
    ap_clk <= not ap_clk after CLK_PERIOD/2;

    ------------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------------
    stim_proc: process

        procedure run_test(
            constant mode : integer) is

            variable expected : integer := 0;

        begin

            ----------------------------------------------------------
            -- WRITE 40 VALUES
            ----------------------------------------------------------
            expected := 0;

            for i in 0 to 39 loop
                wait until rising_edge(ap_clk);
                write_en    <= '1';
                write_index <= std_logic_vector(to_unsigned(i,6));

                case mode is
                    when 0 =>  -- x=i+1 , w=1
                        x_in <= std_logic_vector(to_signed(i+1,8));
                        w_in <= std_logic_vector(to_signed(1,8));
                        expected := expected + (i+1);

                    when 1 =>  -- x=1 , w=1
                        x_in <= std_logic_vector(to_signed(1,8));
                        w_in <= std_logic_vector(to_signed(1,8));
                        expected := expected + 1;

                    when 2 =>  -- x=-1 , w=1
                        x_in <= std_logic_vector(to_signed(-1,8));
                        w_in <= std_logic_vector(to_signed(1,8));
                        expected := expected - 1;

                    when others =>
                        null;
                end case;
            end loop;

            wait until rising_edge(ap_clk);
            write_en <= '0';

            wait until rising_edge(ap_clk);

            ----------------------------------------------------------
            -- START
            ----------------------------------------------------------
            start_r <= '1';
            wait until rising_edge(ap_clk);
            start_r <= '0';

            ----------------------------------------------------------
            -- WAIT FOR DONE
            ----------------------------------------------------------
            wait until done = '1';
            wait until rising_edge(ap_clk);

            report "--------------------------------";
            report "Result   = " &
                   integer'image(to_integer(signed(result)));
            report "Expected = " &
                   integer'image(expected);

            if to_integer(signed(result)) = expected then
                report "TEST PASSED" severity note;
            else
                report "TEST FAILED" severity error;
            end if;

            ----------------------------------------------------------
            -- TEST clear_done
            ----------------------------------------------------------
            clear_done <= '1';
            wait until rising_edge(ap_clk);
            clear_done <= '0';
            wait until rising_edge(ap_clk);

            if done = '0' then
                report "clear_done PASSED" severity note;
            else
                report "clear_done FAILED" severity error;
            end if;

        end procedure;

    begin

        --------------------------------------------------------------
        -- RESET SEQUENCE (KEEPING YOUR STYLE)
        --------------------------------------------------------------
        ap_rst   <= '1';
        ap_rst_r <= '0';
        wait for 50 ns;

        ap_rst   <= '0';
        ap_rst_r <= '1';
        wait until rising_edge(ap_clk);

        --------------------------------------------------------------
        -- TEST 1
        --------------------------------------------------------------
        report "========== TEST 1 ==========";
        run_test(0);

        --------------------------------------------------------------
        -- TEST 2
        --------------------------------------------------------------
        report "========== TEST 2 ==========";
        run_test(1);

        --------------------------------------------------------------
        -- TEST 3
        --------------------------------------------------------------
        report "========== TEST 3 ==========";
        run_test(2);

        --------------------------------------------------------------
        -- TEST 4: Back-to-back without reset
        --------------------------------------------------------------
        report "========== TEST 4 ==========";
        run_test(0);

        report "ALL TESTS COMPLETED.";
        wait;

    end process;

end architecture;
