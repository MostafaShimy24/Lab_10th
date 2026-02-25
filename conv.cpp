#include <ap_int.h>

#define N 40
#define INDEX_WIDTH 6

void conv(
    bool ap_rst,                  // ACTIVE LOW reset
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
#pragma HLS INTERFACE ap_none port=ap_rst
#pragma HLS INTERFACE ap_none port=write_en
#pragma HLS INTERFACE ap_none port=write_index
#pragma HLS INTERFACE ap_none port=x_in
#pragma HLS INTERFACE ap_none port=w_in
#pragma HLS INTERFACE ap_none port=start_r
#pragma HLS INTERFACE ap_none port=clear_done
#pragma HLS INTERFACE ap_none port=result
#pragma HLS INTERFACE ap_none port=done
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE II=1

    static ap_int<8> x_mem[N];
    static ap_int<8> w_mem[N];

    static ap_uint<1> state = 0;     // 0=IDLE, 1=COMPUTE
    static ap_uint<6> comp_index = 0;
    static ap_int<32> acc = 0;
    static bool done_r = false;

    // =============================
    // ACTIVE LOW RESET
    // =============================
    if (ap_rst == 0)
    {
        state = 0;
        comp_index = 0;
        acc = 0;
        done_r = false;
    }
    else
    {
        if (state == 0)  // IDLE
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
        else  // COMPUTE
        {
            acc += (ap_int<32>)(x_mem[comp_index] * w_mem[comp_index]);

            if (comp_index == N-1)
            {
                done_r = true;
                state = 0;
            }
            else
            {
                comp_index++;
            }
        }
    }

    result = acc;
    done   = done_r;
}
