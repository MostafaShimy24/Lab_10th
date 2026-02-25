#include <ap_int.h>

#define N 40
#define INDEX_WIDTH 6

void conv(
    bool write_en,
    ap_uint<INDEX_WIDTH> write_index,
    ap_int<8> x_in,
    ap_int<8> w_in,
    bool start_r,
    bool clear_done,
    ap_int<32> &result,
    bool &done
)
{
#pragma HLS INTERFACE ap_none port=write_en
#pragma HLS INTERFACE ap_none port=write_index
#pragma HLS INTERFACE ap_none port=x_in
#pragma HLS INTERFACE ap_none port=w_in
#pragma HLS INTERFACE ap_none port=start_r
#pragma HLS INTERFACE ap_none port=clear_done
#pragma HLS INTERFACE ap_none port=result
#pragma HLS INTERFACE ap_none port=done
#pragma HLS INTERFACE ap_ctrl_none port=return

    static ap_int<8> x_mem[N];
    static ap_int<8> w_mem[N];

#pragma HLS ARRAY_PARTITION variable=x_mem cyclic factor=8
#pragma HLS ARRAY_PARTITION variable=w_mem cyclic factor=8

    static ap_int<32> acc = 0;
    static ap_uint<INDEX_WIDTH> comp_index = 0;
    static bool done_r = false;
    static ap_uint<1> state = 0;

    // ===== IDLE =====
    if (state == 0)
    {
        if (write_en && write_index < N)
        {
            x_mem[write_index] = x_in;
            w_mem[write_index] = w_in;
        }

        if (clear_done)
            done_r = false;

        if (start_r)
        {
            acc = 0;
            comp_index = 0;
            state = 1;
        }
    }

    // ===== COMPUTE =====
    else
    {
        ap_int<16> m0 = x_mem[comp_index]     * w_mem[comp_index];
        ap_int<16> m1 = x_mem[comp_index + 1] * w_mem[comp_index + 1];
        ap_int<16> m2 = x_mem[comp_index + 2] * w_mem[comp_index + 2];
        ap_int<16> m3 = x_mem[comp_index + 3] * w_mem[comp_index + 3];
        ap_int<16> m4 = x_mem[comp_index + 4] * w_mem[comp_index + 4];
        ap_int<16> m5 = x_mem[comp_index + 5] * w_mem[comp_index + 5];
        ap_int<16> m6 = x_mem[comp_index + 6] * w_mem[comp_index + 6];
        ap_int<16> m7 = x_mem[comp_index + 7] * w_mem[comp_index + 7];

        ap_int<32> mult_sum =
            (ap_int<32>)m0 +
            (ap_int<32>)m1 +
            (ap_int<32>)m2 +
            (ap_int<32>)m3 +
            (ap_int<32>)m4 +
            (ap_int<32>)m5 +
            (ap_int<32>)m6 +
            (ap_int<32>)m7;

        acc += mult_sum;

        if (comp_index == N - 8)
        {
            done_r = true;
            state = 0;
        }
        else
        {
            comp_index += 8;
        }
    }

    result = acc;
    done   = done_r;
}
